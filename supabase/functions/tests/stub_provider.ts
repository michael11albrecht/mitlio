// Provider stub for the fuel-prices integration test: imitates Tankerkönig `list.php` and serves
// the checked-in EU Oil Bulletin sample. Records what it receives so the test can assert that no
// client data (IP, exact coordinates, origin) reaches the provider. Test-only, never deployed.
const fixture = await Deno.readFile(
  new URL("../_shared/testdata/oil_bulletin_sample.xlsx", import.meta.url),
);

interface Seen {
  lat: string | null;
  lng: string | null;
  rad: string | null;
  apikey: string | null;
  headers: Record<string, string>;
}
let listCalls: Seen[] = [];
let oilCalls = 0;

const stations = [
  { id: "a", e5: 1.8, e10: 1.74, diesel: 1.6, isOpen: true },
  { id: "b", e5: 1.9, e10: 1.84, diesel: 1.7, isOpen: true },
  { id: "c", e5: 1.7, e10: 1.64, diesel: 1.65, isOpen: true },
  { id: "d", e5: 1.2, e10: 1.2, diesel: 1.2, isOpen: false },
];

Deno.serve({ hostname: "0.0.0.0", port: 8787 }, (req) => {
  const url = new URL(req.url);
  if (url.pathname === "/json/list.php") {
    const p = url.searchParams;
    const headers: Record<string, string> = {};
    req.headers.forEach((v, k) => (headers[k] = v));
    listCalls.push({
      lat: p.get("lat"),
      lng: p.get("lng"),
      rad: p.get("rad"),
      apikey: p.get("apikey"),
      headers,
    });
    if (p.get("apikey") !== "test-key") {
      return Response.json({ ok: false, message: "apikey nicht angegeben" });
    }
    return Response.json({ ok: true, license: "CC BY 4.0", status: "ok", stations });
  }
  if (url.pathname === "/oil.xlsx") {
    oilCalls++;
    return new Response(fixture, {
      headers: {
        "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      },
    });
  }
  if (url.pathname === "/__stats") return Response.json({ list: listCalls, oil: oilCalls });
  if (url.pathname === "/__reset") {
    listCalls = [];
    oilCalls = 0;
    return Response.json({});
  }
  return new Response("not found", { status: 404 });
});
