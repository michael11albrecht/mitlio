// Contact form island. No cookies, no storage, no third party: the only network target is the configured
// `contact` Edge Function. Failures are always shown inline (plain language, what happened + what to do).
import { contactMessages, type ContactMessageKey } from '../i18n/contact';
import type { Locale } from '../i18n';
import { failureFromResponse, validateFields, type Failure, type Field } from '../lib/contact';

const TIMEOUT_MS = 15000;
const FIELDS: Field[] = ['name', 'email', 'message'];

const form = document.getElementById('contact-form') as HTMLFormElement | null;
if (form) {
  const api = form.dataset['api'] ?? '';
  const key = form.dataset['key'];
  const locale = (form.dataset['locale'] === 'en' ? 'en' : 'de') as Locale;
  const m = contactMessages[locale];

  const input = (f: Field) => document.getElementById(`contact-${f}`) as HTMLInputElement | HTMLTextAreaElement;
  const fieldError = (f: Field) => document.getElementById(`contact-${f}-error`) as HTMLElement;
  const formError = document.getElementById('contact-error') as HTMLElement;
  const success = document.getElementById('contact-success') as HTMLElement;
  const submit = document.getElementById('contact-submit') as HTMLButtonElement;
  const text = (k: ContactMessageKey) => m[k];

  const setFieldError = (f: Field, k: ContactMessageKey | null) => {
    const el = fieldError(f);
    el.hidden = k === null;
    el.textContent = k === null ? '' : text(k);
    if (k === null) input(f).removeAttribute('aria-invalid');
    else input(f).setAttribute('aria-invalid', 'true');
  };
  const setFormError = (message: string) => {
    formError.hidden = message === '';
    formError.textContent = message;
  };
  const clearErrors = () => {
    for (const f of FIELDS) setFieldError(f, null);
    setFormError('');
  };
  const show = (failure: Failure) => {
    if (failure.kind === 'field') {
      setFieldError(failure.field, failure.key);
      input(failure.field).focus();
    } else if (failure.kind === 'rate_limited') {
      setFormError(
        failure.minutes === 1 ? m.errorRateLimitedOne : m.errorRateLimitedMany.replace('{minutes}', String(failure.minutes)),
      );
    } else {
      setFormError(text(failure.key));
    }
  };

  const send = async (): Promise<Failure | null> => {
    const ctrl = new AbortController();
    const timer = window.setTimeout(() => ctrl.abort(), TIMEOUT_MS);
    try {
      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (key) {
        headers['apikey'] = key;
        headers['Authorization'] = `Bearer ${key}`;
      }
      const res = await fetch(api, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          name: input('name').value,
          email: input('email').value,
          message: input('message').value,
          locale,
          website: (form.elements.namedItem('website') as HTMLInputElement).value,
        }),
        signal: ctrl.signal,
        credentials: 'omit',
        referrerPolicy: 'no-referrer',
      });
      if (res.ok) return null;
      const body: unknown = await res.json().catch(() => null);
      return failureFromResponse(res.status, body, res.headers.get('Retry-After'));
    } catch {
      return { kind: 'general', key: 'errorNetwork' };
    } finally {
      window.clearTimeout(timer);
    }
  };

  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    clearErrors();
    const errors = validateFields({ name: input('name').value, email: input('email').value, message: input('message').value });
    const first = FIELDS.find((f) => errors[f] !== undefined);
    if (first) {
      for (const f of FIELDS) setFieldError(f, errors[f] ?? null);
      input(first).focus();
      return;
    }
    submit.disabled = true;
    submit.textContent = m.sending;
    const failure = await send();
    submit.disabled = false;
    submit.textContent = m.send;
    if (failure) {
      show(failure);
      return;
    }
    form.reset();
    form.hidden = true;
    success.hidden = false;
    success.focus();
  });
}
