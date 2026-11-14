// Deep link into the mitlio app: mitlio://ride?km=…&l100=…&price=…&n=…&d=…&rt=…&x=…&t=…
// Contract for P3r-T08, documented in docs/deeplink.md and pinned by tool/fixtures/deeplink.json.
// Pure and DOM-free. Numbers use "." as decimal separator, strings are percent-encoded.
import { sanitizeTripName } from '../calculator/core';

export const DEEP_LINK_SCHEME = 'mitlio';

export interface DeepLinkInput {
  /** Distance in km (one way). */
  km: number;
  /** Consumption per 100 km: litres, or kWh when `ev` is set. */
  l100: number;
  /** Price per litre, or per kWh when `ev` is set. */
  price: number;
  /** People including the driver. */
  n: number;
  /** Driver pays a share. */
  d: boolean;
  /** Round trip. */
  rt: boolean;
  /** Tolls and extras in EUR; omitted when 0 or unset. */
  x?: number | undefined;
  /** Optional trip name. */
  t?: string | undefined;
  /** Electric vehicle: l100 is kWh/100 km and price is EUR/kWh. */
  ev?: boolean | undefined;
}

/** Parameter order is part of the contract: km, l100, price, n, d, rt, x, t, ev. */
export function buildDeepLink(input: DeepLinkInput): string {
  const parts = [
    `km=${input.km}`,
    `l100=${input.l100}`,
    `price=${input.price}`,
    `n=${input.n}`,
    `d=${input.d ? 1 : 0}`,
    `rt=${input.rt ? 1 : 0}`,
  ];
  if (input.x !== undefined && input.x > 0) parts.push(`x=${input.x}`);
  const t = sanitizeTripName(input.t ?? '');
  if (t !== '') parts.push(`t=${encodeURIComponent(t)}`);
  if (input.ev) parts.push('ev=1');
  return `${DEEP_LINK_SCHEME}://ride?${parts.join('&')}`;
}
