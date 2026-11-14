import { assertEquals, assertRejects } from "jsr:@std/assert@1.0.8";
import { excelSerialToDate, parseBulletinXlsx } from "./oil_bulletin.ts";

const sample = await Deno.readFile(new URL("./testdata/oil_bulletin_sample.xlsx", import.meta.url));

Deno.test("parses Germany from a real bulletin sample", async () => {
  const p = await parseBulletinXlsx(sample);
  assertEquals(Number.isInteger(p.e5Milli) && p.e5Milli >= 1000 && p.e5Milli <= 3000, true);
  assertEquals(Number.isInteger(p.dieselMilli) && p.dieselMilli >= 1000, true);
  assertEquals(p.date.getUTCHours(), 0);
  assertEquals(p.date.getUTCFullYear() >= 2024, true);
});

Deno.test("country is a parameter", async () => {
  const de = await parseBulletinXlsx(sample, "Germany");
  const at = await parseBulletinXlsx(sample, "Austria");
  assertEquals(at.e5Milli, 1670);
  assertEquals(at.dieselMilli, 2087);
  assertEquals(de.date, at.date);
  await assertRejects(() => parseBulletinXlsx(sample, "Atlantis"), Error, "country");
});

Deno.test("excelSerialToDate", () => {
  assertEquals(excelSerialToDate(25569).toISOString(), "1970-01-01T00:00:00.000Z");
  assertEquals(excelSerialToDate(46335).toISOString(), "2026-11-09T00:00:00.000Z");
});

Deno.test("rejects garbage", async () => {
  await assertRejects(() => parseBulletinXlsx(new Uint8Array(10)), Error, "zip");
  await assertRejects(
    () => parseBulletinXlsx(new TextEncoder().encode("a,b\n1,2\n".repeat(10))),
    Error,
    "zip",
  );
  await assertRejects(() => parseBulletinXlsx(new Uint8Array(5_000_001)), Error, "large");
  const corrupt = sample.slice();
  const dv = new DataView(corrupt.buffer);
  for (let i = corrupt.length - 22; i >= 0; i--) {
    if (dv.getUint32(i, true) === 0x06054b50) {
      dv.setUint32(i + 16, 0, true); // central directory offset -> points at a local header
      break;
    }
  }
  await assertRejects(() => parseBulletinXlsx(corrupt), Error, "corrupt");
});
