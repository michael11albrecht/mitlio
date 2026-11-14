import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/export/ui/export_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.export.csv {groupId, locale?}` (key without the
/// `ext.mitlio.` prefix): the CSV text the export screen would share, `de` by
/// default. Tests only; nothing is shared.
Map<String, DriveHandler> exportDriveHandlers(ProviderContainer c) => {
  'export.csv': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final locale = p['locale'] ?? 'de';
    if (!AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale,
    )) {
      return invalidParams('locale must be one of de, en');
    }
    final vm = c.read(exportViewModelProvider(groupId).notifier);
    return switch (await vm.csv(lookupAppLocalizations(Locale(locale)))) {
      Ok(:final value) => {'groupId': groupId, 'csv': value},
      Err(:final error) => driveError(error),
    };
  },
};
