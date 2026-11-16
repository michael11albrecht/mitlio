// Contact form logic (no DOM): validation mirrors supabase/functions/_shared/contact.ts, and the API's
// error codes are mapped to message keys. Contract: docs/contact-api.md.
import type { ContactMessageKey } from '../i18n/contact';

export const MESSAGE_MIN = 10;
export const MESSAGE_MAX = 5000;
export const NAME_MAX = 100;

export type Field = 'name' | 'email' | 'message';

const EMAIL = /^[^\s@<>(),;:"[\]\\]+@[^\s@<>(),;:"[\]\\]+\.[^\s@<>(),;:"[\]\\]{2,}$/;

export function validateFields(v: { name: string; email: string; message: string }): Partial<Record<Field, ContactMessageKey>> {
  const errors: Partial<Record<Field, ContactMessageKey>> = {};
  const email = v.email.trim();
  const message = v.message.trim();
  if (email.length > 254 || !EMAIL.test(email)) errors.email = 'errorEmail';
  if (message.length < MESSAGE_MIN) errors.message = 'errorMessageShort';
  else if (message.length > MESSAGE_MAX) errors.message = 'errorMessageLong';
  if (v.name.trim().length > NAME_MAX) errors.name = 'errorNameLong';
  return errors;
}

export type Failure =
  | { kind: 'field'; field: Field; key: ContactMessageKey }
  | { kind: 'rate_limited'; minutes: number }
  | { kind: 'general'; key: ContactMessageKey };

const FIELD_CODES: Record<string, Extract<Failure, { kind: 'field' }>> = {
  invalid_email: { kind: 'field', field: 'email', key: 'errorEmail' },
  message_too_short: { kind: 'field', field: 'message', key: 'errorMessageShort' },
  message_too_long: { kind: 'field', field: 'message', key: 'errorMessageLong' },
  name_too_long: { kind: 'field', field: 'name', key: 'errorNameLong' },
};

/**
 * A failed fetch looks the same for "offline" and "blocked by the browser" (CORS, wrong origin, server down),
 * so navigator.onLine decides: offline says so, otherwise it is "form not reachable", never "no connection".
 */
export function networkFailure(online: boolean): Failure {
  return { kind: 'general', key: online ? 'errorNotConfigured' : 'errorNetwork' };
}

/** Maps a non-2xx API answer to what the user sees. Unknown answers are a failed send, never silence. */
export function failureFromResponse(status: number, body: unknown, retryAfterHeader: string | null): Failure {
  const code =
    typeof body === 'object' && body !== null ? (body as Record<string, unknown>)['error'] : undefined;
  if (status === 429 && code === 'busy') return { kind: 'general', key: 'errorBusy' };
  if (status === 429) {
    const fromBody = typeof body === 'object' && body !== null ? (body as Record<string, unknown>)['retryAfter'] : undefined;
    const seconds = Number(typeof fromBody === 'number' ? fromBody : retryAfterHeader);
    return { kind: 'rate_limited', minutes: Number.isFinite(seconds) && seconds > 0 ? Math.ceil(seconds / 60) : 60 };
  }
  if (typeof code === 'string' && code in FIELD_CODES) return FIELD_CODES[code]!;
  if (status === 503 && code === 'not_configured') return { kind: 'general', key: 'errorNotConfigured' };
  return { kind: 'general', key: 'errorSendFailed' };
}
