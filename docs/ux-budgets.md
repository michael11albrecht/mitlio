# UX budgets

Tap budgets per core flow (plan §2.6, product rule #0). Integration and widget tests count taps with `TapCounter` (`app/test/support/tap_counter.dart`) and call `expectWithinBudget('<flow>')`.

The fenced JSON block below is the single source: the helper parses it. Keys are flow ids. `maxTaps` is the inclusive tap limit; text entry is counted separately and never as a tap. Raising a budget is a product decision, not an implementation fix.

| Flow id | Flow | Max taps |
|---|---|---|
| `log_commute_ride` | Log a commute ride | 3 |
| `add_equal_split_expense` | Add an equal-split expense (plus typing the amount/title) | 5 |
| `mark_transfer_paid` | Mark a transfer as paid | 2 |
| `web_calculator` | Web calculator shows the result without pressing any button | 0 |

```json
{
  "log_commute_ride": {"maxTaps": 3},
  "add_equal_split_expense": {"maxTaps": 5},
  "mark_transfer_paid": {"maxTaps": 2},
  "web_calculator": {"maxTaps": 0}
}
```

Performance budgets (`traceAction`, frame times) come with the first list screens and are not tracked here yet.

## Undo convention (destructive actions)

Plan §2.6 #5: destructive ViewModel commands (delete, remove member, ...) must expose an undo (`undo<Command>()` or a returned undo handle) that the View surfaces as a snackbar action. Confirm dialogs are not used (`dialog-allowlist` arch rule). No mechanical rule exists yet because no ViewModels with destructive commands exist; see the TODO in `app/test/architecture/rules.dart`.
