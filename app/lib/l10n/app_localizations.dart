import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Product name. Stays the same in every language.
  ///
  /// In de, this message translates to:
  /// **'mitlio'**
  String get appName;

  /// No description provided for @errorTitle.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In de, this message translates to:
  /// **'Versuch es gleich noch einmal.'**
  String get errorMessage;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get retry;

  /// No description provided for @amountInvalid.
  ///
  /// In de, this message translates to:
  /// **'Das ist kein gültiger Betrag'**
  String get amountInvalid;

  /// Spoken name of a currency for screen readers.
  ///
  /// In de, this message translates to:
  /// **'{code, select, EUR{Euro} USD{US-Dollar} GBP{Pfund} CHF{Franken} other{{code}}}'**
  String currencyName(String code);

  /// Screen reader text of a whole amount, e.g. '12 Euro'.
  ///
  /// In de, this message translates to:
  /// **'{whole} {currency}'**
  String moneySpoken(int whole, String currency);

  /// Screen reader text with minor units, e.g. '12 Euro 34'.
  ///
  /// In de, this message translates to:
  /// **'{whole} {currency} {fraction}'**
  String moneySpokenWithFraction(int whole, String currency, String fraction);

  /// No description provided for @moneySpokenNegative.
  ///
  /// In de, this message translates to:
  /// **'minus {amount}'**
  String moneySpokenNegative(String amount);

  /// No description provided for @undo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undo;

  /// No description provided for @dismiss.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get dismiss;

  /// No description provided for @groupsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Gruppe'**
  String get groupsEmptyTitle;

  /// No description provided for @groupsEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Leg die erste an.'**
  String get groupsEmptyMessage;

  /// No description provided for @groupNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Gruppe'**
  String get groupNew;

  /// No description provided for @groupCreate.
  ///
  /// In de, this message translates to:
  /// **'Gruppe anlegen'**
  String get groupCreate;

  /// No description provided for @groupEditTitle.
  ///
  /// In de, this message translates to:
  /// **'Gruppe bearbeiten'**
  String get groupEditTitle;

  /// No description provided for @groupNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get groupNameLabel;

  /// No description provided for @groupNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Wochenendtrip'**
  String get groupNameHint;

  /// No description provided for @groupNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Gib der Gruppe einen Namen'**
  String get groupNameRequired;

  /// No description provided for @groupCurrencyLabel.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get groupCurrencyLabel;

  /// No description provided for @groupCurrencyLocked.
  ///
  /// In de, this message translates to:
  /// **'Die Währung lässt sich nicht mehr ändern, sobald es Ausgaben gibt.'**
  String get groupCurrencyLocked;

  /// No description provided for @groupSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get groupSave;

  /// No description provided for @groupMenu.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get groupMenu;

  /// No description provided for @groupArchive.
  ///
  /// In de, this message translates to:
  /// **'Gruppe archivieren'**
  String get groupArchive;

  /// No description provided for @groupArchived.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ archiviert'**
  String groupArchived(String name);

  /// No description provided for @membersEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch niemand dabei'**
  String get membersEmptyTitle;

  /// No description provided for @membersEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Füge die Leute hinzu, mit denen du teilst.'**
  String get membersEmptyMessage;

  /// No description provided for @memberAddLabel.
  ///
  /// In de, this message translates to:
  /// **'Name hinzufügen'**
  String get memberAddLabel;

  /// No description provided for @memberAdd.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get memberAdd;

  /// No description provided for @memberNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get memberNameLabel;

  /// No description provided for @memberRenameSave.
  ///
  /// In de, this message translates to:
  /// **'Namen speichern'**
  String get memberRenameSave;

  /// No description provided for @memberRemove.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen'**
  String memberRemove(String name);

  /// No description provided for @memberRemoved.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ entfernt'**
  String memberRemoved(String name);

  /// No description provided for @memberOrderHint.
  ///
  /// In de, this message translates to:
  /// **'Zum Sortieren ziehen. Wer weiter oben steht, zahlt bei Restcents zuerst einen Cent mehr.'**
  String get memberOrderHint;

  /// No description provided for @memberInUse.
  ///
  /// In de, this message translates to:
  /// **'{name} hat Ausgaben oder Zahlungen und bleibt deshalb in der Gruppe.'**
  String memberInUse(String name);

  /// No description provided for @balancesTitle.
  ///
  /// In de, this message translates to:
  /// **'Salden'**
  String get balancesTitle;

  /// No description provided for @balancesOpen.
  ///
  /// In de, this message translates to:
  /// **'Wer bekommt was'**
  String get balancesOpen;

  /// No description provided for @balanceGets.
  ///
  /// In de, this message translates to:
  /// **'{name} bekommt'**
  String balanceGets(String name);

  /// No description provided for @balanceOwes.
  ///
  /// In de, this message translates to:
  /// **'{name} schuldet'**
  String balanceOwes(String name);

  /// No description provided for @balanceEven.
  ///
  /// In de, this message translates to:
  /// **'{name} ist ausgeglichen'**
  String balanceEven(String name);

  /// No description provided for @balancesSettledTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles ausgeglichen'**
  String get balancesSettledTitle;

  /// No description provided for @balancesSettledMessage.
  ///
  /// In de, this message translates to:
  /// **'Niemand schuldet jemandem etwas.'**
  String get balancesSettledMessage;

  /// No description provided for @balancesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts zu verrechnen'**
  String get balancesEmptyTitle;

  /// No description provided for @balancesEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Sobald es Ausgaben gibt, siehst du hier, wer wem was schuldet.'**
  String get balancesEmptyMessage;

  /// No description provided for @balancesTransfersTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer zahlt wem'**
  String get balancesTransfersTitle;

  /// No description provided for @balancesModeSimplified.
  ///
  /// In de, this message translates to:
  /// **'Einfach'**
  String get balancesModeSimplified;

  /// No description provided for @balancesModeDirect.
  ///
  /// In de, this message translates to:
  /// **'Direkt'**
  String get balancesModeDirect;

  /// No description provided for @balancesModeSimplifiedHint.
  ///
  /// In de, this message translates to:
  /// **'So wenige Zahlungen wie möglich.'**
  String get balancesModeSimplifiedHint;

  /// No description provided for @balancesModeDirectHint.
  ///
  /// In de, this message translates to:
  /// **'Jede Schuld einzeln, zwischen den Beteiligten.'**
  String get balancesModeDirectHint;

  /// No description provided for @balancesTransfer.
  ///
  /// In de, this message translates to:
  /// **'{from} zahlt {to}'**
  String balancesTransfer(String from, String to);

  /// No description provided for @tabMembers.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder'**
  String get tabMembers;

  /// No description provided for @tabExpenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get tabExpenses;

  /// No description provided for @expensesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgabe'**
  String get expensesEmptyTitle;

  /// No description provided for @expensesEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Trag die erste ein.'**
  String get expensesEmptyMessage;

  /// No description provided for @expenseAdd.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe hinzufügen'**
  String get expenseAdd;

  /// No description provided for @expensesNoMembersMessage.
  ///
  /// In de, this message translates to:
  /// **'Füge zuerst die Leute hinzu, die sich Kosten teilen.'**
  String get expensesNoMembersMessage;

  /// No description provided for @expensesNoMembersAction.
  ///
  /// In de, this message translates to:
  /// **'Mitglieder hinzufügen'**
  String get expensesNoMembersAction;

  /// No description provided for @expenseToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get expenseToday;

  /// No description provided for @expenseYesterday.
  ///
  /// In de, this message translates to:
  /// **'Gestern'**
  String get expenseYesterday;

  /// No description provided for @expensePaidBy.
  ///
  /// In de, this message translates to:
  /// **'{name} hat bezahlt'**
  String expensePaidBy(String name);

  /// No description provided for @expensePaidByMore.
  ///
  /// In de, this message translates to:
  /// **'{name} +{count} haben bezahlt'**
  String expensePaidByMore(String name, int count);

  /// No description provided for @expenseDeleted.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ gelöscht'**
  String expenseDeleted(String title);

  /// No description provided for @expenseDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get expenseDelete;

  /// No description provided for @expenseFilterPerson.
  ///
  /// In de, this message translates to:
  /// **'Person'**
  String get expenseFilterPerson;

  /// No description provided for @expenseFilterCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get expenseFilterCategory;

  /// No description provided for @expenseFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get expenseFilterAll;

  /// No description provided for @expenseFilterEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get expenseFilterEmptyTitle;

  /// No description provided for @expenseFilterReset.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get expenseFilterReset;

  /// No description provided for @expenseCategoryFood.
  ///
  /// In de, this message translates to:
  /// **'Essen & Trinken'**
  String get expenseCategoryFood;

  /// No description provided for @expenseCategoryStay.
  ///
  /// In de, this message translates to:
  /// **'Unterkunft'**
  String get expenseCategoryStay;

  /// No description provided for @expenseCategoryTransport.
  ///
  /// In de, this message translates to:
  /// **'Verkehr'**
  String get expenseCategoryTransport;

  /// No description provided for @expenseCategoryFun.
  ///
  /// In de, this message translates to:
  /// **'Freizeit'**
  String get expenseCategoryFun;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get expenseCategoryOther;

  /// No description provided for @expenseFormNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Ausgabe'**
  String get expenseFormNew;

  /// No description provided for @expenseFormEdit.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe bearbeiten'**
  String get expenseFormEdit;

  /// No description provided for @expenseAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get expenseAmountLabel;

  /// No description provided for @expenseTitleLabel.
  ///
  /// In de, this message translates to:
  /// **'Wofür?'**
  String get expenseTitleLabel;

  /// No description provided for @expenseTitleHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Pizza'**
  String get expenseTitleHint;

  /// No description provided for @expenseDateChange.
  ///
  /// In de, this message translates to:
  /// **'Datum ändern'**
  String get expenseDateChange;

  /// No description provided for @expensePayerSection.
  ///
  /// In de, this message translates to:
  /// **'Wer hat bezahlt?'**
  String get expensePayerSection;

  /// No description provided for @expensePayerMulti.
  ///
  /// In de, this message translates to:
  /// **'Mehrere haben bezahlt'**
  String get expensePayerMulti;

  /// No description provided for @expensePayerSingle.
  ///
  /// In de, this message translates to:
  /// **'Nur eine Person hat bezahlt'**
  String get expensePayerSingle;

  /// No description provided for @expenseSplitSection.
  ///
  /// In de, this message translates to:
  /// **'Aufteilung'**
  String get expenseSplitSection;

  /// No description provided for @expenseSplitEqual.
  ///
  /// In de, this message translates to:
  /// **'Gleich'**
  String get expenseSplitEqual;

  /// No description provided for @expenseSplitShares.
  ///
  /// In de, this message translates to:
  /// **'Anteile'**
  String get expenseSplitShares;

  /// No description provided for @expenseSplitPercent.
  ///
  /// In de, this message translates to:
  /// **'Prozent'**
  String get expenseSplitPercent;

  /// No description provided for @expenseSplitExact.
  ///
  /// In de, this message translates to:
  /// **'Genau'**
  String get expenseSplitExact;

  /// No description provided for @expenseCategorySection.
  ///
  /// In de, this message translates to:
  /// **'Kategorie (optional)'**
  String get expenseCategorySection;

  /// No description provided for @expenseSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get expenseSave;

  /// No description provided for @expenseErrorTitle.
  ///
  /// In de, this message translates to:
  /// **'Gib der Ausgabe einen Titel'**
  String get expenseErrorTitle;

  /// No description provided for @expenseErrorAmount.
  ///
  /// In de, this message translates to:
  /// **'Gib einen Betrag ein'**
  String get expenseErrorAmount;

  /// No description provided for @expenseErrorNoParticipants.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens eine Person'**
  String get expenseErrorNoParticipants;

  /// No description provided for @expenseErrorNoPayer.
  ///
  /// In de, this message translates to:
  /// **'Wähle, wer bezahlt hat'**
  String get expenseErrorNoPayer;

  /// No description provided for @expenseErrorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Das passt noch nicht zusammen'**
  String get expenseErrorGeneric;

  /// No description provided for @expenseLeftOver.
  ///
  /// In de, this message translates to:
  /// **'Noch {amount} offen'**
  String expenseLeftOver(String amount);

  /// No description provided for @expenseOver.
  ///
  /// In de, this message translates to:
  /// **'{amount} zu viel'**
  String expenseOver(String amount);

  /// No description provided for @expensePercentSum.
  ///
  /// In de, this message translates to:
  /// **'Zusammen {sum} – es müssen 100 % sein'**
  String expensePercentSum(String sum);

  /// No description provided for @expenseSharesFewer.
  ///
  /// In de, this message translates to:
  /// **'Weniger Anteile für {name}'**
  String expenseSharesFewer(String name);

  /// No description provided for @expenseSharesMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr Anteile für {name}'**
  String expenseSharesMore(String name);

  /// No description provided for @expenseExcluded.
  ///
  /// In de, this message translates to:
  /// **'Nicht dabei'**
  String get expenseExcluded;

  /// No description provided for @tabRides.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get tabRides;

  /// No description provided for @ridesEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Strecke'**
  String get ridesEmptyTitle;

  /// No description provided for @ridesEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Leg dein Auto und deine Strecke an — dann reichen 2 Taps pro Fahrt.'**
  String get ridesEmptyMessage;

  /// No description provided for @ridesEmptyActionVehicle.
  ///
  /// In de, this message translates to:
  /// **'Auto und Strecke anlegen'**
  String get ridesEmptyActionVehicle;

  /// No description provided for @ridesEmptyActionTemplate.
  ///
  /// In de, this message translates to:
  /// **'Strecke anlegen'**
  String get ridesEmptyActionTemplate;

  /// No description provided for @ridesNoMembersMessage.
  ///
  /// In de, this message translates to:
  /// **'Füge zuerst die Leute hinzu, die mitfahren.'**
  String get ridesNoMembersMessage;

  /// No description provided for @ridesSettings.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeuge und Strecken'**
  String get ridesSettings;

  /// No description provided for @quickLogTitleToday.
  ///
  /// In de, this message translates to:
  /// **'Heute gefahren'**
  String get quickLogTitleToday;

  /// No description provided for @quickLogTitleDate.
  ///
  /// In de, this message translates to:
  /// **'Gefahren am {date}'**
  String quickLogTitleDate(String date);

  /// No description provided for @quickLogPickRoute.
  ///
  /// In de, this message translates to:
  /// **'Wähle deine Strecke.'**
  String get quickLogPickRoute;

  /// No description provided for @quickLogDriver.
  ///
  /// In de, this message translates to:
  /// **'Wer fährt?'**
  String get quickLogDriver;

  /// No description provided for @quickLogPassengers.
  ///
  /// In de, this message translates to:
  /// **'Wer fährt mit?'**
  String get quickLogPassengers;

  /// No description provided for @quickLogSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get quickLogSave;

  /// No description provided for @quickLogAnother.
  ///
  /// In de, this message translates to:
  /// **'Weitere Fahrt'**
  String get quickLogAnother;

  /// No description provided for @quickLogDone.
  ///
  /// In de, this message translates to:
  /// **'{name} ist gefahren'**
  String quickLogDone(String name);

  /// No description provided for @quickLogPrice.
  ///
  /// In de, this message translates to:
  /// **'Kraftstoff {price} je {unit}'**
  String quickLogPrice(String price, String unit);

  /// No description provided for @quickLogPriceLabel.
  ///
  /// In de, this message translates to:
  /// **'Preis je {unit}'**
  String quickLogPriceLabel(String unit);

  /// No description provided for @quickLogPriceSet.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get quickLogPriceSet;

  /// No description provided for @quickLogBackToToday.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu heute'**
  String get quickLogBackToToday;

  /// No description provided for @ridesUnitLitre.
  ///
  /// In de, this message translates to:
  /// **'l'**
  String get ridesUnitLitre;

  /// No description provided for @ridesUnitKwh.
  ///
  /// In de, this message translates to:
  /// **'kWh'**
  String get ridesUnitKwh;

  /// No description provided for @ridesDistanceOneWay.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String ridesDistanceOneWay(String km);

  /// No description provided for @ridesDistanceRoundTrip.
  ///
  /// In de, this message translates to:
  /// **'2 × {km} km'**
  String ridesDistanceRoundTrip(String km);

  /// No description provided for @ridesRouteLine.
  ///
  /// In de, this message translates to:
  /// **'{name} · {distance}'**
  String ridesRouteLine(String name, String distance);

  /// No description provided for @ridesOwes.
  ///
  /// In de, this message translates to:
  /// **'{name} zahlt {amount}'**
  String ridesOwes(String name, String amount);

  /// No description provided for @ridesNobodyOwes.
  ///
  /// In de, this message translates to:
  /// **'Keine Mitfahrer, nichts zu teilen'**
  String get ridesNobodyOwes;

  /// No description provided for @ridesSaved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert · {summary}'**
  String ridesSaved(String summary);

  /// No description provided for @ridesRideDeleted.
  ///
  /// In de, this message translates to:
  /// **'Fahrt gelöscht'**
  String get ridesRideDeleted;

  /// No description provided for @ridesLocked.
  ///
  /// In de, this message translates to:
  /// **'Abgerechnet, gesperrt'**
  String get ridesLocked;

  /// No description provided for @ridesMonthPrev.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Monat'**
  String get ridesMonthPrev;

  /// No description provided for @ridesMonthNext.
  ///
  /// In de, this message translates to:
  /// **'Nächster Monat'**
  String get ridesMonthNext;

  /// No description provided for @ridesMonthEmpty.
  ///
  /// In de, this message translates to:
  /// **'In diesem Monat noch keine Fahrt'**
  String get ridesMonthEmpty;

  /// No description provided for @ridesDayDrivers.
  ///
  /// In de, this message translates to:
  /// **'{date}: {names}'**
  String ridesDayDrivers(String date, String names);

  /// No description provided for @ridesDayNoRides.
  ///
  /// In de, this message translates to:
  /// **'Keine Fahrt an diesem Tag'**
  String get ridesDayNoRides;

  /// No description provided for @ridesDayLog.
  ///
  /// In de, this message translates to:
  /// **'Fahrt für diesen Tag erfassen'**
  String get ridesDayLog;

  /// No description provided for @ridesRideTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} fuhr · {distance}'**
  String ridesRideTitle(String name, String distance);

  /// No description provided for @ridesRidePassengers.
  ///
  /// In de, this message translates to:
  /// **'mit {names}'**
  String ridesRidePassengers(String names);

  /// No description provided for @ridesRideDelete.
  ///
  /// In de, this message translates to:
  /// **'Fahrt löschen'**
  String get ridesRideDelete;

  /// No description provided for @ridesSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeuge und Strecken'**
  String get ridesSettingsTitle;

  /// No description provided for @ridesVehicles.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeuge'**
  String get ridesVehicles;

  /// No description provided for @ridesTemplates.
  ///
  /// In de, this message translates to:
  /// **'Strecken'**
  String get ridesTemplates;

  /// No description provided for @ridesVehiclesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Fahrzeug'**
  String get ridesVehiclesEmpty;

  /// No description provided for @ridesTemplatesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Strecke'**
  String get ridesTemplatesEmpty;

  /// No description provided for @ridesVehicleAdd.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug hinzufügen'**
  String get ridesVehicleAdd;

  /// No description provided for @ridesTemplateAdd.
  ///
  /// In de, this message translates to:
  /// **'Strecke hinzufügen'**
  String get ridesTemplateAdd;

  /// No description provided for @ridesVehicleDeleted.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ gelöscht'**
  String ridesVehicleDeleted(String name);

  /// No description provided for @ridesTemplateDeleted.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ gelöscht'**
  String ridesTemplateDeleted(String name);

  /// No description provided for @ridesVehicleInUse.
  ///
  /// In de, this message translates to:
  /// **'Das Fahrzeug wird noch von einer Strecke genutzt.'**
  String get ridesVehicleInUse;

  /// No description provided for @ridesVehicleLine.
  ///
  /// In de, this message translates to:
  /// **'{fuel} · {consumption} {unit}/100 km'**
  String ridesVehicleLine(String fuel, String consumption, String unit);

  /// No description provided for @ridesDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get ridesDelete;

  /// No description provided for @fuelPetrol.
  ///
  /// In de, this message translates to:
  /// **'Benzin'**
  String get fuelPetrol;

  /// No description provided for @fuelDiesel.
  ///
  /// In de, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// No description provided for @fuelElectric.
  ///
  /// In de, this message translates to:
  /// **'Elektro'**
  String get fuelElectric;

  /// No description provided for @fuelOther.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get fuelOther;

  /// No description provided for @vehicleFormNew.
  ///
  /// In de, this message translates to:
  /// **'Neues Fahrzeug'**
  String get vehicleFormNew;

  /// No description provided for @vehicleFormEdit.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug bearbeiten'**
  String get vehicleFormEdit;

  /// No description provided for @vehicleNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get vehicleNameLabel;

  /// No description provided for @vehicleNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Golf'**
  String get vehicleNameHint;

  /// No description provided for @vehicleFuelSection.
  ///
  /// In de, this message translates to:
  /// **'Antrieb'**
  String get vehicleFuelSection;

  /// No description provided for @vehicleConsumptionLitre.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch (l/100 km)'**
  String get vehicleConsumptionLitre;

  /// No description provided for @vehicleConsumptionKwh.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch (kWh/100 km)'**
  String get vehicleConsumptionKwh;

  /// No description provided for @vehicleWearLabel.
  ///
  /// In de, this message translates to:
  /// **'Verschleiß je km (optional)'**
  String get vehicleWearLabel;

  /// No description provided for @vehicleKmRateLabel.
  ///
  /// In de, this message translates to:
  /// **'Pauschale je km (optional)'**
  String get vehicleKmRateLabel;

  /// No description provided for @vehicleKmRateHelper.
  ///
  /// In de, this message translates to:
  /// **'Mit Pauschale zählt der Betrag je km statt Sprit und Verschleiß.'**
  String get vehicleKmRateHelper;

  /// No description provided for @vehicleErrorName.
  ///
  /// In de, this message translates to:
  /// **'Gib einen Namen ein'**
  String get vehicleErrorName;

  /// No description provided for @vehicleErrorConsumption.
  ///
  /// In de, this message translates to:
  /// **'Gib den Verbrauch ein'**
  String get vehicleErrorConsumption;

  /// No description provided for @vehicleSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get vehicleSave;

  /// No description provided for @templateFormNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Strecke'**
  String get templateFormNew;

  /// No description provided for @templateFormEdit.
  ///
  /// In de, this message translates to:
  /// **'Strecke bearbeiten'**
  String get templateFormEdit;

  /// No description provided for @templateNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get templateNameLabel;

  /// No description provided for @templateNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Arbeit'**
  String get templateNameHint;

  /// No description provided for @templateDistanceLabel.
  ///
  /// In de, this message translates to:
  /// **'Entfernung einfach (km)'**
  String get templateDistanceLabel;

  /// No description provided for @templateRoundTrip.
  ///
  /// In de, this message translates to:
  /// **'Hin- und Rückfahrt'**
  String get templateRoundTrip;

  /// No description provided for @templateVehicleSection.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug'**
  String get templateVehicleSection;

  /// No description provided for @templateDriverSection.
  ///
  /// In de, this message translates to:
  /// **'Fahrer'**
  String get templateDriverSection;

  /// No description provided for @templateDriverNone.
  ///
  /// In de, this message translates to:
  /// **'Wechselt'**
  String get templateDriverNone;

  /// No description provided for @templatePassengersSection.
  ///
  /// In de, this message translates to:
  /// **'Fährt mit'**
  String get templatePassengersSection;

  /// No description provided for @templateTollsLabel.
  ///
  /// In de, this message translates to:
  /// **'Maut (optional)'**
  String get templateTollsLabel;

  /// No description provided for @templateErrorName.
  ///
  /// In de, this message translates to:
  /// **'Gib einen Namen ein'**
  String get templateErrorName;

  /// No description provided for @templateErrorDistance.
  ///
  /// In de, this message translates to:
  /// **'Gib die Entfernung ein'**
  String get templateErrorDistance;

  /// No description provided for @templateNoVehicle.
  ///
  /// In de, this message translates to:
  /// **'Lege zuerst ein Fahrzeug an.'**
  String get templateNoVehicle;

  /// No description provided for @templateNoVehicleAction.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeug anlegen'**
  String get templateNoVehicleAction;

  /// No description provided for @templateSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get templateSave;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
