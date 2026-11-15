# ADR-25: Personal profile, personal vehicles and guided setup flows

- **Status:** proposed (owner idea 2026-11-15; open points in plan §12 #9–#12)
- **Date:** 2026-11-15

## Context

Today everything is per group: a person's PayPal.Me and IBAN are typed into each group's member,
and a car (`vehicles`, synced, group-scoped) is set up again in every group. Most people have one
car (sometimes a second family car) and one set of payment details, and use them in several groups.
Wear cost (`wear_milli_per_km`) is a single number most people cannot estimate, so they leave it at
0 and the driver is underpaid.

The owner also wants setting things up to feel light: no long forms, one or two values per screen,
pictures that explain, optional steps that can be skipped, visible progress and a small celebration
at the end.

## Decision

1. **Personal profile ("Ich"), device-local first.** One row per device/user: display name, avatar
   (initials + colour by default, emoji or photo optional), PayPal.Me handle. The full IBAN stays in
   a local-only table (`local_profile_bank`), exactly like `local_member_bank` (§8). Before P6 sync
   the profile never leaves the device. After P6-T07 the profile is tied to the account; connecting
   to a person (ADR-24) copies name, avatar and PayPal.Me to that person. IBAN sharing is not part
   of this ADR (owner decision §12 #9).
2. **Personal vehicles ("Meine Autos").** Vehicles the user owns or can use are set up once in
   `user_vehicles` (local, later synced to the own account only). Using one in a group creates a
   **linked copy** in the group's `vehicles` (`source_user_vehicle_id`). Editing the personal car
   updates all linked group copies from now on, with an undo snackbar ("In 3 Gruppen aktualisiert ·
   Rückgängig"); a group copy can be unlinked to diverge. Closed ride periods are unaffected because
   they are already expenses (P3r-T06). Group vehicles without a source keep working unchanged.
3. **Personal extra cost per km.** Instead of guessing a wear rate, the user can optionally enter
   their real car costs: annual km, then one cost category per screen (insurance, vehicle tax,
   maintenance/inspection, tyres, repairs, loan/leasing, depreciation, parking, other), each as a
   yes/no question with "Überspringen". Domain function `vehicleExtraCostPerKm` turns this into
   `wear_milli_per_km`. Categories are tagged **running** (maintenance, tyres, repairs, depreciation
   by km) or **fixed** (insurance, tax, loan, parking). Default share basis is **running costs only**,
   because private ride sharing in Germany is exempt from the passenger transport law only if the
   total payment does not exceed the trip's operating costs (PBefG §1 Abs. 2 Nr. 1); including fixed
   costs is an explicit opt-in with a plain hint (owner decision §12 #10). Without the calculator the
   flat default stays (today's behaviour).
4. **Guided setup flow pattern** (`app/lib/core/ui/setup_flow/`), reused by every setup:
   - one question per screen, at most two related values; a picture/visual on every step;
   - optional steps are yes/no cards or have "Überspringen"; nothing is required except where the
     feature cannot work without it (a car needs consumption);
   - segmented progress bar ("Schritt 2 von 5"), back always possible, every step saved on "Weiter"
     so leaving and resuming is free;
   - the result is shown live while typing (e.g. "≈ 7,4 ct/km"), result first (§2.6 #2);
   - a finish screen with a short celebration (respects reduce-motion), a summary of what was set up
     and one obvious next action. No points, streaks or badges outside the flow (§2.6 #6).
   - First-time users get the flow; returning users editing a value get a compact list where each
     row opens the single step.
   - **App-wide pattern choice** (owner rule 2026-11-15): the step flow fits whenever a flow is *rare*
     (one-time or a few times a year) **and** has more than ~3 inputs. Frequent flows stay one compact
     screen with smart defaults, because people want to be done fast; they never get progress bars,
     celebrations or extra screens. Celebration is only for one-time setups and long rare flows.

     | Flow | Frequency | Pattern | Celebration |
     |---|---|---|---|
     | Profile, PayPal.Me, IBAN | once | step flow | yes, at the end |
     | Personal car + cost calculator | once per car | step flow | yes |
     | First group with people (P7-T06 onboarding) | once | step flow, max 3 steps | short |
     | Commute template (`ride_templates`) | rare | step flow | no, just "Fertig" |
     | Month settlement ("Abrechnen für Oktober") | monthly | short step flow (review → confirm) | small "Alles ausgeglichen" when balances reach 0 |
     | Join group / connect person (P6, ADR-24) | once per group | step flow, max 2 steps | no |
     | Log ride, add expense, mark as paid | daily | **one screen**, defaults, tap budgets (§2.6) | **never** |
     | Edit any existing value | any | compact list → single field/step | never |
5. **Entry points are just-in-time, never at first launch.** Onboarding (P7-T06) still goes straight
   to the first group. The flows are offered by calm inline cards where the data is needed: settle
   screen without own PayPal/IBAN, vehicle picker in a group ("Dein Auto einmal einrichten, in allen
   Gruppen nutzen"), creating a second group (prefill "Ich" member). A dismissed card stays dismissed.
   Settings get "Mein Profil" and "Meine Autos".
6. **PayPal.Me help uses our own illustrations, not screenshots.** Real PayPal screenshots or logos
   would be trademark/copyright material and go stale with every PayPal app update. We draw neutral,
   PayPal-like step mockups in the mitlio design (generic phone frame, highlighted tap target, the
   name "PayPal" only as text) and keep the step texts in ARB so they can be updated without new art.
   The input accepts any form (`paypal.me/name`, full URL, `@name`, `name`), normalises it, and offers
   "Link testen" (opens the link externally) plus "Noch kein PayPal.Me? Jetzt erstellen".

## Consequences

- New tables `profile`, `local_profile_bank`, `user_vehicles`, `user_vehicle_costs`; new nullable
  column `vehicles.source_user_vehicle_id`. Migration is `critical`.
- New domain code: PayPal.Me handle normalisation/validation, vehicle cost model and
  `vehicleExtraCostPerKm` (int milli, property tests like the rest of the domain).
- Illustrations are vector assets; drawing them in `CustomPainter` avoids a new dependency, an SVG
  renderer (`flutter_svg`) would need a rationale in the PR (owner decision §12 #11).
- The "Ich" member prefill makes group creation faster but must stay editable (one person may use
  another name in a group).
- Profile photo is a nice-to-have (backlog); its sync waits for Storage (P9-T01).

## Revisit when

Field data (P5) shows people keep different payment details per group, or the cost wizard is
rarely finished (then shorten it to the three biggest categories).
