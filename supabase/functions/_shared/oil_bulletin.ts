// EU Weekly Oil Bulletin ("prices with taxes", European Commission) reader. Keyless national
// fuel price source (ADR-20). The published file is a one-sheet XLSX:
//   row 1: column headers ("Euro-super 95 (I)", "Gas oil automobile ... Dieselkraftstoff (I)", ...)
//   row 2: A2 = date the prices are in force (Excel serial), units row ("1000 l")
//   row 3+: A = English country name, B.. = EUR per 1000 litres (= milli-EUR per litre).
// Pure functions only; the fetch lives in fuel-prices/index.ts.

export interface BulletinPrices {
  /** Date the prices are in force on (UTC midnight). */
  date: Date;
  e5Milli: number;
  dieselMilli: number;
}

const MAX_XLSX_BYTES = 5_000_000;
const MAX_ENTRY_BYTES = 10_000_000;

interface ZipEntry {
  method: number;
  compressedSize: number;
  localOffset: number;
}

function readCentralDirectory(bytes: Uint8Array): Map<string, ZipEntry> {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let eocd = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 65_557); i--) {
    if (dv.getUint32(i, true) === 0x06054b50) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) throw new Error("not a zip file");
  const count = dv.getUint16(eocd + 10, true);
  let p = dv.getUint32(eocd + 16, true);
  const entries = new Map<string, ZipEntry>();
  for (let n = 0; n < count; n++) {
    if (p + 46 > bytes.length || dv.getUint32(p, true) !== 0x02014b50) {
      throw new Error("corrupt zip directory");
    }
    const nameLen = dv.getUint16(p + 28, true);
    const extraLen = dv.getUint16(p + 30, true);
    const commentLen = dv.getUint16(p + 32, true);
    const name = new TextDecoder().decode(bytes.subarray(p + 46, p + 46 + nameLen));
    entries.set(name, {
      method: dv.getUint16(p + 10, true),
      compressedSize: dv.getUint32(p + 20, true),
      localOffset: dv.getUint32(p + 42, true),
    });
    p += 46 + nameLen + extraLen + commentLen;
  }
  return entries;
}

async function readEntry(bytes: Uint8Array, entry: ZipEntry): Promise<string> {
  const dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const off = entry.localOffset;
  if (off + 30 > bytes.length || dv.getUint32(off, true) !== 0x04034b50) {
    throw new Error("corrupt zip entry");
  }
  const start = off + 30 + dv.getUint16(off + 26, true) + dv.getUint16(off + 28, true);
  const data = bytes.subarray(start, start + entry.compressedSize);
  let out: Uint8Array;
  if (entry.method === 0) {
    out = data;
  } else if (entry.method === 8) {
    const stream = new Blob([data]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
    out = new Uint8Array(await new Response(stream).arrayBuffer());
  } else {
    throw new Error("unsupported zip compression");
  }
  if (out.length > MAX_ENTRY_BYTES) throw new Error("zip entry too large");
  return new TextDecoder().decode(out);
}

function xmlText(s: string): string {
  return s
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");
}

function parseSharedStrings(xml: string): string[] {
  const out: string[] = [];
  for (const si of xml.matchAll(/<si>(.*?)<\/si>/gs)) {
    let text = "";
    for (const t of si[1].matchAll(/<t[^>]*>(.*?)<\/t>/gs)) text += t[1];
    out.push(xmlText(text));
  }
  return out;
}

/** cell ref ("B3") -> string for shared strings, number as text otherwise. */
function parseSheet(xml: string, strings: string[]): Map<string, string> {
  const cells = new Map<string, string>();
  for (const c of xml.matchAll(/<c r="([A-Z]+\d+)"([^>]*?)(?:\/>|>(.*?)<\/c>)/gs)) {
    const v = c[3]?.match(/<v>(.*?)<\/v>/s)?.[1];
    if (v === undefined) continue;
    const isShared = /\bt="s"/.test(c[2]);
    cells.set(c[1], isShared ? (strings[Number(v)] ?? "") : v);
  }
  return cells;
}

/** EUR per 1000 l string -> milli-EUR per litre. */
function toMilli(raw: string | undefined): number {
  const value = Number(raw);
  if (raw === undefined || !Number.isFinite(value) || value < 500 || value > 5000) {
    throw new Error("implausible bulletin price");
  }
  return Math.round(value);
}

/** Excel 1900 date serial -> UTC midnight. */
export function excelSerialToDate(serial: number): Date {
  return new Date(Math.round((serial - 25569) * 86_400_000));
}

/** Latest Euro-super 95 and diesel prices for `country` (English name, e.g. "Germany"). */
export async function parseBulletinXlsx(
  bytes: Uint8Array,
  country = "Germany",
): Promise<BulletinPrices> {
  if (bytes.length > MAX_XLSX_BYTES) throw new Error("bulletin too large");
  const entries = readCentralDirectory(bytes);
  const sheetEntry = entries.get("xl/worksheets/sheet1.xml");
  const stringsEntry = entries.get("xl/sharedStrings.xml");
  if (!sheetEntry || !stringsEntry) throw new Error("unexpected bulletin layout");
  const strings = parseSharedStrings(await readEntry(bytes, stringsEntry));
  const cells = parseSheet(await readEntry(bytes, sheetEntry), strings);

  let superCol: string | undefined;
  let dieselCol: string | undefined;
  for (const [ref, text] of cells) {
    if (!/^[A-Z]+1$/.test(ref)) continue;
    const col = ref.slice(0, -1);
    if (/Euro-super 95/i.test(text)) superCol ??= col;
    if (/gas oil automobile|Dieselkraftstoff/i.test(text)) dieselCol ??= col;
  }
  if (!superCol || !dieselCol) throw new Error("bulletin columns not found");

  const serial = Number(cells.get("A2"));
  if (!Number.isFinite(serial) || serial < 40_000 || serial > 80_000) {
    throw new Error("bulletin date not found");
  }

  for (const [ref, text] of cells) {
    if (!/^A\d+$/.test(ref) || text.trim() !== country) continue;
    const row = ref.slice(1);
    return {
      date: excelSerialToDate(serial),
      e5Milli: toMilli(cells.get(superCol + row)),
      dieselMilli: toMilli(cells.get(dieselCol + row)),
    };
  }
  throw new Error("country not in bulletin");
}
