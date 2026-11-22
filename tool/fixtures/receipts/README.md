# Receipt fixtures (P9r, ADR-26)

OCR output of receipts plus the `ReceiptDraft` we expect `parseReceipt` (`packages/domain/lib/src/receipt/`) to
produce. Test and gate: `packages/domain/test/receipt/receipt_fixtures_test.dart` parses every `*.json` in this folder.

**No photos in the repo, ever.** Only OCR text, boxes and the expected values, anonymised (see below).

## Files

- `synthetic-*.json`: hand-written stand-ins that exercise the formats (P9r-T03). They are not real receipts.
- `real-<nn>-<kind>.json`: anonymised real receipts collected by the owner (P9r-T02, ~30 of them: supermarket,
  restaurant, petrol station, pharmacy, foreign). Not there yet; drop them in here and the gate picks them up.

The file name without `.json` must equal `name`. Synthetic files must also have `"synthetic": true`.

## Format

```json
{
  "name": "synthetic-rewe-groceries",
  "synthetic": true,
  "note": "optional, what this fixture is about",
  "lines": [
    "REWE Markt GmbH",
    { "text": "SUMME", "box": [0.1, 0.62, 0.5, 0.65] }
  ],
  "expected": {
    "totalCents": 1234,
    "merchant": "REWE",
    "date": "2024-03-12",
    "currency": "EUR",
    "category": "groceries"
  }
}
```

- `lines`: top to bottom as the OCR service returns them. Each entry is a plain string (no box) or
  `{"text", "box": [left, top, right, bottom]}` with the box normalised to 0..1 of the page. Either every line has a
  box or none does (the parser only merges lines into rows when all have boxes).
- `expected`: the values `parseReceipt` must return. `null` means the field must stay **empty** (low confidence is
  better than a wrong value). A key that is missing is not checked.
  - `totalCents`: integer cents, never a float.
  - `merchant`: canonical chain name (`REWE`, `ALDI`, `Shell`, ...) or the cleaned name of an unknown shop.
  - `date`: `yyyy-MM-dd`.
  - `currency`: ISO 4217 code.
  - `category`: `groceries | fuel | restaurant | pharmacy | drugstore`.
- Confidences are not part of the fixture; they are covered by the unit tests.

## Gate

Across all fixtures: total correct >= 90 %, merchant correct >= 80 % (plan P9r-T03). Every fixture is also asserted
field by field, so a single regression shows up by name. If a real receipt cannot be parsed yet, keep it with the
value we want and fix the parser (or, when the OCR itself is wrong, correct the line to what the OCR returns, never to
what the receipt says).

## Anonymising a real receipt

Replace names, addresses, phone numbers, tax ids, card numbers, loyalty/customer numbers and any item that identifies
a person. Keep the merchant name, amounts, date and the layout of keywords (`SUMME`, `Rückgeld`, `MwSt`, ...) because
those are what the parser reads. Shift the date by a few days if it could identify a visit. Never commit the photo.
