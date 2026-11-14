import 'package:mitlio/features/fx/data/fx_suggestion.dart';
import 'package:mitlio/features/fx/data/services/fx_rate_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory rate API for tests and DebugDrive: fixed rates per pair, a switch
/// for failures, and a log of what was asked.
class FakeFxRateService implements FxRateService {
  FakeFxRateService({
    Map<(Currency, Currency), int>? rates,
    DateTime? date,
    this.configured = true,
  }) : rates =
           rates ??
           {
             (Currency.usd, Currency.eur): 920000,
             (Currency.gbp, Currency.eur): 1150000,
           },
       date = date ?? DateTime.utc(2026, 11, 13);

  /// Group currency per 1 foreign unit, times 1e6, by (base, quote).
  final Map<(Currency, Currency), int> rates;

  /// The "ECB day" every answer carries.
  final DateTime date;

  /// Whether a backend "is configured".
  bool configured;

  /// Makes every call return nothing while set.
  bool failing = false;

  /// Every request in order; `date` is null for the latest rate.
  final List<({Currency base, Currency quote, DateTime? date})> calls = [];

  @override
  bool get isConfigured => configured;

  @override
  Future<FxSuggestion?> fetch({
    required Currency base,
    required Currency quote,
    DateTime? date,
  }) async {
    calls.add((base: base, quote: quote, date: date));
    if (!configured || failing) return null;
    final ppm = rates[(base, quote)];
    if (ppm == null) return null;
    return FxSuggestion(
      ppm: ppm,
      date: this.date,
      attribution: 'Quelle: EZB-Referenzkurse via Frankfurter',
    );
  }
}
