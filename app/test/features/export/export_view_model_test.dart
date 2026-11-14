import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/handlers/export.dart';
import 'package:mitlio/features/export/ui/export_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../helpers/fake_app.dart';
import '../balances/balances_support.dart';
import '../repo_test_support.dart' show ok;
import 'export_support.dart';

void main() {
  late FakeApp app;
  late FakeExportActions actions;
  late ProviderContainer container;

  ExportViewModel vm(String id) =>
      container.read(exportViewModelProvider(id).notifier);

  setUp(() {
    app = FakeApp();
    actions = FakeExportActions();
    container = ProviderContainer(
      overrides: [...app.overrides, ...exportOverrides(actions)],
    );
    addTearDown(container.dispose);
  });

  Future<Scenario> dinner() async {
    final s = await Scenario.create(app, ['Anna', 'Ben']);
    await s.expense({'Anna': 3000}, {'Anna': 1500, 'Ben': 1500});
    return s;
  }

  group('csv', () {
    test('lists the expenses with balances from the balances logic', () async {
      final s = await dinner();
      final csv = ok(await vm(s.group.id).csv(l10nOf('en')));
      final lines = csv.split('\r\n');
      expect(
        lines.first,
        'Date,Title,Category,Amount,Currency,Paid by,Share Anna,Share Ben',
      );
      expect(
        lines[1],
        '2026-02-01,Ausgabe,,30.00,EUR,Anna (30.00),15.00,15.00',
      );
      expect(csv, contains('Anna,15.00,EUR'));
      expect(csv, contains('Ben,-15.00,EUR'));
    });

    test('empty group: header and zero balances, no failure', () async {
      final s = await Scenario.create(app, ['Anna', 'Ben']);
      final csv = ok(await vm(s.group.id).csv(l10nOf('de')));
      expect(csv.split('\r\n').first, startsWith('Datum;Titel'));
      expect(csv, contains('Anna;0,00;EUR'));
    });

    test('unknown group is NotFound', () async {
      final r = await vm('nope').csv(l10nOf('en'));
      expect(r, isA<Err<String, RepositoryError>>());
    });

    test('repository failure is reported, not thrown', () async {
      final s = await dinner();
      app.settlements.watchError = const Storage('disk');
      final r = await vm(s.group.id).csv(l10nOf('en'));
      expect(r, isA<Err<String, RepositoryError>>());
    });
  });

  group('shareCsv', () {
    test('shares a UTF-8 file with BOM named after the group', () async {
      final s = await dinner();
      ok(await vm(s.group.id).shareCsv(l10nOf('de')));
      final file = actions.shared.single;
      expect(file.name, 'trip.csv');
      expect(file.mimeType, 'text/csv');
      expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
      expect(utf8.decode(file.bytes.skip(3).toList()), startsWith('Datum;'));
      expect(
        container.read(exportViewModelProvider(s.group.id)),
        ExportState.idle,
      );
    });

    test('share failure is an Err and the state recovers', () async {
      final s = await dinner();
      actions.failShare = const Storage('no share sheet');
      expect(
        await vm(s.group.id).shareCsv(l10nOf('de')),
        isA<Err<void, RepositoryError>>(),
      );
      expect(
        container.read(exportViewModelProvider(s.group.id)),
        ExportState.idle,
      );
    });

    test('load failure shares nothing', () async {
      final s = await dinner();
      app.members.watchError = const Storage('disk');
      expect(
        await vm(s.group.id).shareCsv(l10nOf('de')),
        isA<Err<void, RepositoryError>>(),
      );
      expect(actions.shared, isEmpty);
    });
  });

  group('sharePdf', () {
    test('renders the report and shares it', () async {
      final s = await dinner();
      ok(await vm(s.group.id).sharePdf(l10nOf('en')));
      expect(actions.reports.single.transfers.single.text, 'Ben → Anna €15.00');
      expect(actions.shared.single.name, 'trip.pdf');
      expect(actions.shared.single.mimeType, 'application/pdf');
    });

    test('empty group still produces a report', () async {
      final s = await Scenario.create(app, ['Anna', 'Ben']);
      ok(await vm(s.group.id).sharePdf(l10nOf('en')));
      expect(actions.reports.single.transfers, isEmpty);
    });

    test('render failure shares nothing', () async {
      final s = await dinner();
      actions.failRender = const Storage('font');
      expect(
        await vm(s.group.id).sharePdf(l10nOf('en')),
        isA<Err<void, RepositoryError>>(),
      );
      expect(actions.shared, isEmpty);
    });

    test('a second export while one runs is refused', () async {
      final s = await dinner();
      final first = vm(s.group.id).sharePdf(l10nOf('en'));
      final second = await vm(s.group.id).sharePdf(l10nOf('en'));
      expect(second, isA<Err<void, RepositoryError>>());
      ok(await first);
      expect(actions.shared, hasLength(1));
    });
  });

  group('ext.mitlio.export.csv', () {
    test('returns the CSV string', () async {
      final s = await dinner();
      final h = exportDriveHandlers(container)['export.csv']!;
      final r = await h({'groupId': s.group.id, 'locale': 'en'});
      expect(r['csv'], contains('Date,Title'));
      expect(r['groupId'], s.group.id);
      final de = await h({'groupId': s.group.id});
      expect(de['csv'], contains('Datum;Titel'));
    });

    test('rejects missing groupId, bad locale, unknown group', () async {
      final h = exportDriveHandlers(container)['export.csv']!;
      expect((await h({}))['error'], 'invalid_params');
      expect(
        (await h({'groupId': 'x', 'locale': 'fr'}))['error'],
        'invalid_params',
      );
      expect((await h({'groupId': 'nope'}))['error'], isNotNull);
    });
  });
}
