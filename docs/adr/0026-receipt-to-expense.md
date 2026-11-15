# ADR-26: Receipt photo to expense, recognised on the device

- **Status:** proposed (owner idea 2026-11-15; backlog, after M3)
- **Date:** 2026-11-15

## Context

Typing title and amount from a receipt is the slowest part of adding an expense. The owner wants:
take a photo, the app fills in what it was and the total, the user only picks the people. Running
recognition on a server would cost money per receipt and send photos of personal purchases off the
device.

## Decision

1. **Recognition runs on the device, no server, no per-receipt cost.**
   - Capture: the platform document scanner (Android: ML Kit Document Scanner, iOS: VisionKit
     `VNDocumentCameraViewController`) for edge detection, perspective fix and good contrast.
   - Text: on-device OCR (Android: ML Kit Text Recognition v2 with the bundled Latin model, iOS:
     Apple Vision `VNRecognizeTextRequest`) behind one `ReceiptOcrService` interface returning lines
     with bounding boxes. A spike (P9r-T01) checks both for accuracy, app size, offline use and
     whether the SDK sends usage data; anything that phones home fails `deps_policy` and is replaced.
2. **Understanding the receipt is pure Dart in the domain** (`parseReceipt(lines) → ReceiptDraft`):
   total (keywords `SUMME`, `GESAMT`, `ZU ZAHLEN`, `TOTAL`, `BAR`, `EC`, `KARTE` …, largest amount
   near them, cross-checked with the sum of line items), merchant (top lines, biggest text, a small
   dictionary of chains), date, currency, and a category guess from the merchant (supermarket →
   Lebensmittel, petrol station → Tanken). Every field carries a confidence. Deterministic, fully
   testable with fixture OCR outputs, no ML model of our own.
3. **UX is the daily one-screen pattern (ADR-25 §4), no step flow, no celebration.** "Foto" on the
   add-expense screen → scanner → the normal expense form, prefilled, with recognised fields marked
   ("erkannt") and the cropped receipt area next to the total so it can be checked at a glance;
   focus jumps to the people picker (last-used people preselected). Low-confidence fields stay empty
   rather than wrong. Camera permission is asked only on the first tap on "Foto" (§2.6 #4). If
   recognition fails the form opens empty with a plain message (no silent errors).
4. **The photo stays local** unless attached on purpose; syncing attachments waits for Storage
   (P9-T01). OCR text is not stored beyond the draft.

## Consequences

- New dependencies (scanner + OCR plugins), each needs a rationale and a `deps_policy` pass.
- A fixture set of anonymised real receipts (OCR output JSON, no photos in the repo) is the
  accuracy gate; the owner collects ~30 receipts (supermarket, restaurant, petrol station, pharmacy,
  foreign).
- Later: split by line items ("wer hatte was") reuses the same parsed lines.

## Revisit when

Accuracy on the fixture set stays below the gate, or a platform ships a better on-device receipt
API.
