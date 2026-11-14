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

  /// No description provided for @paymentSectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsdaten'**
  String get paymentSectionTitle;

  /// No description provided for @paymentOpen.
  ///
  /// In de, this message translates to:
  /// **'Zahlungsdaten von {name}'**
  String paymentOpen(String name);

  /// No description provided for @paymentPaypalLabel.
  ///
  /// In de, this message translates to:
  /// **'PayPal.Me-Name'**
  String get paymentPaypalLabel;

  /// No description provided for @paymentIbanLabel.
  ///
  /// In de, this message translates to:
  /// **'IBAN'**
  String get paymentIbanLabel;

  /// No description provided for @paymentBicLabel.
  ///
  /// In de, this message translates to:
  /// **'BIC (optional)'**
  String get paymentBicLabel;

  /// No description provided for @paymentAccountNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Kontoinhaber'**
  String get paymentAccountNameLabel;

  /// No description provided for @paymentPrivacyHint.
  ///
  /// In de, this message translates to:
  /// **'IBAN, BIC und Kontoinhaber bleiben nur auf diesem Gerät.'**
  String get paymentPrivacyHint;

  /// No description provided for @paymentSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get paymentSave;

  /// No description provided for @paymentErrorPaypal.
  ///
  /// In de, this message translates to:
  /// **'Das ist kein gültiger PayPal.Me-Name.'**
  String get paymentErrorPaypal;

  /// No description provided for @paymentErrorIban.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine gültige IBAN.'**
  String get paymentErrorIban;

  /// No description provided for @paymentErrorIbanChecksum.
  ///
  /// In de, this message translates to:
  /// **'Die Prüfziffer der IBAN stimmt nicht. Vertippt?'**
  String get paymentErrorIbanChecksum;

  /// No description provided for @paymentErrorIbanMissing.
  ///
  /// In de, this message translates to:
  /// **'Dafür brauchen wir zuerst eine IBAN.'**
  String get paymentErrorIbanMissing;

  /// No description provided for @paymentErrorBic.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine gültige BIC.'**
  String get paymentErrorBic;

  /// No description provided for @paymentErrorAccountName.
  ///
  /// In de, this message translates to:
  /// **'Der Name darf höchstens 70 Zeichen haben.'**
  String get paymentErrorAccountName;

  /// No description provided for @paymentLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get paymentLinkCopied;

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

  /// No description provided for @expenseCurrencyLabel.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get expenseCurrencyLabel;

  /// No description provided for @expenseRateLabel.
  ///
  /// In de, this message translates to:
  /// **'Kurs'**
  String get expenseRateLabel;

  /// No description provided for @expenseErrorRate.
  ///
  /// In de, this message translates to:
  /// **'Gib den Kurs ein'**
  String get expenseErrorRate;

  /// No description provided for @rateInvalid.
  ///
  /// In de, this message translates to:
  /// **'Das ist kein gültiger Kurs'**
  String get rateInvalid;

  /// No description provided for @expenseConverted.
  ///
  /// In de, this message translates to:
  /// **'= {amount} (Gruppenwährung)'**
  String expenseConverted(String amount);

  /// No description provided for @tripAdd.
  ///
  /// In de, this message translates to:
  /// **'Fahrt hinzufügen'**
  String get tripAdd;

  /// No description provided for @tripFormTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrt'**
  String get tripFormTitle;

  /// No description provided for @tripDefaultTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrt'**
  String get tripDefaultTitle;

  /// No description provided for @tripResultCaption.
  ///
  /// In de, this message translates to:
  /// **'Jede Person zahlt'**
  String get tripResultCaption;

  /// No description provided for @tripResultCaptionRounded.
  ///
  /// In de, this message translates to:
  /// **'Jede Person zahlt rund'**
  String get tripResultCaptionRounded;

  /// No description provided for @tripResultDriverGets.
  ///
  /// In de, this message translates to:
  /// **'{name} bekommt {amount}'**
  String tripResultDriverGets(String name, String amount);

  /// No description provided for @tripHintFuel.
  ///
  /// In de, this message translates to:
  /// **'Trag Strecke, Verbrauch und Preis ein. Das Ergebnis siehst du sofort.'**
  String get tripHintFuel;

  /// No description provided for @tripHintKmRate.
  ///
  /// In de, this message translates to:
  /// **'Trag Strecke und Kilometerpauschale ein. Das Ergebnis siehst du sofort.'**
  String get tripHintKmRate;

  /// No description provided for @tripNoParticipants.
  ///
  /// In de, this message translates to:
  /// **'Wähle mindestens eine Person, die mitfährt.'**
  String get tripNoParticipants;

  /// No description provided for @tripTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Das ist zu viel zum Rechnen. Prüf die Zahlen.'**
  String get tripTooLarge;

  /// No description provided for @tripNumberInvalid.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine gültige Zahl'**
  String get tripNumberInvalid;

  /// No description provided for @tripDistanceLabel.
  ///
  /// In de, this message translates to:
  /// **'Strecke (einfach)'**
  String get tripDistanceLabel;

  /// No description provided for @tripUnitKm.
  ///
  /// In de, this message translates to:
  /// **'km'**
  String get tripUnitKm;

  /// No description provided for @tripRoundTrip.
  ///
  /// In de, this message translates to:
  /// **'Hin- und Rückfahrt'**
  String get tripRoundTrip;

  /// No description provided for @tripEnergyFuel.
  ///
  /// In de, this message translates to:
  /// **'Benzin / Diesel'**
  String get tripEnergyFuel;

  /// No description provided for @tripEnergyElectric.
  ///
  /// In de, this message translates to:
  /// **'Strom'**
  String get tripEnergyElectric;

  /// No description provided for @tripConsumptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get tripConsumptionLabel;

  /// No description provided for @tripUnitLitersPer100.
  ///
  /// In de, this message translates to:
  /// **'l/100 km'**
  String get tripUnitLitersPer100;

  /// No description provided for @tripUnitKwhPer100.
  ///
  /// In de, this message translates to:
  /// **'kWh/100 km'**
  String get tripUnitKwhPer100;

  /// No description provided for @tripPriceFuelLabel.
  ///
  /// In de, this message translates to:
  /// **'Preis pro Liter'**
  String get tripPriceFuelLabel;

  /// No description provided for @tripPriceElectricLabel.
  ///
  /// In de, this message translates to:
  /// **'Preis pro kWh'**
  String get tripPriceElectricLabel;

  /// No description provided for @tripUnitPerLiter.
  ///
  /// In de, this message translates to:
  /// **'{symbol}/l'**
  String tripUnitPerLiter(String symbol);

  /// No description provided for @tripUnitPerKwh.
  ///
  /// In de, this message translates to:
  /// **'{symbol}/kWh'**
  String tripUnitPerKwh(String symbol);

  /// No description provided for @tripUnitPerKm.
  ///
  /// In de, this message translates to:
  /// **'{symbol}/km'**
  String tripUnitPerKm(String symbol);

  /// No description provided for @tripWearLabel.
  ///
  /// In de, this message translates to:
  /// **'Verschleiß (optional)'**
  String get tripWearLabel;

  /// No description provided for @tripKmRateToggle.
  ///
  /// In de, this message translates to:
  /// **'Kilometerpauschale'**
  String get tripKmRateToggle;

  /// No description provided for @tripKmRateHint.
  ///
  /// In de, this message translates to:
  /// **'Ersetzt Sprit und Verschleiß'**
  String get tripKmRateHint;

  /// No description provided for @tripKmRateLabel.
  ///
  /// In de, this message translates to:
  /// **'Pauschale pro km'**
  String get tripKmRateLabel;

  /// No description provided for @tripTollsLabel.
  ///
  /// In de, this message translates to:
  /// **'Maut (optional)'**
  String get tripTollsLabel;

  /// No description provided for @tripFerryLabel.
  ///
  /// In de, this message translates to:
  /// **'Fähre (optional)'**
  String get tripFerryLabel;

  /// No description provided for @tripDriverLabel.
  ///
  /// In de, this message translates to:
  /// **'Wer fährt?'**
  String get tripDriverLabel;

  /// No description provided for @tripPassengersLabel.
  ///
  /// In de, this message translates to:
  /// **'Wer fährt mit?'**
  String get tripPassengersLabel;

  /// No description provided for @tripDriverPays.
  ///
  /// In de, this message translates to:
  /// **'Fahrer zahlt mit'**
  String get tripDriverPays;

  /// No description provided for @tripTitleLabel.
  ///
  /// In de, this message translates to:
  /// **'Wohin ging’s? (optional)'**
  String get tripTitleLabel;

  /// No description provided for @tripSave.
  ///
  /// In de, this message translates to:
  /// **'Fahrt speichern'**
  String get tripSave;

  /// No description provided for @tripSaved.
  ///
  /// In de, this message translates to:
  /// **'Fahrt gespeichert'**
  String get tripSaved;

  /// No description provided for @tripBreakdown.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get tripBreakdown;

  /// No description provided for @tripBreakdownFuel.
  ///
  /// In de, this message translates to:
  /// **'Sprit'**
  String get tripBreakdownFuel;

  /// No description provided for @tripBreakdownElectric.
  ///
  /// In de, this message translates to:
  /// **'Strom'**
  String get tripBreakdownElectric;

  /// No description provided for @tripBreakdownWear.
  ///
  /// In de, this message translates to:
  /// **'Verschleiß'**
  String get tripBreakdownWear;

  /// No description provided for @tripBreakdownKmRate.
  ///
  /// In de, this message translates to:
  /// **'Kilometerpauschale'**
  String get tripBreakdownKmRate;

  /// No description provided for @tripBreakdownTolls.
  ///
  /// In de, this message translates to:
  /// **'Maut'**
  String get tripBreakdownTolls;

  /// No description provided for @tripBreakdownFerry.
  ///
  /// In de, this message translates to:
  /// **'Fähre'**
  String get tripBreakdownFerry;

  /// No description provided for @tripBreakdownTotal.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get tripBreakdownTotal;

  /// No description provided for @tripBreakdownPerPerson.
  ///
  /// In de, this message translates to:
  /// **'Pro Person'**
  String get tripBreakdownPerPerson;

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
  /// **'{count, plural, =1{{date}, {names} ist gefahren} other{{date}, {names} sind gefahren}}'**
  String ridesDayDrivers(int count, String date, String names);

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

  /// No description provided for @ridesSettleCardTitle.
  ///
  /// In de, this message translates to:
  /// **'{month} abrechnen · {count, plural, =1{1 Fahrt} other{{count} Fahrten}}'**
  String ridesSettleCardTitle(String month, int count);

  /// No description provided for @ridesSettleCardAction.
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get ridesSettleCardAction;

  /// No description provided for @ridesSettleMenu.
  ///
  /// In de, this message translates to:
  /// **'Monat abrechnen'**
  String get ridesSettleMenu;

  /// No description provided for @ridesMonthMenu.
  ///
  /// In de, this message translates to:
  /// **'Monatsmenü'**
  String get ridesMonthMenu;

  /// No description provided for @ridesSettleNothing.
  ///
  /// In de, this message translates to:
  /// **'Dieser Monat ist schon abgerechnet oder hat keine Fahrten.'**
  String get ridesSettleNothing;

  /// No description provided for @ridesSettleTitle.
  ///
  /// In de, this message translates to:
  /// **'{month} abrechnen'**
  String ridesSettleTitle(String month);

  /// No description provided for @ridesSettleDriverLine.
  ///
  /// In de, this message translates to:
  /// **'{name} bekommt {amount} für {count, plural, =1{1 Fahrt} other{{count} Fahrten}}'**
  String ridesSettleDriverLine(String name, String amount, int count);

  /// No description provided for @ridesSettleNote.
  ///
  /// In de, this message translates to:
  /// **'Pro Fahrer entsteht eine Ausgabe. Du kannst das gleich rückgängig machen.'**
  String get ridesSettleNote;

  /// No description provided for @ridesSettleAction.
  ///
  /// In de, this message translates to:
  /// **'Abrechnen'**
  String get ridesSettleAction;

  /// No description provided for @ridesSettleDone.
  ///
  /// In de, this message translates to:
  /// **'{month} abgerechnet'**
  String ridesSettleDone(String month);

  /// No description provided for @ridesSettleExpenseTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrten {period} · {name}'**
  String ridesSettleExpenseTitle(String period, String name);

  /// No description provided for @ridesFairnessTitle.
  ///
  /// In de, this message translates to:
  /// **'Fairness'**
  String get ridesFairnessTitle;

  /// No description provided for @ridesFairnessNext.
  ///
  /// In de, this message translates to:
  /// **'Als Nächstes dran: {name}'**
  String ridesFairnessNext(String name);

  /// No description provided for @ridesFairnessKm.
  ///
  /// In de, this message translates to:
  /// **'{driven} km gefahren · {ridden} km mitgefahren'**
  String ridesFairnessKm(String driven, String ridden);

  /// No description provided for @settleOpen.
  ///
  /// In de, this message translates to:
  /// **'Ausgleichen'**
  String get settleOpen;

  /// No description provided for @settleTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausgleichen'**
  String get settleTitle;

  /// No description provided for @settleOpenTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch zu zahlen'**
  String get settleOpenTitle;

  /// No description provided for @settleTransfer.
  ///
  /// In de, this message translates to:
  /// **'{from} → {to}'**
  String settleTransfer(String from, String to);

  /// No description provided for @settleSettledTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles ausgeglichen'**
  String get settleSettledTitle;

  /// No description provided for @settleSettledMessage.
  ///
  /// In de, this message translates to:
  /// **'Niemand muss noch etwas zahlen.'**
  String get settleSettledMessage;

  /// No description provided for @settleHistoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausgleiche'**
  String get settleHistoryTitle;

  /// No description provided for @settleHistoryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts bezahlt. Sobald jemand zahlt, siehst du es hier.'**
  String get settleHistoryEmpty;

  /// No description provided for @settleHistoryDelete.
  ///
  /// In de, this message translates to:
  /// **'Ausgleich löschen'**
  String get settleHistoryDelete;

  /// No description provided for @settleHistoryDeleted.
  ///
  /// In de, this message translates to:
  /// **'Ausgleich gelöscht'**
  String get settleHistoryDeleted;

  /// No description provided for @settleShare.
  ///
  /// In de, this message translates to:
  /// **'Zusammenfassung teilen'**
  String get settleShare;

  /// No description provided for @settlePaidDone.
  ///
  /// In de, this message translates to:
  /// **'{from} → {to} als bezahlt markiert'**
  String settlePaidDone(String from, String to);

  /// No description provided for @settleAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get settleAmountLabel;

  /// No description provided for @settleAmountTooHigh.
  ///
  /// In de, this message translates to:
  /// **'Das ist mehr als die offenen {amount}.'**
  String settleAmountTooHigh(String amount);

  /// No description provided for @settlePartialHint.
  ///
  /// In de, this message translates to:
  /// **'Teilzahlung: Der Rest bleibt offen.'**
  String get settlePartialHint;

  /// No description provided for @settlePayPal.
  ///
  /// In de, this message translates to:
  /// **'Mit PayPal zahlen'**
  String get settlePayPal;

  /// No description provided for @settleBankTitle.
  ///
  /// In de, this message translates to:
  /// **'Überweisung'**
  String get settleBankTitle;

  /// No description provided for @settleQrHint.
  ///
  /// In de, this message translates to:
  /// **'Mit der Banking-App scannen'**
  String get settleQrHint;

  /// No description provided for @settleQrLabel.
  ///
  /// In de, this message translates to:
  /// **'QR-Code für die Überweisung an {name}'**
  String settleQrLabel(String name);

  /// No description provided for @settleCopyIban.
  ///
  /// In de, this message translates to:
  /// **'IBAN kopieren'**
  String get settleCopyIban;

  /// No description provided for @settleIbanCopied.
  ///
  /// In de, this message translates to:
  /// **'IBAN kopiert'**
  String get settleIbanCopied;

  /// No description provided for @settleNoDetails.
  ///
  /// In de, this message translates to:
  /// **'{name} hat noch keine Zahlungsdaten — trotzdem als bezahlt markieren?'**
  String settleNoDetails(String name);

  /// No description provided for @settleMarkPaid.
  ///
  /// In de, this message translates to:
  /// **'Als bezahlt markieren'**
  String get settleMarkPaid;

  /// No description provided for @settleActionFailed.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Versuch es nochmal.'**
  String get settleActionFailed;

  /// No description provided for @exportMenu.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get exportMenu;

  /// No description provided for @exportTitle.
  ///
  /// In de, this message translates to:
  /// **'Exportieren'**
  String get exportTitle;

  /// No description provided for @exportCsv.
  ///
  /// In de, this message translates to:
  /// **'Tabelle (CSV)'**
  String get exportCsv;

  /// No description provided for @exportCsvHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Ausgaben und Salden'**
  String get exportCsvHint;

  /// No description provided for @exportPdf.
  ///
  /// In de, this message translates to:
  /// **'Abrechnung (PDF)'**
  String get exportPdf;

  /// No description provided for @exportPdfHint.
  ///
  /// In de, this message translates to:
  /// **'Wer wem wie viel zahlt, mit Ausgabenliste'**
  String get exportPdfHint;

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Versuch es nochmal.'**
  String get exportFailed;

  /// No description provided for @exportColDate.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get exportColDate;

  /// No description provided for @exportColTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get exportColTitle;

  /// No description provided for @exportColCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get exportColCategory;

  /// No description provided for @exportColAmount.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get exportColAmount;

  /// No description provided for @exportColCurrency.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get exportColCurrency;

  /// No description provided for @exportColPaidBy.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt von'**
  String get exportColPaidBy;

  /// No description provided for @exportColMember.
  ///
  /// In de, this message translates to:
  /// **'Person'**
  String get exportColMember;

  /// No description provided for @exportColBalance.
  ///
  /// In de, this message translates to:
  /// **'Saldo'**
  String get exportColBalance;

  /// No description provided for @exportColPaid.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt'**
  String get exportColPaid;

  /// No description provided for @exportColShare.
  ///
  /// In de, this message translates to:
  /// **'Anteil'**
  String get exportColShare;

  /// No description provided for @exportBalances.
  ///
  /// In de, this message translates to:
  /// **'Salden'**
  String get exportBalances;

  /// No description provided for @exportReportTitle.
  ///
  /// In de, this message translates to:
  /// **'Abrechnung'**
  String get exportReportTitle;

  /// No description provided for @exportPeriod.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum: {from} – {to}'**
  String exportPeriod(String from, String to);

  /// No description provided for @exportPeriodNone.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben'**
  String get exportPeriodNone;

  /// No description provided for @exportMembers.
  ///
  /// In de, this message translates to:
  /// **'Personen'**
  String get exportMembers;

  /// No description provided for @exportTotals.
  ///
  /// In de, this message translates to:
  /// **'Summen pro Person'**
  String get exportTotals;

  /// No description provided for @exportTransfers.
  ///
  /// In de, this message translates to:
  /// **'Ausgleich'**
  String get exportTransfers;

  /// No description provided for @exportAllSettled.
  ///
  /// In de, this message translates to:
  /// **'Alles ausgeglichen'**
  String get exportAllSettled;

  /// No description provided for @exportExpenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben'**
  String get exportExpenses;

  /// No description provided for @exportPaypal.
  ///
  /// In de, this message translates to:
  /// **'PayPal: {handle}'**
  String exportPaypal(String handle);

  /// No description provided for @exportIbanHint.
  ///
  /// In de, this message translates to:
  /// **'IBAN {hint}'**
  String exportIbanHint(String hint);

  /// No description provided for @exportCategoryFood.
  ///
  /// In de, this message translates to:
  /// **'Essen'**
  String get exportCategoryFood;

  /// No description provided for @exportCategoryStay.
  ///
  /// In de, this message translates to:
  /// **'Unterkunft'**
  String get exportCategoryStay;

  /// No description provided for @exportCategoryTransport.
  ///
  /// In de, this message translates to:
  /// **'Transport'**
  String get exportCategoryTransport;

  /// No description provided for @exportCategoryFun.
  ///
  /// In de, this message translates to:
  /// **'Freizeit'**
  String get exportCategoryFun;

  /// No description provided for @exportCategoryOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get exportCategoryOther;

  /// No description provided for @onboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei mitlio'**
  String get onboardingTitle;

  /// No description provided for @onboardingValue.
  ///
  /// In de, this message translates to:
  /// **'Fahrtkosten und Ausgaben fair teilen — ohne Anmeldung, ohne Werbung.'**
  String get onboardingValue;

  /// No description provided for @onboardingCommute.
  ///
  /// In de, this message translates to:
  /// **'Fahrgemeinschaft starten'**
  String get onboardingCommute;

  /// No description provided for @onboardingCommuteHint.
  ///
  /// In de, this message translates to:
  /// **'Auto und Strecke einmal anlegen, dann reichen 2 Taps pro Fahrt.'**
  String get onboardingCommuteHint;

  /// No description provided for @onboardingCommuteGroupName.
  ///
  /// In de, this message translates to:
  /// **'Fahrgemeinschaft'**
  String get onboardingCommuteGroupName;

  /// No description provided for @onboardingGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe für Ausgaben anlegen'**
  String get onboardingGroup;

  /// No description provided for @onboardingGroupHint.
  ///
  /// In de, this message translates to:
  /// **'Für Reisen, die WG oder einen Abend zu mehreren.'**
  String get onboardingGroupHint;

  /// No description provided for @onboardingTripOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur eine Fahrt berechnen'**
  String get onboardingTripOnly;

  /// No description provided for @tripSeatName.
  ///
  /// In de, this message translates to:
  /// **'Person {number}'**
  String tripSeatName(int number);

  /// No description provided for @tripShare.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis teilen'**
  String get tripShare;

  /// No description provided for @tripShareText.
  ///
  /// In de, this message translates to:
  /// **'Fahrtkosten: jede Person zahlt {amount}'**
  String tripShareText(String amount);

  /// No description provided for @balancesEmptyAction.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe eintragen'**
  String get balancesEmptyAction;
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
