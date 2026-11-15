import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/error_snack_bar.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/l10n/app_localizations.dart';

import '../helpers/themed_app.dart';

/// No silent errors: every RepositoryError has its own plain message with a
/// next step (de, du-form).
void main() {
  Future<String> messageFor(WidgetTester tester, RepositoryError e) async {
    late String text;
    await tester.pumpWidget(
      themedApp(
        Builder(
          builder: (context) {
            text = repositoryErrorMessage(AppLocalizations.of(context), e);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return text;
  }

  testWidgets('each error type says what happened and what to do', (
    tester,
  ) async {
    expect(
      await messageFor(tester, const NotFound('group', 'g')),
      contains('nicht mehr'),
    );
    expect(await messageFor(tester, const Conflict('x')), contains('geändert'));
    expect(
      await messageFor(tester, const Locked('ride', 'r')),
      contains('abgerechnet'),
    );
    expect(
      await messageFor(tester, const InvalidData('x')),
      contains('Eingabe'),
    );
    expect(
      await messageFor(tester, const Storage('x')),
      contains('Speicher'),
    );
  });

  testWidgets('rate limit says so and names the wait when known', (
    tester,
  ) async {
    expect(
      await messageFor(tester, const RateLimited()),
      'Zu viele Anfragen. Versuch es in ein paar Minuten nochmal.',
    );
    expect(
      await messageFor(
        tester,
        const RateLimited(retryAfter: Duration(minutes: 12)),
      ),
      'Zu viele Anfragen. Versuch es in 12 Min. nochmal.',
    );
    // Less than a minute still reads "1 Min.", never "0".
    expect(
      await messageFor(
        tester,
        const RateLimited(retryAfter: Duration(seconds: 20)),
      ),
      contains('1 Min.'),
    );
  });

  testWidgets('showErrorSnackBar puts the message on screen', (tester) async {
    await tester.pumpWidget(
      themedApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showErrorSnackBar(
              ScaffoldMessenger.of(context),
              AppLocalizations.of(context),
              const RateLimited(),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Zu viele Anfragen'), findsOneWidget);
  });
}
