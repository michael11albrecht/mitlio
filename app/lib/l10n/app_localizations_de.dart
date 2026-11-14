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
  String get paymentSectionTitle => 'Zahlungsdaten';

  @override
  String paymentOpen(String name) {
    return 'Zahlungsdaten von $name';
  }

  @override
  String get paymentPaypalLabel => 'PayPal.Me-Name';

  @override
  String get paymentIbanLabel => 'IBAN';

  @override
  String get paymentBicLabel => 'BIC (optional)';

  @override
  String get paymentAccountNameLabel => 'Kontoinhaber';

  @override
  String get paymentPrivacyHint =>
      'IBAN, BIC und Kontoinhaber bleiben nur auf diesem Gerät.';

  @override
  String get paymentSave => 'Speichern';

  @override
  String get paymentErrorPaypal => 'Das ist kein gültiger PayPal.Me-Name.';

  @override
  String get paymentErrorIban => 'Das ist keine gültige IBAN.';

  @override
  String get paymentErrorIbanChecksum =>
      'Die Prüfziffer der IBAN stimmt nicht. Vertippt?';

  @override
  String get paymentErrorIbanMissing => 'Dafür brauchen wir zuerst eine IBAN.';

  @override
  String get paymentErrorBic => 'Das ist keine gültige BIC.';

  @override
  String get paymentErrorAccountName =>
      'Der Name darf höchstens 70 Zeichen haben.';

  @override
  String get paymentLinkCopied => 'Link kopiert';

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

  @override
  String get tabRides => 'Fahrten';

  @override
  String get ridesEmptyTitle => 'Noch keine Strecke';

  @override
  String get ridesEmptyMessage =>
      'Leg dein Auto und deine Strecke an — dann reichen 2 Taps pro Fahrt.';

  @override
  String get ridesEmptyActionVehicle => 'Auto und Strecke anlegen';

  @override
  String get ridesEmptyActionTemplate => 'Strecke anlegen';

  @override
  String get ridesNoMembersMessage =>
      'Füge zuerst die Leute hinzu, die mitfahren.';

  @override
  String get ridesSettings => 'Fahrzeuge und Strecken';

  @override
  String get quickLogTitleToday => 'Heute gefahren';

  @override
  String quickLogTitleDate(String date) {
    return 'Gefahren am $date';
  }

  @override
  String get quickLogPickRoute => 'Wähle deine Strecke.';

  @override
  String get quickLogDriver => 'Wer fährt?';

  @override
  String get quickLogPassengers => 'Wer fährt mit?';

  @override
  String get quickLogSave => 'Speichern';

  @override
  String get quickLogAnother => 'Weitere Fahrt';

  @override
  String quickLogDone(String name) {
    return '$name ist gefahren';
  }

  @override
  String quickLogPrice(String price, String unit) {
    return 'Kraftstoff $price je $unit';
  }

  @override
  String quickLogPriceLabel(String unit) {
    return 'Preis je $unit';
  }

  @override
  String get quickLogPriceSet => 'Übernehmen';

  @override
  String get quickLogBackToToday => 'Zurück zu heute';

  @override
  String get ridesUnitLitre => 'l';

  @override
  String get ridesUnitKwh => 'kWh';

  @override
  String ridesDistanceOneWay(String km) {
    return '$km km';
  }

  @override
  String ridesDistanceRoundTrip(String km) {
    return '2 × $km km';
  }

  @override
  String ridesRouteLine(String name, String distance) {
    return '$name · $distance';
  }

  @override
  String ridesOwes(String name, String amount) {
    return '$name zahlt $amount';
  }

  @override
  String get ridesNobodyOwes => 'Keine Mitfahrer, nichts zu teilen';

  @override
  String ridesSaved(String summary) {
    return 'Gespeichert · $summary';
  }

  @override
  String get ridesRideDeleted => 'Fahrt gelöscht';

  @override
  String get ridesLocked => 'Abgerechnet, gesperrt';

  @override
  String get ridesMonthPrev => 'Vorheriger Monat';

  @override
  String get ridesMonthNext => 'Nächster Monat';

  @override
  String get ridesMonthEmpty => 'In diesem Monat noch keine Fahrt';

  @override
  String ridesDayDrivers(String date, String names) {
    return '$date: $names';
  }

  @override
  String get ridesDayNoRides => 'Keine Fahrt an diesem Tag';

  @override
  String get ridesDayLog => 'Fahrt für diesen Tag erfassen';

  @override
  String ridesRideTitle(String name, String distance) {
    return '$name fuhr · $distance';
  }

  @override
  String ridesRidePassengers(String names) {
    return 'mit $names';
  }

  @override
  String get ridesRideDelete => 'Fahrt löschen';

  @override
  String get ridesSettingsTitle => 'Fahrzeuge und Strecken';

  @override
  String get ridesVehicles => 'Fahrzeuge';

  @override
  String get ridesTemplates => 'Strecken';

  @override
  String get ridesVehiclesEmpty => 'Noch kein Fahrzeug';

  @override
  String get ridesTemplatesEmpty => 'Noch keine Strecke';

  @override
  String get ridesVehicleAdd => 'Fahrzeug hinzufügen';

  @override
  String get ridesTemplateAdd => 'Strecke hinzufügen';

  @override
  String ridesVehicleDeleted(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String ridesTemplateDeleted(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get ridesVehicleInUse =>
      'Das Fahrzeug wird noch von einer Strecke genutzt.';

  @override
  String ridesVehicleLine(String fuel, String consumption, String unit) {
    return '$fuel · $consumption $unit/100 km';
  }

  @override
  String get ridesDelete => 'Löschen';

  @override
  String get fuelPetrol => 'Benzin';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelElectric => 'Elektro';

  @override
  String get fuelOther => 'Andere';

  @override
  String get vehicleFormNew => 'Neues Fahrzeug';

  @override
  String get vehicleFormEdit => 'Fahrzeug bearbeiten';

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'z. B. Golf';

  @override
  String get vehicleFuelSection => 'Antrieb';

  @override
  String get vehicleConsumptionLitre => 'Verbrauch (l/100 km)';

  @override
  String get vehicleConsumptionKwh => 'Verbrauch (kWh/100 km)';

  @override
  String get vehicleWearLabel => 'Verschleiß je km (optional)';

  @override
  String get vehicleKmRateLabel => 'Pauschale je km (optional)';

  @override
  String get vehicleKmRateHelper =>
      'Mit Pauschale zählt der Betrag je km statt Sprit und Verschleiß.';

  @override
  String get vehicleErrorName => 'Gib einen Namen ein';

  @override
  String get vehicleErrorConsumption => 'Gib den Verbrauch ein';

  @override
  String get vehicleSave => 'Speichern';

  @override
  String get templateFormNew => 'Neue Strecke';

  @override
  String get templateFormEdit => 'Strecke bearbeiten';

  @override
  String get templateNameLabel => 'Name';

  @override
  String get templateNameHint => 'z. B. Arbeit';

  @override
  String get templateDistanceLabel => 'Entfernung einfach (km)';

  @override
  String get templateRoundTrip => 'Hin- und Rückfahrt';

  @override
  String get templateVehicleSection => 'Fahrzeug';

  @override
  String get templateDriverSection => 'Fahrer';

  @override
  String get templateDriverNone => 'Wechselt';

  @override
  String get templatePassengersSection => 'Fährt mit';

  @override
  String get templateTollsLabel => 'Maut (optional)';

  @override
  String get templateErrorName => 'Gib einen Namen ein';

  @override
  String get templateErrorDistance => 'Gib die Entfernung ein';

  @override
  String get templateNoVehicle => 'Lege zuerst ein Fahrzeug an.';

  @override
  String get templateNoVehicleAction => 'Fahrzeug anlegen';

  @override
  String get templateSave => 'Speichern';

  @override
  String ridesSettleCardTitle(String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten',
      one: '1 Fahrt',
    );
    return '$month abrechnen · $_temp0';
  }

  @override
  String get ridesSettleCardAction => 'Ansehen';

  @override
  String get ridesSettleMenu => 'Monat abrechnen';

  @override
  String get ridesMonthMenu => 'Monatsmenü';

  @override
  String get ridesSettleNothing =>
      'Dieser Monat ist schon abgerechnet oder hat keine Fahrten.';

  @override
  String ridesSettleTitle(String month) {
    return '$month abrechnen';
  }

  @override
  String ridesSettleDriverLine(String name, String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fahrten',
      one: '1 Fahrt',
    );
    return '$name bekommt $amount für $_temp0';
  }

  @override
  String get ridesSettleNote =>
      'Pro Fahrer entsteht eine Ausgabe. Du kannst das gleich rückgängig machen.';

  @override
  String get ridesSettleAction => 'Abrechnen';

  @override
  String ridesSettleDone(String month) {
    return '$month abgerechnet';
  }

  @override
  String ridesSettleExpenseTitle(String period, String name) {
    return 'Fahrten $period · $name';
  }

  @override
  String get ridesFairnessTitle => 'Fairness';

  @override
  String ridesFairnessNext(String name) {
    return 'Als Nächstes dran: $name';
  }

  @override
  String ridesFairnessKm(String driven, String ridden) {
    return '$driven km gefahren · $ridden km mitgefahren';
  }

  @override
  String get settleOpen => 'Ausgleichen';

  @override
  String get settleTitle => 'Ausgleichen';

  @override
  String get settleOpenTitle => 'Noch zu zahlen';

  @override
  String settleTransfer(String from, String to) {
    return '$from → $to';
  }

  @override
  String get settleSettledTitle => 'Alles ausgeglichen';

  @override
  String get settleSettledMessage => 'Niemand muss noch etwas zahlen.';

  @override
  String get settleHistoryTitle => 'Ausgleiche';

  @override
  String get settleHistoryEmpty =>
      'Noch nichts bezahlt. Sobald jemand zahlt, siehst du es hier.';

  @override
  String get settleHistoryDelete => 'Ausgleich löschen';

  @override
  String get settleHistoryDeleted => 'Ausgleich gelöscht';

  @override
  String get settleShare => 'Zusammenfassung teilen';

  @override
  String settlePaidDone(String from, String to) {
    return '$from → $to als bezahlt markiert';
  }

  @override
  String get settleAmountLabel => 'Betrag';

  @override
  String settleAmountTooHigh(String amount) {
    return 'Das ist mehr als die offenen $amount.';
  }

  @override
  String get settlePartialHint => 'Teilzahlung: Der Rest bleibt offen.';

  @override
  String get settlePayPal => 'Mit PayPal zahlen';

  @override
  String get settleBankTitle => 'Überweisung';

  @override
  String get settleQrHint => 'Mit der Banking-App scannen';

  @override
  String settleQrLabel(String name) {
    return 'QR-Code für die Überweisung an $name';
  }

  @override
  String get settleCopyIban => 'IBAN kopieren';

  @override
  String get settleIbanCopied => 'IBAN kopiert';

  @override
  String settleNoDetails(String name) {
    return '$name hat noch keine Zahlungsdaten — trotzdem als bezahlt markieren?';
  }

  @override
  String get settleMarkPaid => 'Als bezahlt markieren';

  @override
  String get settleActionFailed =>
      'Das hat nicht geklappt. Versuch es nochmal.';
}
