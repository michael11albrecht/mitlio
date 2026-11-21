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
  String get errorNotFound =>
      'Das gibt es nicht mehr. Geh einen Schritt zurück und lad neu.';

  @override
  String get errorConflict =>
      'Das geht gerade nicht, weil sich etwas geändert hat. Prüf den Stand und versuch es nochmal.';

  @override
  String get errorLocked =>
      'Das ist schon abgerechnet und lässt sich nicht mehr ändern.';

  @override
  String get errorInvalidData =>
      'Die Eingabe passt nicht. Prüf sie und versuch es nochmal.';

  @override
  String get errorStorage =>
      'Das hat nicht geklappt. Prüf den freien Speicher deines Geräts und versuch es nochmal.';

  @override
  String get shareFailed => 'Teilen hat nicht geklappt. Versuch es nochmal.';

  @override
  String get errorRateLimited =>
      'Zu viele Anfragen. Versuch es in ein paar Minuten nochmal.';

  @override
  String errorRateLimitedIn(int minutes) {
    return 'Zu viele Anfragen. Versuch es in $minutes Min. nochmal.';
  }

  @override
  String get remoteErrorOffline =>
      'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, sobald du online bist.';

  @override
  String get remoteErrorRateLimited =>
      'Zu viele Versuche. Versuch es in ein paar Minuten nochmal.';

  @override
  String remoteErrorRateLimitedIn(int minutes) {
    return 'Zu viele Versuche. Versuch es in $minutes Min. nochmal.';
  }

  @override
  String get remoteErrorInviteInvalid =>
      'Dieser Link gilt nicht mehr. Bitte um einen neuen Link.';

  @override
  String remoteErrorMemberAlreadyClaimed(String name) {
    return '$name ist schon mit einem anderen Handy verbunden. Wähl eine andere Person.';
  }

  @override
  String get remoteErrorMemberAlreadyClaimedNoName =>
      'Diese Person ist schon mit einem anderen Handy verbunden. Wähl eine andere Person.';

  @override
  String remoteErrorAlreadyConnected(String name) {
    return 'Du bist in dieser Gruppe schon als $name verbunden.';
  }

  @override
  String get remoteErrorAlreadyConnectedNoName =>
      'Du bist in dieser Gruppe schon verbunden.';

  @override
  String get remoteErrorMemberGone =>
      'Diese Person gibt es in der Gruppe nicht mehr. Wähl eine andere.';

  @override
  String get remoteErrorNotOwner =>
      'Das kann nur, wer die Gruppe erstellt hat.';

  @override
  String get remoteErrorNotMember =>
      'Du bist nicht mehr in dieser Gruppe. Deine Daten bleiben auf diesem Handy.';

  @override
  String get remoteErrorCannotRemoveSelf =>
      'Dich selbst kannst du hier nicht entfernen.';

  @override
  String get remoteErrorVersionTooOld =>
      'Diese Version kann nicht mehr teilen. Aktualisiere mitlio.';

  @override
  String get remoteErrorServerDown =>
      'Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal.';

  @override
  String remoteErrorRejected(String title) {
    return '„$title“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy.';
  }

  @override
  String get remoteErrorRejectedNoTitle =>
      'Das konnte nicht geteilt werden. Es ist nur auf diesem Handy.';

  @override
  String get remoteErrorPullFailed =>
      'Neue Änderungen aus der Gruppe konnten nicht übernommen werden. Deine eigenen Daten sind sicher. Versuch es später nochmal oder aktualisiere mitlio.';

  @override
  String get errorSettingNotSaved =>
      'Die Einstellung konnte nicht gespeichert werden. Versuch es nochmal.';

  @override
  String get errorUndoFailed =>
      'Rückgängig machen hat nicht geklappt. Prüf den Stand und versuch es nochmal.';

  @override
  String get retry => 'Nochmal versuchen';

  @override
  String get keyboardDone => 'Fertig';

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
  String get hideSnackBar => 'Ausblenden';

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
  String groupsArchivedEntry(int count) {
    return 'Archiviert ($count)';
  }

  @override
  String get groupsArchivedTitle => 'Archivierte Gruppen';

  @override
  String get groupRestore => 'Wiederherstellen';

  @override
  String groupRestoreLabel(String name) {
    return '$name wiederherstellen';
  }

  @override
  String groupRestored(String name) {
    return '„$name“ wiederhergestellt';
  }

  @override
  String get membersEmptyTitle => 'Noch niemand dabei';

  @override
  String get membersEmptyMessage =>
      'Füge die Leute hinzu, mit denen du teilst.';

  @override
  String get memberAddLabel => 'Name hinzufügen';

  @override
  String memberNameTaken(String name) {
    return '„$name“ ist schon in der Gruppe. Nimm einen anderen Namen.';
  }

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
  String get memberDisconnect => 'Verbindung trennen';

  @override
  String memberDisconnectFor(String name) {
    return 'Verbindung trennen, $name';
  }

  @override
  String memberDisconnected(String name) {
    return '$name ist nicht mehr verbunden';
  }

  @override
  String memberDisconnectOffline(String name) {
    return 'Keine Verbindung. Nichts geändert: $name bleibt verbunden. Versuch es nochmal, sobald du online bist.';
  }

  @override
  String memberDisconnectServerDown(String name) {
    return 'Der Server antwortet gerade nicht. Nichts geändert: $name bleibt verbunden. Versuch es in ein paar Minuten nochmal.';
  }

  @override
  String get memberDisconnectNothingChanged => 'Nichts geändert.';

  @override
  String get memberThatsMe => 'Das bin ich';

  @override
  String memberThatsMeFor(String name) {
    return 'Das bin ich, $name';
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
  String balancesOpenRides(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offene Fahrten',
      one: '1 offene Fahrt',
    );
    return 'inkl. $_temp0 ($amount)';
  }

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
  String get statsMenu => 'Statistik';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsPeriodLabel => 'Zeitraum';

  @override
  String get statsPeriodMonth => 'Monat';

  @override
  String get statsPeriod3Months => '3 Monate';

  @override
  String get statsPeriodYear => 'Jahr';

  @override
  String get statsPeriodAll => 'Alles';

  @override
  String get statsHeadlineMonth => 'Diesen Monat';

  @override
  String get statsHeadline3Months => 'Letzte 3 Monate';

  @override
  String get statsHeadlineYear => 'Dieses Jahr';

  @override
  String get statsHeadlineAll => 'Insgesamt';

  @override
  String statsTopCategory(String category, int percent) {
    return 'meist $category ($percent %)';
  }

  @override
  String statsExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben',
      one: '1 Ausgabe',
    );
    return '$_temp0';
  }

  @override
  String get statsEmptyTitle => 'Nichts in diesem Zeitraum';

  @override
  String get statsEmptyMessage =>
      'Wähle einen anderen Zeitraum oder trag eine Ausgabe ein.';

  @override
  String get statsByCategory => 'Nach Kategorie';

  @override
  String get statsCategoryNone => 'Ohne Kategorie';

  @override
  String statsPercent(int percent) {
    return '$percent %';
  }

  @override
  String statsCategorySpoken(String category, String amount, int percent) {
    return '$category: $amount, $percent Prozent';
  }

  @override
  String get statsByMember => 'Pro Person';

  @override
  String get statsPaid => 'Bezahlt';

  @override
  String get statsConsumed => 'Verbraucht';

  @override
  String statsMemberSpoken(String name, String paid, String consumed) {
    return '$name: bezahlt $paid, verbraucht $consumed';
  }

  @override
  String get statsOverTime => 'Letzte 6 Monate';

  @override
  String statsMonthSpoken(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String get statsRides => 'Fahrten';

  @override
  String statsKm(String km) {
    return '$km km';
  }

  @override
  String statsRideSpoken(String month, String km, String amount) {
    return '$month: $km Kilometer, $amount';
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
  String get expenseHistory => 'Verlauf';

  @override
  String get expenseHistoryEmpty => 'Noch keine Änderungen';

  @override
  String get expenseHistoryRestore => 'Diese Version wiederherstellen';

  @override
  String get expenseHistoryRestored => 'Version wiederhergestellt';

  @override
  String get expenseHistoryNoVisibleChange => 'Keine sichtbare Änderung';

  @override
  String expenseHistoryByAuthor(String when, String name) {
    return '$when · $name';
  }

  @override
  String expenseHistoryTitle(String from, String to) {
    return 'Titel „$from“ → „$to“';
  }

  @override
  String expenseHistoryAmount(String from, String to) {
    return 'Betrag $from → $to';
  }

  @override
  String expenseHistoryRate(String from, String to) {
    return 'Kurs $from → $to';
  }

  @override
  String expenseHistoryDate(String from, String to) {
    return 'Datum $from → $to';
  }

  @override
  String expenseHistoryCategory(String from, String to) {
    return 'Kategorie $from → $to';
  }

  @override
  String expenseHistorySplit(String from, String to) {
    return 'Aufteilung $from → $to';
  }

  @override
  String get expenseHistoryTrip => 'Reisedaten geändert';

  @override
  String expenseHistoryPayerAdded(String name) {
    return '$name hat jetzt mitbezahlt';
  }

  @override
  String expenseHistoryPayerRemoved(String name) {
    return '$name hat nicht mehr bezahlt';
  }

  @override
  String expenseHistoryPaid(String name, String from, String to) {
    return '$name hat $to statt $from bezahlt';
  }

  @override
  String expenseHistoryParticipantAdded(String name) {
    return '$name jetzt beteiligt';
  }

  @override
  String expenseHistoryParticipantRemoved(String name) {
    return '$name nicht mehr beteiligt';
  }

  @override
  String expenseHistoryShare(String name, String from, String to) {
    return 'Anteil von $name: $from → $to';
  }

  @override
  String get expenseHistoryUnknownMember => 'Unbekannt';

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
  String get expenseCurrencyLabel => 'Währung';

  @override
  String get expenseRateLabel => 'Kurs';

  @override
  String get expenseErrorRate => 'Gib den Kurs ein';

  @override
  String get rateInvalid => 'Das ist kein gültiger Kurs';

  @override
  String expenseRateSuggestion(
    String from,
    String rate,
    String symbol,
    String date,
  ) {
    return '1 $from = $rate $symbol · EZB, $date';
  }

  @override
  String get expenseRateUse => 'Übernehmen';

  @override
  String expenseConverted(String amount) {
    return '= $amount (Gruppenwährung)';
  }

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
  String tripTooFar(String max) {
    return 'Das ist weiter, als eine Fahrt sein kann. Maximal $max km.';
  }

  @override
  String tripTooHigh(String max) {
    return 'Das ist unwahrscheinlich hoch. Maximal $max.';
  }

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
  String ridesDayDrivers(int count, String date, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date, $names sind gefahren',
      one: '$date, $names ist gefahren',
    );
    return '$_temp0';
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
  String vehicleCatalogEngine(String litres) {
    return '$litres l';
  }

  @override
  String vehicleCatalogPower(int kw) {
    return '$kw kW';
  }

  @override
  String vehicleCatalogHybrid(String fuel) {
    return '$fuel-Hybrid';
  }

  @override
  String vehicleCatalogConsumptionLitre(String value) {
    return '$value l/100 km';
  }

  @override
  String vehicleCatalogConsumptionKwh(String value) {
    return '$value kWh/100 km';
  }

  @override
  String get vehicleCatalogSuggestions => 'Fahrzeugvorschläge';

  @override
  String get vehicleCatalogSource => 'Daten: EEA, CC BY 4.0';

  @override
  String get vehicleCatalogNoMatch =>
      'Nicht dabei? Trag den Verbrauch selbst ein, z. B. aus deinem Bordcomputer.';

  @override
  String get vehicleCatalogUnavailable =>
      'Die Fahrzeugliste konnte nicht geladen werden. Trag den Verbrauch selbst ein, z. B. aus deinem Bordcomputer.';

  @override
  String get vehicleCatalogWltpNote =>
      'Herstellerangabe (WLTP). Im Alltag verbrauchst du meist etwa 20 % mehr.';

  @override
  String get vehicleCatalogWltpNoteElectric =>
      'Herstellerangabe (WLTP). Im Alltag brauchst du meist etwas mehr.';

  @override
  String get vehicleCatalogRealisticNote =>
      'Geschätzter Alltagswert: Herstellerangabe (WLTP) plus etwa 20 %. Das ist eine Schätzung, kein offizieller Wert.';

  @override
  String vehicleCatalogUseRealistic(String value) {
    return 'Realistischen Wert übernehmen: $value l/100 km';
  }

  @override
  String vehicleCatalogPicked(String name) {
    return '„$name“ übernommen. Dein Verbrauch wurde ersetzt.';
  }

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
      'Die Fahrten zählen schon im Saldo. Beim Abrechnen werden sie gesperrt und pro Fahrer zu einer Ausgabe. Du kannst das gleich rückgängig machen.';

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
  String get ridesDriversTitle => 'Wer fährt?';

  @override
  String get ridesDriversHelp =>
      'Nur Fahrer werden als Nächstes vorgeschlagen.';

  @override
  String get ridesDriverSwitch => 'Fährt selbst';

  @override
  String ridesDriverNowDrives(String name) {
    return '$name wird wieder vorgeschlagen';
  }

  @override
  String ridesDriverNotSuggested(String name) {
    return '$name wird nicht mehr vorgeschlagen';
  }

  @override
  String get ridesFairnessNotDriving =>
      'Fährt nicht · wird nicht vorgeschlagen';

  @override
  String get ridesFairnessChangeDrivers => 'Fahrer ändern';

  @override
  String get ridesFairnessHow => 'Wie wird das berechnet?';

  @override
  String get ridesFairnessHowText =>
      'Vorgeschlagen wird, wer bisher am wenigsten gefahren ist – km gefahren minus km mitgefahren seit der letzten Abrechnung. Bei Gleichstand ist dran, wer am längsten nicht gefahren ist. Nur Mitglieder, die als Fahrer markiert sind, werden vorgeschlagen.';

  @override
  String ridesDriverPromptTitle(String name) {
    return 'Fährt $name nicht selbst?';
  }

  @override
  String ridesDriverPromptBody(String name, int n) {
    return '$name ist bei $n Fahrten mitgefahren, aber noch nie gefahren. Als Nichtfahrer wird $name nicht mehr als Nächstes vorgeschlagen.';
  }

  @override
  String get ridesDriverPromptMark => 'Als Nichtfahrer markieren';

  @override
  String ridesDriverPromptKeep(String name) {
    return '$name fährt auch';
  }

  @override
  String get ridesDriverPromptManage => 'Fahrer verwalten';

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

  @override
  String get exportMenu => 'Exportieren';

  @override
  String get exportTitle => 'Exportieren';

  @override
  String get exportCsv => 'Tabelle (CSV)';

  @override
  String get exportCsvHint => 'Alle Ausgaben und Salden';

  @override
  String get exportPdf => 'Abrechnung (PDF)';

  @override
  String get exportPdfHint => 'Wer wem wie viel zahlt, mit Ausgabenliste';

  @override
  String get exportFailed => 'Das hat nicht geklappt. Versuch es nochmal.';

  @override
  String get exportColDate => 'Datum';

  @override
  String get exportColTitle => 'Titel';

  @override
  String get exportColCategory => 'Kategorie';

  @override
  String get exportColAmount => 'Betrag';

  @override
  String get exportColCurrency => 'Währung';

  @override
  String get exportColPaidBy => 'Bezahlt von';

  @override
  String get exportColMember => 'Person';

  @override
  String get exportColBalance => 'Saldo';

  @override
  String get exportColPaid => 'Bezahlt';

  @override
  String get exportColShare => 'Anteil';

  @override
  String get exportBalances => 'Salden';

  @override
  String get exportReportTitle => 'Abrechnung';

  @override
  String exportPeriod(String from, String to) {
    return 'Zeitraum: $from – $to';
  }

  @override
  String get exportPeriodNone => 'Noch keine Ausgaben';

  @override
  String get exportMembers => 'Personen';

  @override
  String get exportTotals => 'Summen pro Person';

  @override
  String get exportTransfers => 'Ausgleich';

  @override
  String get exportAllSettled => 'Alles ausgeglichen';

  @override
  String get exportExpenses => 'Ausgaben';

  @override
  String exportPaypal(String handle) {
    return 'PayPal: $handle';
  }

  @override
  String exportIbanHint(String hint) {
    return 'IBAN $hint';
  }

  @override
  String get exportCategoryFood => 'Essen';

  @override
  String get exportCategoryStay => 'Unterkunft';

  @override
  String get exportCategoryTransport => 'Transport';

  @override
  String get exportCategoryFun => 'Freizeit';

  @override
  String get exportCategoryOther => 'Sonstiges';

  @override
  String get onboardingTitle => 'Willkommen bei mitlio';

  @override
  String get onboardingValue =>
      'Fahrtkosten und Ausgaben fair teilen — ohne Anmeldung, ohne Werbung.';

  @override
  String get onboardingCommute => 'Fahrgemeinschaft starten';

  @override
  String get onboardingCommuteHint =>
      'Auto und Strecke einmal anlegen, dann reichen 2 Taps pro Fahrt.';

  @override
  String get onboardingCommuteGroupName => 'Fahrgemeinschaft';

  @override
  String get onboardingGroup => 'Gruppe für Ausgaben anlegen';

  @override
  String get onboardingGroupHint =>
      'Für Reisen, die WG oder einen Abend zu mehreren.';

  @override
  String get onboardingTripOnly => 'Nur eine Fahrt berechnen';

  @override
  String tripSeatName(int number) {
    return 'Person $number';
  }

  @override
  String get tripShare => 'Ergebnis teilen';

  @override
  String tripShareText(
    String distance,
    String total,
    String amount,
    String name,
  ) {
    return 'Fahrt $distance km: $total gesamt\nJede Person zahlt $amount an $name';
  }

  @override
  String get balancesEmptyAction => 'Ausgabe eintragen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get privacySection => 'Datenschutz';

  @override
  String get privacySummary =>
      'Deine Daten bleiben auf diesem Gerät. Nur für Spritpreise und Wechselkurse fragt die App unseren Server; Standort nur, wenn du \"In meiner Nähe\" antippst. Absturzberichte sind aus, bis du sie einschaltest.';

  @override
  String get privacyPolicyEntry => 'Datenschutzerklärung';

  @override
  String get imprintEntry => 'Impressum';

  @override
  String get crashReportsLabel => 'Absturzberichte senden';

  @override
  String get crashReportsHint =>
      'Nur bei einem Absturz: technische Fehlerdaten ohne Namen, Beträge, Notizen oder IBAN. Standardmäßig aus.';

  @override
  String get crashReportsUnavailable => 'In dieser Version nicht verfügbar.';

  @override
  String get deleteMyDataEntry => 'Alle meine Daten löschen';

  @override
  String get deleteMyDataEntryHint =>
      'Gruppen, Ausgaben und Fahrten von diesem Gerät entfernen';

  @override
  String get licensesEntry => 'Quellen und Lizenzen';

  @override
  String get licensesEntryHint => 'Daten und Schriften, die mitlio nutzt';

  @override
  String get creditLead => 'Mit';

  @override
  String get creditMid => 'gemacht von';

  @override
  String get creditName => 'Michael Albrecht';

  @override
  String get creditOpenFailed =>
      'Der Link ließ sich nicht öffnen. Wir haben ihn kopiert, du kannst ihn in deinen Browser einfügen.';

  @override
  String get licensesTitle => 'Quellen und Lizenzen';

  @override
  String get licensesEeaTitle => 'Fahrzeugliste';

  @override
  String get licensesEea =>
      'Daten: Europäische Umweltagentur (EEA), Überwachung der CO2-Emissionen von neuen Pkw (Verordnung (EU) 2019/631), CC BY 4.0. Die Werte sind Herstellerangaben (WLTP). mitlio hat sie nur zusammengefasst und nicht verändert.';

  @override
  String get licensesFontTitle => 'Schrift im PDF';

  @override
  String get licensesFont => 'Roboto, Apache License 2.0.';

  @override
  String get deleteMyDataTitle => 'Alle meine Daten löschen';

  @override
  String get deleteMyDataWhatTitle => 'Das wird gelöscht';

  @override
  String get deleteMyDataWhat =>
      'Auf diesem Gerät: alle Gruppen, Mitglieder, Ausgaben, Fahrten, Ausgleiche, Zahlungsdaten (auch IBAN und der zugehörige Schlüssel) und deine Einstellungen. Danach startet die App wie neu.';

  @override
  String get deleteMyDataServer =>
      'Auf dem Server: deine Verknüpfungen mit Gruppen und dein Konto, falls du eins hast.';

  @override
  String get deleteMyDataStaysTitle => 'Das bleibt';

  @override
  String get deleteMyDataStays =>
      'Gemeinsame Gruppendaten, die andere Mitglieder auf ihren Geräten haben, bleiben bei ihnen erhalten. Sie gehören der Gruppe, nicht dir allein.';

  @override
  String get deleteMyDataIrreversible =>
      'Das lässt sich nicht rückgängig machen.';

  @override
  String get deleteMyDataConfirmWord => 'LÖSCHEN';

  @override
  String get deleteMyDataConfirmLabel => 'Zur Bestätigung LÖSCHEN eintippen';

  @override
  String get deleteMyDataAction => 'Alles endgültig löschen';

  @override
  String get deleteMyDataFailed =>
      'Löschen hat nicht geklappt. Es wurde nichts gelöscht. Bitte versuche es noch einmal.';

  @override
  String get fuelChipsLabel => 'Spritpreis übernehmen';

  @override
  String get fuelGradeE5 => 'E5';

  @override
  String get fuelGradeE10 => 'E10';

  @override
  String get fuelGradeDiesel => 'Diesel';

  @override
  String get fuelScopeNational => 'Ø Deutschland';

  @override
  String fuelScopePlz(String plz) {
    return 'Ø PLZ $plz';
  }

  @override
  String get fuelScopeNearby => 'Ø in deiner Nähe';

  @override
  String get fuelAgeNow => 'gerade eben';

  @override
  String fuelAgeMinutes(int count) {
    return 'vor $count min';
  }

  @override
  String fuelAgeHours(int count) {
    return 'vor $count Std.';
  }

  @override
  String fuelAgeDays(int count) {
    return 'vor $count Tagen';
  }

  @override
  String fuelAgeSince(String date) {
    return 'Stand $date';
  }

  @override
  String get fuelOfflineNote => 'offline, zuletzt bekannt';

  @override
  String get fuelStaleRateLimited => 'zu viele Anfragen, zuletzt bekannt';

  @override
  String fuelStaleRateLimitedIn(int minutes) {
    return 'zu viele Anfragen, in $minutes Min. nochmal, zuletzt bekannt';
  }

  @override
  String get fuelStaleServer => 'Preisdienst nicht erreichbar, zuletzt bekannt';

  @override
  String get fuelRateLimited =>
      'Zu viele Preisabfragen – versuch es in ein paar Minuten nochmal.';

  @override
  String fuelRateLimitedIn(int minutes) {
    return 'Zu viele Preisabfragen – versuch es in $minutes Min. nochmal.';
  }

  @override
  String get fuelOffline =>
      'Keine Verbindung. Prüf dein Netz oder trag den Preis selbst ein.';

  @override
  String get fuelServerDown =>
      'Preisdienst gerade nicht erreichbar. Versuch es später nochmal oder trag den Preis selbst ein.';

  @override
  String get fuelAreasUnavailable =>
      'Postleitzahl und „In meiner Nähe“ gibt es auf diesem Server nicht. Es gilt der Bundesdurchschnitt, den Preis kannst du auch selbst eintragen.';

  @override
  String get fuelNoPrice =>
      'Gerade kein aktueller Preis verfügbar. Trag ihn einfach selbst ein.';

  @override
  String get fuelNearby => 'In meiner Nähe';

  @override
  String get fuelNearbyDenied =>
      'Standort nicht freigegeben, es gilt der Bundesdurchschnitt.';

  @override
  String get fuelNearbyBlocked =>
      'Standort ist in den Einstellungen gesperrt, es gilt der Bundesdurchschnitt.';

  @override
  String get fuelNearbyUnavailable => 'Standort gerade nicht verfügbar.';

  @override
  String get fuelPlzAction => 'PLZ eingeben';

  @override
  String get fuelPlzLabel => 'Postleitzahl';

  @override
  String get fuelPlzInvalid => 'Bitte fünf Ziffern';

  @override
  String get fuelPlzApply => 'Übernehmen';

  @override
  String get fuelNationalAction => 'Bundesweit';

  @override
  String get fuelAttributionFallback => 'Spritpreisdaten';

  @override
  String get routeToggle => 'Start und Ziel eingeben, Strecke berechnen';

  @override
  String get routeStartLabel => 'Start';

  @override
  String get routeEndLabel => 'Ziel';

  @override
  String routeResult(String km) {
    return '$km km, Strecke über die Straße';
  }

  @override
  String get routeRecalculate => 'Neu berechnen';

  @override
  String get routeSearching => 'Suche läuft …';

  @override
  String get routeCalculating => 'Strecke wird berechnet …';

  @override
  String get routeNoMatches =>
      'Keine Treffer. Probier einen anderen Ort oder trag die Kilometer selbst ein.';

  @override
  String get routeSavedHome => 'Zuhause';

  @override
  String get routeSavedWork => 'Arbeit';

  @override
  String get routeSaveAsHome => 'Als Zuhause merken';

  @override
  String get routeSaveAsWork => 'Als Arbeit merken';

  @override
  String get routeSavedAsHome => 'Als Zuhause gemerkt';

  @override
  String get routeSavedAsWork => 'Als Arbeit gemerkt';

  @override
  String get routeOffline =>
      'Keine Verbindung, trag die Kilometer einfach selbst ein.';

  @override
  String get routeRateLimited =>
      'Zu viele Streckenanfragen. Versuch es später nochmal oder trag die Kilometer selbst ein.';

  @override
  String routeRateLimitedIn(int minutes) {
    return 'Zu viele Streckenanfragen. Versuch es in $minutes Min. nochmal oder trag die Kilometer selbst ein.';
  }

  @override
  String get routeNoRoute =>
      'Zwischen diesen Orten gibt es keine Straßenverbindung. Prüf Start und Ziel oder trag die Kilometer selbst ein.';

  @override
  String get routeServerDown =>
      'Der Routendienst ist gerade nicht erreichbar. Versuch es später nochmal oder trag die Kilometer selbst ein.';

  @override
  String get routeUnconfigured =>
      'Die Streckenberechnung gibt es auf diesem Server nicht. Trag die Kilometer einfach selbst ein.';

  @override
  String get routeInvalid =>
      'Start und Ziel passen nicht zusammen. Wähl zwei verschiedene Orte oder trag die Kilometer selbst ein.';

  @override
  String get routeAttributionFallback =>
      'Karten- und Routendaten © OpenStreetMap-Mitwirkende';

  @override
  String shareUploadPartial(int uploaded, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Einträgen',
      one: 'Eintrag',
    );
    return '$uploaded von $total $_temp0 hochgeladen. Auf diesem Handy ist alles unverändert. Wir versuchen es weiter.';
  }

  @override
  String get shareGroupMissing =>
      'Diese Gruppe gibt es auf diesem Handy nicht mehr. Lade die Gruppenliste neu.';

  @override
  String get syncStatusUpToDate => 'Aktuell';

  @override
  String get syncStatusSending => 'Wird gesendet …';

  @override
  String syncStatusPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Änderungen warten',
      one: '1 Änderung wartet',
    );
    return '$_temp0';
  }

  @override
  String get syncRejectedLine => 'Eine Änderung konnte nicht geteilt werden.';

  @override
  String get syncRejectedShow => 'Ansehen';

  @override
  String get syncRejectedSheetTitle => 'Nicht geteilt';

  @override
  String get syncRejectedOk => 'OK';

  @override
  String get syncUpdateAction => 'Aktualisieren';

  @override
  String get syncUpdateOpenFailed =>
      'Der Store lässt sich nicht öffnen. Öffne ihn selbst und aktualisiere mitlio.';

  @override
  String get syncStatusUploading => 'Wird hochgeladen …';

  @override
  String syncStatusUploadingLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wird hochgeladen … noch $count Einträge',
      one: 'Wird hochgeladen … noch 1 Eintrag',
    );
    return '$_temp0';
  }

  @override
  String get shareMenu => 'Gruppe teilen';

  @override
  String get shareSheetTitle => 'Gruppe teilen';

  @override
  String get sharePreparing => 'Link wird vorbereitet …';

  @override
  String get shareLinkButton => 'Link teilen';

  @override
  String shareQrLabel(String name) {
    return 'QR-Code zum Beitreten der Gruppe $name';
  }

  @override
  String inviteShareText(String name, String link) {
    return 'Komm in die Gruppe $name bei mitlio: $link';
  }

  @override
  String get inviteRotate => 'Neuen Link erstellen';

  @override
  String get inviteRotateWarning =>
      'Der alte Link funktioniert dann nicht mehr.';

  @override
  String get inviteRotateCancel => 'Abbrechen';

  @override
  String get inviteLinkRotated =>
      'Dieser Link gilt nicht mehr. Frag, wer die Gruppe erstellt hat, nach dem neuen.';

  @override
  String get inviteNoLinkMember =>
      'Auf diesem Handy ist kein Link gespeichert. Frag, wer die Gruppe erstellt hat, nach dem Link.';

  @override
  String get inviteStoreUnreadable =>
      'Der gespeicherte Link ließ sich nicht lesen. Starte mitlio neu und versuch es nochmal.';

  @override
  String get inviteNotSaved =>
      'Der Link konnte auf diesem Handy nicht gespeichert werden. Teile ihn jetzt, später brauchst du einen neuen Link.';

  @override
  String get joinTitle => 'Wer bist du?';

  @override
  String get joinJoining => 'Du trittst der Gruppe bei …';

  @override
  String get joinConnected => 'verbunden';

  @override
  String get joinNewHere => 'Ich bin neu hier';

  @override
  String get joinNameLabel => 'Dein Name';

  @override
  String get joinNameRequired => 'Wie heißt du? Trag deinen Namen ein.';

  @override
  String get joinNameConfirm => 'Beitreten';

  @override
  String get joinSkip => 'Überspringen';

  @override
  String get joinConnecting => 'Einen Moment …';

  @override
  String get joinOffline =>
      'Keine Verbindung. Du bist der Gruppe noch nicht beigetreten und auf diesem Handy wurde nichts angelegt. Verbinde dich mit dem Internet und öffne den Link nochmal.';

  @override
  String get joinLocalFailed =>
      'Die Gruppe konnte auf diesem Handy nicht gespeichert werden. Prüfe den freien Speicher und öffne den Link nochmal.';

  @override
  String get joinOpenGroup => 'Zur Gruppe';

  @override
  String get joinClose => 'Schließen';

  @override
  String get joinConnectOffline =>
      'Keine Verbindung. Du bist in der Gruppe, aber noch mit niemandem verbunden. Versuch es nochmal, sobald du online bist.';

  @override
  String get pushPromptText =>
      'Soll mitlio dir Bescheid geben, wenn jemand etwas einträgt?';

  @override
  String get pushPromptAction => 'Ja, bitte';

  @override
  String get pushPermissionDenied =>
      'Benachrichtigungen sind aus. Schalte sie in den Systemeinstellungen ein, wenn du sie doch willst.';

  @override
  String get pushUnavailable =>
      'Benachrichtigungen gibt es in dieser Version noch nicht.';

  @override
  String get pushErrorPlatform =>
      'Benachrichtigungen ließen sich nicht einrichten. Versuch es gleich nochmal.';

  @override
  String get pushIncomingGeneric => 'Es gibt Neues in deiner Gruppe.';

  @override
  String get pushIncomingOpen => 'Ansehen';

  @override
  String get pushOpenFailed =>
      'Diese Benachrichtigung ließ sich nicht öffnen. Öffne die Gruppe in der Liste.';

  @override
  String get notifSettingsTitle => 'Benachrichtigungen';

  @override
  String get notifLevelLabel => 'Worüber soll ich dich informieren?';

  @override
  String get notifLevelAll => 'Alles';

  @override
  String get notifLevelMine => 'Nur was mich betrifft';

  @override
  String get notifLevelNone => 'Nichts';

  @override
  String get notifQuietHoursLabel => 'Ruhezeiten';

  @override
  String get notifQuietHoursHint =>
      'In dieser Zeit bekommst du keine Benachrichtigung.';

  @override
  String get notifQuietHoursFrom => 'Von';

  @override
  String get notifQuietHoursTo => 'Bis';

  @override
  String get notifHideAmountsLabel => 'Beträge ausblenden';

  @override
  String get notifHideAmountsHint =>
      'Auf dem Sperrbildschirm steht nur, dass es Neues gibt.';

  @override
  String get notifNotShared =>
      'Benachrichtigungen gibt es nur für geteilte Gruppen. Teile die Gruppe zuerst.';

  @override
  String get notifEnable => 'Benachrichtigungen einschalten';

  @override
  String get notifLoading => 'Einstellungen werden geladen';

  @override
  String pushLocExpenseAdded(String actor, String title, String amount) {
    return '$actor hat „$title“ eingetragen · $amount';
  }

  @override
  String pushLocExpenseChanged(String actor, String title, String amount) {
    return '$actor hat „$title“ geändert · $amount';
  }

  @override
  String pushLocExpenseDeleted(String actor, String title) {
    return '$actor hat „$title“ gelöscht';
  }

  @override
  String pushLocSettlementAdded(String actor, String amount) {
    return '$actor hat eine Zahlung eingetragen · $amount';
  }

  @override
  String pushLocMemberJoined(String name, String group) {
    return '$name ist „$group“ beigetreten';
  }

  @override
  String pushLocExpensesAdded(String actor, String count, String group) {
    return '$actor hat $count Ausgaben in „$group“ eingetragen';
  }

  @override
  String pushLocGroupUpdates(String count, String group) {
    return '$count Änderungen in „$group“';
  }

  @override
  String pushLocGeneric(String group) {
    return 'Neues in „$group“';
  }
}
