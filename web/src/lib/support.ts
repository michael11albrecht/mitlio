// The footer link "mitlio unterstützen" (P7-T09, ADR-28). Pure and DOM-free.
// A PayPal.Me handle is 1 to 20 letters or digits. Anything else (empty, a URL, a typo with a slash) gives no link,
// so a bad build setting hides the link instead of publishing a wrong or hijackable one.

/** `https://paypal.me/<handle>`, or null when [handle] is empty or not a valid PayPal.Me handle. */
export function supportUrl(handle: string): string | null {
  return /^[A-Za-z0-9]{1,20}$/.test(handle) ? `https://paypal.me/${handle}` : null;
}
