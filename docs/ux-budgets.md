# UX budgets

Tap budgets per core flow (plan §2.6, product rule #0). Integration and widget tests count taps with `TapCounter` (`app/test/support/tap_counter.dart`) and call `expectWithinBudget('<flow>')`.

The fenced JSON block below is the single source: the helper parses it. Keys are flow ids. `maxTaps` is the inclusive tap limit; text entry is counted separately and never as a tap. Raising a budget is a product decision, not an implementation fix.

| Flow id | Flow | Max taps |
|---|---|---|
| `log_commute_ride` | Log a commute ride | 3 |
| `add_equal_split_expense` | Add an equal-split expense (plus typing the amount/title) | 5 |
| `add_recurring_expense` | Add an expense that repeats monthly: the equal-split flow plus one tap on "Wiederkehrend" (P9-T03; typing is not a tap) | 4 |
| `mark_transfer_paid` | Mark a transfer as paid | 2 |
| `create_group_with_members` | Create a group and add its people (typing names and keyboard enter are not taps) | 3 |
| `share_group_link` | Group detail to the share sheet with link and QR | 1 |
| `share_group_system_share` | Group detail to the system share sheet with the link | 2 |
| `join_link_claim_self` | Invite link opened to being in the group as yourself (tap your name) | 1 |
| `web_calculator` | Web calculator shows the result without pressing any button | 0 |
| `setup_step_answer` | Answer any step of a guided setup flow and move on (typing is not a tap; PU-T05, ADR-25 §4) | 2 |
| `setup_step_yes_no` | Yes/no step: tap a card, it answers and moves on | 1 |
| `setup_step_input` | Input step: type the value, tap "Weiter" | 1 |
| `setup_step_skip` | Skip an optional step ("Überspringen") | 1 |
| `setup_finish_action` | Finish screen to its one next action | 1 |
| `car_setup` | Whole car flow with the flat extra cost: "Ja", name + "Weiter", fuel card, consumption + "Weiter", "Pauschale", "Auto speichern" (typing is not a tap; PU-T08) | 6 |
| `profile_setup` | Whole profile flow, every step answered: name, avatar (pick + "Weiter"), PayPal yes, PayPal.Me, bank yes, IBAN, finish action. Typing is not a tap; the minimal path (name, skip, no, no, finish) is 5 (PU-T07) | 8 |
| `first_group` | First group with people on the step flow (from the first-run screen, PU-T12): name + "Weiter", people + "Weiter", currency "Überspringen", finish action. Typing is not a tap; the entry tap on the first-run screen is not counted | 4 |
| `commute_template` | New commute route on the step flow (PU-T12): name + "Weiter", distance + "Weiter", car (preselected) "Weiter", driver pick, passenger pick, "Weiter", tolls + "Weiter", finish action. Typing is not a tap; the shortest path (car, skip people, skip tolls) is 6 | 8 |
| `send_feedback` | Settings to a sent report (ADR-29, P7-T10): "Feedback" row, a type chip, "Senden". Typing the text is not a tap; screenshots, email and app info are optional extras | 3 |

```json
{
  "log_commute_ride": {"maxTaps": 3},
  "add_equal_split_expense": {"maxTaps": 5},
  "add_recurring_expense": {"maxTaps": 4},
  "mark_transfer_paid": {"maxTaps": 2},
  "create_group_with_members": {"maxTaps": 3},
  "share_group_link": {"maxTaps": 1},
  "share_group_system_share": {"maxTaps": 2},
  "join_link_claim_self": {"maxTaps": 1},
  "web_calculator": {"maxTaps": 0},
  "setup_step_answer": {"maxTaps": 2},
  "setup_step_yes_no": {"maxTaps": 1},
  "setup_step_input": {"maxTaps": 1},
  "setup_step_skip": {"maxTaps": 1},
  "setup_finish_action": {"maxTaps": 1},
  "car_setup": {"maxTaps": 6},
  "profile_setup": {"maxTaps": 8},
  "first_group": {"maxTaps": 4},
  "commute_template": {"maxTaps": 8},
  "send_feedback": {"maxTaps": 3}
}
```

The `setup_*` budgets are per step, not per flow: a whole guided flow takes as many taps as it has steps, which is why only rare flows use it (ADR-25 §4). Concrete flows (profile, car) add their own per-flow budgets (`profile_setup`, `car_setup`). `setup_step_answer` is the upper bound any step type must stay within; the specific ids are what the framework tests (`app/test/core/ui/setup_flow/setup_flow_widgets_test.dart`) hold the step types to.

Performance budgets (`traceAction`, frame times) come with the first list screens and are not tracked here yet.

## Undo convention (destructive actions)

Plan §2.6 #5: destructive ViewModel commands (delete, remove member, ...) must expose an undo (`undo<Command>()` or a returned undo handle) that the View surfaces as a snackbar action. Confirm dialogs are not used (`dialog-allowlist` arch rule). No mechanical rule exists yet because no ViewModels with destructive commands exist; see the TODO in `app/test/architecture/rules.dart`.
