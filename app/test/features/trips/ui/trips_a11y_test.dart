import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/trips/ui/trip_form_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';

import '../../../helpers/a11y.dart';
import 'trips_fixtures.dart';

/// Contrast, labelled and large-enough tap targets, in light/dark and at
/// text scale 1.0 and 2.0 (plan §2.6).
void main() {
  Widget form(TripFormState s) =>
      tripScoped(tripStateOverride(s), const TripFormView(groupId: 'g-1'));

  group('trip form', () {
    final states = {
      'error': const TripFormFailure(Storage('x')),
      'no members': tripNoMembers,
      'empty': tripEmpty,
      'result': tripResult,
      'km rate': tripKmRate,
      'invalid numbers': tripInvalid,
      'nobody shares': tripNobody,
    };
    for (final e in states.entries) {
      forEachMode(
        e.key,
        () => form(e.value),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });
}
