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
let fxCalls: { path: string; headers: Record<string, string> }[] = [];
let githubCalls: { path: string; headers: Record<string, string>; body: string }[] = [];
// FCM v1 + Google OAuth imitation for the notify test (P6b-T05). Records every request. The token
// of a message decides the answer: *-unregistered -> 404 UNREGISTERED, *-invalid -> 400
// INVALID_ARGUMENT, *-flaky -> 503 until /__fcm_heal is called, everything else 200.
let fcmCalls: { authorization: string | null; body: { message: Record<string, unknown> } }[] = [];
let oauthCalls: { grant_type: string | null; assertion: string | null }[] = [];
let fcmHealed = false;

// Frankfurter imitation: rates per 1 unit of `from`. Dated requests answer the last working day.
const fxRates: Record<string, Record<string, number>> = {
  USD: { EUR: 0.92, GBP: 0.79 },
  EUR: { USD: 1.0869565 },
};
const FX_LATEST_DATE = "2026-11-13";

function lastWorkingDay(day: string): string {
  const d = new Date(`${day}T00:00:00Z`);
  while (d.getUTCDay() === 0 || d.getUTCDay() === 6) d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

function fxResponse(url: URL, headers: Record<string, string>): Response {
  fxCalls.push({ path: url.pathname + url.search, headers });
  const from = url.searchParams.get("from") ?? "EUR";
  const to = url.searchParams.get("to");
  const quote = to === null ? undefined : fxRates[from]?.[to];
  if (quote === undefined) return Response.json({ message: "not found" }, { status: 404 });
  const day = url.pathname.slice(1);
  const date = day === "latest" ? FX_LATEST_DATE : lastWorkingDay(day);
  return Response.json({ amount: 1.0, base: from, date, rates: { [to!]: quote } });
}

const stations = [
  { id: "a", e5: 1.8, e10: 1.74, diesel: 1.6, isOpen: true },
  { id: "b", e5: 1.9, e10: 1.84, diesel: 1.7, isOpen: true },
  { id: "c", e5: 1.7, e10: 1.64, diesel: 1.65, isOpen: true },
  { id: "d", e5: 1.2, e10: 1.2, diesel: 1.2, isOpen: false },
];

Deno.serve({ hostname: "0.0.0.0", port: 8787 }, async (req) => {
  const url = new URL(req.url);
  if (url.pathname === "/oauth/token" && req.method === "POST") {
    const form = new URLSearchParams(await req.text());
    oauthCalls.push({ grant_type: form.get("grant_type"), assertion: form.get("assertion") });
    return Response.json({ access_token: "stub-access-token", expires_in: 3600 });
  }
  if (url.pathname === "/fcm/v1/projects/stub/messages:send" && req.method === "POST") {
    const authorization = req.headers.get("authorization");
    const body = await req.json();
    fcmCalls.push({ authorization, body });
    const token = String(body.message?.token ?? "");
    if (authorization !== "Bearer stub-access-token") {
      return Response.json({ error: { status: "UNAUTHENTICATED" } }, { status: 401 });
    }
    if (token.endsWith("-unregistered")) {
      return Response.json({
        error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] },
      }, { status: 404 });
    }
    if (token.endsWith("-invalid")) {
      return Response.json({ error: { status: "INVALID_ARGUMENT" } }, { status: 400 });
    }
    if (token.endsWith("-flaky") && !fcmHealed) {
      return Response.json({ error: { status: "UNAVAILABLE" } }, { status: 503 });
    }
    return Response.json({ name: `projects/stub/messages/${fcmCalls.length}` });
  }
  if (url.pathname === "/__fcm_heal") {
    fcmHealed = true;
    return Response.json({});
  }
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
  if (url.pathname === "/latest" || /^\/\d{4}-\d{2}-\d{2}$/.test(url.pathname)) {
    const headers: Record<string, string> = {};
    req.headers.forEach((v, k) => (headers[k] = v));
    return fxResponse(url, headers);
  }
  // GitHub imitation for submit-feedback: records the issue request, answers 201.
  if (req.method === "POST" && /^\/github\/repos\/[^/]+\/[^/]+\/issues$/.test(url.pathname)) {
    return req.text().then((body) => {
      const headers: Record<string, string> = {};
      req.headers.forEach((v, k) => (headers[k] = v));
      githubCalls.push({ path: url.pathname, headers, body });
      return Response.json({ number: 1, html_url: "https://github.test/1" }, { status: 201 });
    });
  }
  if (url.pathname === "/__stats") {
    return Response.json({
      list: listCalls,
      oil: oilCalls,
      fx: fxCalls,
      github: githubCalls,
      fcm: fcmCalls,
      oauth: oauthCalls,
    });
  }
  if (url.pathname === "/__reset") {
    listCalls = [];
    oilCalls = 0;
    fxCalls = [];
    githubCalls = [];
    fcmCalls = [];
    oauthCalls = [];
    fcmHealed = false;
    return Response.json({});
  }
  return new Response("not found", { status: 404 });
});
