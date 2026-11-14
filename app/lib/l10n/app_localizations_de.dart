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

  @override
  String get tabMembers => 'Mitglieder';

  @override
  String get tabExpenses => 'Ausgaben';

  @override
  String get expensesEmptyTitle => 'Noch keine Ausgabe';

  @override
  String get expensesEmptyMessage => 'Trag die erste ein.';

  @override
  String get expenseAdd => 'Ausgabe hinzufügen';

  @override
  String get expensesNoMembersMessage =>
      'Füge zuerst die Leute hinzu, die sich Kosten teilen.';

  @override
  String get expensesNoMembersAction => 'Mitglieder hinzufügen';

  @override
  String get expenseToday => 'Heute';

  @override
  String get expenseYesterday => 'Gestern';

  @override
  String expensePaidBy(String name) {
    return '$name hat bezahlt';
  }

  @override
  String expensePaidByMore(String name, int count) {
    return '$name +$count haben bezahlt';
  }

  @override
  String expenseDeleted(String title) {
    return '„$title“ gelöscht';
  }

  @override
  String get expenseDelete => 'Löschen';

  @override
  String get expenseFilterPerson => 'Person';

  @override
  String get expenseFilterCategory => 'Kategorie';

  @override
  String get expenseFilterAll => 'Alle';

  @override
  String get expenseFilterEmptyTitle => 'Nichts gefunden';

  @override
  String get expenseFilterReset => 'Filter zurücksetzen';

  @override
  String get expenseCategoryFood => 'Essen & Trinken';

  @override
  String get expenseCategoryStay => 'Unterkunft';

  @override
  String get expenseCategoryTransport => 'Verkehr';

  @override
  String get expenseCategoryFun => 'Freizeit';

  @override
  String get expenseCategoryOther => 'Sonstiges';

  @override
  String get expenseFormNew => 'Neue Ausgabe';

  @override
  String get expenseFormEdit => 'Ausgabe bearbeiten';

  @override
  String get expenseAmountLabel => 'Betrag';

  @override
  String get expenseTitleLabel => 'Wofür?';

  @override
  String get expenseTitleHint => 'z. B. Pizza';

  @override
  String get expenseDateChange => 'Datum ändern';

  @override
  String get expensePayerSection => 'Wer hat bezahlt?';

  @override
  String get expensePayerMulti => 'Mehrere haben bezahlt';

  @override
  String get expensePayerSingle => 'Nur eine Person hat bezahlt';

  @override
  String get expenseSplitSection => 'Aufteilung';

  @override
  String get expenseSplitEqual => 'Gleich';

  @override
  String get expenseSplitShares => 'Anteile';

  @override
  String get expenseSplitPercent => 'Prozent';

  @override
  String get expenseSplitExact => 'Genau';

  @override
  String get expenseCategorySection => 'Kategorie (optional)';

  @override
  String get expenseSave => 'Speichern';

  @override
  String get expenseErrorTitle => 'Gib der Ausgabe einen Titel';

  @override
  String get expenseErrorAmount => 'Gib einen Betrag ein';

  @override
  String get expenseErrorNoParticipants => 'Wähle mindestens eine Person';

  @override
  String get expenseErrorNoPayer => 'Wähle, wer bezahlt hat';

  @override
  String get expenseErrorGeneric => 'Das passt noch nicht zusammen';

  @override
  String expenseLeftOver(String amount) {
    return 'Noch $amount offen';
  }

  @override
  String expenseOver(String amount) {
    return '$amount zu viel';
  }

  @override
  String expensePercentSum(String sum) {
    return 'Zusammen $sum – es müssen 100 % sein';
  }

  @override
  String expenseSharesFewer(String name) {
    return 'Weniger Anteile für $name';
  }

  @override
  String expenseSharesMore(String name) {
    return 'Mehr Anteile für $name';
  }

  @override
  String get expenseExcluded => 'Nicht dabei';

  @override
  String get tripAdd => 'Fahrt hinzufügen';

  @override
  String get tripFormTitle => 'Fahrt';

  @override
  String get tripDefaultTitle => 'Fahrt';

  @override
  String get tripResultCaption => 'Jede Person zahlt';

  @override
  String get tripResultCaptionRounded => 'Jede Person zahlt rund';

  @override
  String tripResultDriverGets(String name, String amount) {
    return '$name bekommt $amount';
  }

  @override
  String get tripHintFuel =>
      'Trag Strecke, Verbrauch und Preis ein. Das Ergebnis siehst du sofort.';

  @override
  String get tripHintKmRate =>
      'Trag Strecke und Kilometerpauschale ein. Das Ergebnis siehst du sofort.';

  @override
  String get tripNoParticipants =>
      'Wähle mindestens eine Person, die mitfährt.';

  @override
  String get tripTooLarge => 'Das ist zu viel zum Rechnen. Prüf die Zahlen.';

  @override
  String get tripNumberInvalid => 'Das ist keine gültige Zahl';

  @override
  String get tripDistanceLabel => 'Strecke (einfach)';

  @override
  String get tripUnitKm => 'km';

  @override
  String get tripRoundTrip => 'Hin- und Rückfahrt';

  @override
  String get tripEnergyFuel => 'Benzin / Diesel';

  @override
  String get tripEnergyElectric => 'Strom';

  @override
  String get tripConsumptionLabel => 'Verbrauch';

  @override
  String get tripUnitLitersPer100 => 'l/100 km';

  @override
  String get tripUnitKwhPer100 => 'kWh/100 km';

  @override
  String get tripPriceFuelLabel => 'Preis pro Liter';

  @override
  String get tripPriceElectricLabel => 'Preis pro kWh';

  @override
  String tripUnitPerLiter(String symbol) {
    return '$symbol/l';
  }

  @override
  String tripUnitPerKwh(String symbol) {
    return '$symbol/kWh';
  }

  @override
  String tripUnitPerKm(String symbol) {
    return '$symbol/km';
  }

  @override
  String get tripWearLabel => 'Verschleiß (optional)';

  @override
  String get tripKmRateToggle => 'Kilometerpauschale';

  @override
  String get tripKmRateHint => 'Ersetzt Sprit und Verschleiß';

  @override
  String get tripKmRateLabel => 'Pauschale pro km';

  @override
  String get tripTollsLabel => 'Maut (optional)';

  @override
  String get tripFerryLabel => 'Fähre (optional)';

  @override
  String get tripDriverLabel => 'Wer fährt?';

  @override
  String get tripPassengersLabel => 'Wer fährt mit?';

  @override
  String get tripDriverPays => 'Fahrer zahlt mit';

  @override
  String get tripTitleLabel => 'Wohin ging’s? (optional)';

  @override
  String get tripSave => 'Fahrt speichern';

  @override
  String get tripSaved => 'Fahrt gespeichert';

  @override
  String get tripBreakdown => 'Details';

  @override
  String get tripBreakdownFuel => 'Sprit';

  @override
  String get tripBreakdownElectric => 'Strom';

  @override
  String get tripBreakdownWear => 'Verschleiß';

  @override
  String get tripBreakdownKmRate => 'Kilometerpauschale';

  @override
  String get tripBreakdownTolls => 'Maut';

  @override
  String get tripBreakdownFerry => 'Fähre';

  @override
  String get tripBreakdownTotal => 'Gesamt';

  @override
  String get tripBreakdownPerPerson => 'Pro Person';
}
