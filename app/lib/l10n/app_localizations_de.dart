// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'mitlio';

  @override
  String get errorTitle => 'Das hat nicht geklappt';

  @override
  String get errorMessage => 'Versuch es gleich noch einmal.';

  @override
  String get retry => 'Nochmal versuchen';

  @override
  String get amountInvalid => 'Das ist kein gültiger Betrag';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'EUR': 'Euro',
        'USD': 'US-Dollar',
        'GBP': 'Pfund',
        'CHF': 'Franken',
        'other': '$code',
      },
    );
    return '$_temp0';
  }

  @override
  String moneySpoken(int whole, String currency) {
    final intl.NumberFormat wholeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String wholeString = wholeNumberFormat.format(whole);

    return '$wholeString $currency';
  }

  @override
  String moneySpokenWithFraction(int whole, String currency, String fraction) {
    final intl.NumberFormat wholeNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String wholeString = wholeNumberFormat.format(whole);

    return '$wholeString $currency $fraction';
  }

  @override
  String moneySpokenNegative(String amount) {
    return 'minus $amount';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get dismiss => 'Schließen';

  @override
  String get groupsEmptyTitle => 'Noch keine Gruppe';

  @override
  String get groupsEmptyMessage => 'Leg die erste an.';

  @override
  String get groupNew => 'Neue Gruppe';

  @override
  String get groupCreate => 'Gruppe anlegen';

  @override
  String get groupEditTitle => 'Gruppe bearbeiten';

  @override
  String get groupNameLabel => 'Name';

  @override
  String get groupNameHint => 'z. B. Wochenendtrip';

  @override
  String get groupNameRequired => 'Gib der Gruppe einen Namen';

  @override
  String get groupCurrencyLabel => 'Währung';

  @override
  String get groupCurrencyLocked =>
      'Die Währung lässt sich nicht mehr ändern, sobald es Ausgaben gibt.';

  @override
  String get groupSave => 'Speichern';

  @override
  String get groupMenu => 'Mehr';

  @override
  String get groupArchive => 'Gruppe archivieren';

  @override
  String groupArchived(String name) {
    return '„$name“ archiviert';
  }

  @override
  String get membersEmptyTitle => 'Noch niemand dabei';

  @override
  String get membersEmptyMessage =>
      'Füge die Leute hinzu, mit denen du teilst.';

  @override
  String get memberAddLabel => 'Name hinzufügen';

  @override
  String get memberAdd => 'Hinzufügen';

  @override
  String get memberNameLabel => 'Name';

  @override
  String get memberRenameSave => 'Namen speichern';

  @override
  String memberRemove(String name) {
    return '$name entfernen';
  }

  @override
  String memberRemoved(String name) {
    return '„$name“ entfernt';
  }

  @override
  String get memberOrderHint =>
      'Zum Sortieren ziehen. Wer weiter oben steht, zahlt bei Restcents zuerst einen Cent mehr.';

  @override
  String memberInUse(String name) {
    return '$name hat Ausgaben oder Zahlungen und bleibt deshalb in der Gruppe.';
  }

  @override
  String get balancesTitle => 'Salden';

  @override
  String get balancesOpen => 'Wer bekommt was';

  @override
  String balanceGets(String name) {
    return '$name bekommt';
  }

  @override
  String balanceOwes(String name) {
    return '$name schuldet';
  }

  @override
  String balanceEven(String name) {
    return '$name ist ausgeglichen';
  }

  @override
  String get balancesSettledTitle => 'Alles ausgeglichen';

  @override
  String get balancesSettledMessage => 'Niemand schuldet jemandem etwas.';

  @override
  String get balancesEmptyTitle => 'Noch nichts zu verrechnen';

  @override
  String get balancesEmptyMessage =>
      'Sobald es Ausgaben gibt, siehst du hier, wer wem was schuldet.';

  @override
  String get balancesTransfersTitle => 'Wer zahlt wem';

  @override
  String get balancesModeSimplified => 'Einfach';

  @override
  String get balancesModeDirect => 'Direkt';

  @override
  String get balancesModeSimplifiedHint => 'So wenige Zahlungen wie möglich.';

  @override
  String get balancesModeDirectHint =>
      'Jede Schuld einzeln, zwischen den Beteiligten.';

  @override
  String balancesTransfer(String from, String to) {
    return '$from zahlt $to';
  }
}
