# ADR-29: In-app feedback, human-triaged into GitHub issues

- **Status:** proposed (owner agreed to the idea 2026-11-20); build after the P8 store release
- **Date:** 2026-11-20

## Context

Every user, technical or not, should be able to report a problem or suggest an idea without a GitHub
account. Reports become GitHub issues that the agent pipeline can later implement. Product rule #0
(no popups, no dark patterns, no tracking SDKs) and the privacy policy (P7-T07) apply.

## Decision

1. **Surface:** Settings row "Feedback". No popups, nags or rating prompts. Form: three chips
   (Problem / Idea / Question), one text box, optional screenshots from the photo picker, optional
   contact email ("nur wenn du eine Antwort möchtest"), optional diagnostics (app version, OS,
   locale) with a visible preview, off by default.
2. **Server-side only:** the app calls a Supabase Edge Function `submit-feedback`. The GitHub token
   (GitHub App or fine-grained PAT, issues:write only) lives only in the function secrets.
3. **Human gate:** created issues get `user-feedback` + `needs-triage`, never `agent-implement`.
   User text is untrusted input; an auto-triggered agent run would be a prompt-injection path. The
   owner (or Opus, planning only) rewrites a report into a proper spec before `agent-implement`.
4. **Screenshots are private:** stored in a private Supabase Storage bucket, linked from the issue
   only via maintainer-only access. Public issue text contains no attachments, no email, no
   diagnostics beyond version/OS. Screenshots can show third-party names and amounts. Retention is
   set in the privacy policy and enforced by a scheduled cleanup.
5. **Abuse control:** per-device and per-IP rate limit, size and count limits (e.g. 3 images,
   5 MB each), text length cap, server-side validation. App Attest / Play Integrity only if spam appears.
6. **No silent errors:** every failure shows cause + next step and keeps the draft; rate limit says
   when to retry. Success state: "Danke, wir lesen jede Nachricht."
7. **Architecture:** `FeedbackViewModel` → `FeedbackRepository` → Edge Function service. DebugDrive
   handler `ext.mitlio.feedback.submit` calls the same API. No new SDK in the app.
8. **Later (not v1):** duplicate hint ("das wurde schon vorgeschlagen"), status link back to the
   reporter, voting.

## Consequences

- Needs a GitHub App/PAT, a Storage bucket, an Edge Function and a privacy policy update (owner tasks).
- Triage effort is human; volume is bounded by rate limits.
- Reporters stay anonymous unless they give an email.
