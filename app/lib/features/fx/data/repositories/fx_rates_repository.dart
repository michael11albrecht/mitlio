import 'package:mitlio/core/clock.dart';
import 'package:mitlio/features/fx/data/fx_suggestion.dart';
import 'package:mitlio/features/fx/data/services/fx_rate_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/fx/data/fx_suggestion.dart';

/// Looks reference rates up and remembers them for a while, so switching the
/// currency back and forth in the form does not ask again.
class FxRatesRepository {
  FxRatesRepository({
    required this._service,
    required this._clock,
    this.reuseFor = const Duration(minutes: 10),
  });

  final FxRateService _service;
  final Clock _clock;

  /// A rate fetched less ago than this is reused instead of asked again.
  final Duration reuseFor;

  final Map<String, ({FxSuggestion value, DateTime at})> _cache = {};

  /// Whether rate suggestions are on (a backend is configured).
  bool get isAvailable => _service.isConfigured;

  /// The rate of 1 [base] in [quote] on [date] (null: the latest), or null
  /// when there is none. Failures are not remembered.
  Future<FxSuggestion?> suggest({
    required Currency base,
    required Currency quote,
    DateTime? date,
  }) async {
    if (!isAvailable) return null;
    final key = '${base.code}>${quote.code}@${date?.toIso8601String()}';
    final now = _clock.now();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.at) < reuseFor) return hit.value;
    final value = await _service.fetch(base: base, quote: quote, date: date);
    if (value != null) _cache[key] = (value: value, at: now);
    return value;
  }
}
