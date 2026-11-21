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

  /// No description provided for @errorNotFound.
  ///
  /// In de, this message translates to:
  /// **'Das gibt es nicht mehr. Geh einen Schritt zurück und lad neu.'**
  String get errorNotFound;

  /// No description provided for @errorConflict.
  ///
  /// In de, this message translates to:
  /// **'Das geht gerade nicht, weil sich etwas geändert hat. Prüf den Stand und versuch es nochmal.'**
  String get errorConflict;

  /// No description provided for @errorLocked.
  ///
  /// In de, this message translates to:
  /// **'Das ist schon abgerechnet und lässt sich nicht mehr ändern.'**
  String get errorLocked;

  /// No description provided for @errorInvalidData.
  ///
  /// In de, this message translates to:
  /// **'Die Eingabe passt nicht. Prüf sie und versuch es nochmal.'**
  String get errorInvalidData;

  /// No description provided for @errorStorage.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt. Prüf den freien Speicher deines Geräts und versuch es nochmal.'**
  String get errorStorage;

  /// No description provided for @shareFailed.
  ///
  /// In de, this message translates to:
  /// **'Teilen hat nicht geklappt. Versuch es nochmal.'**
  String get shareFailed;

  /// No description provided for @errorRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Anfragen. Versuch es in ein paar Minuten nochmal.'**
  String get errorRateLimited;

  /// No description provided for @errorRateLimitedIn.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Anfragen. Versuch es in {minutes} Min. nochmal.'**
  String errorRateLimitedIn(int minutes);

  /// No description provided for @remoteErrorOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, sobald du online bist.'**
  String get remoteErrorOffline;

  /// No description provided for @remoteErrorRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Versuch es in ein paar Minuten nochmal.'**
  String get remoteErrorRateLimited;

  /// No description provided for @remoteErrorRateLimitedIn.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Versuche. Versuch es in {minutes} Min. nochmal.'**
  String remoteErrorRateLimitedIn(int minutes);

  /// No description provided for @remoteErrorInviteInvalid.
  ///
  /// In de, this message translates to:
  /// **'Dieser Link gilt nicht mehr. Bitte um einen neuen Link.'**
  String get remoteErrorInviteInvalid;

  /// No description provided for @remoteErrorMemberAlreadyClaimed.
  ///
  /// In de, this message translates to:
  /// **'{name} ist schon mit einem anderen Handy verbunden. Wähl eine andere Person.'**
  String remoteErrorMemberAlreadyClaimed(String name);

  /// No description provided for @remoteErrorMemberAlreadyClaimedNoName.
  ///
  /// In de, this message translates to:
  /// **'Diese Person ist schon mit einem anderen Handy verbunden. Wähl eine andere Person.'**
  String get remoteErrorMemberAlreadyClaimedNoName;

  /// No description provided for @remoteErrorAlreadyConnected.
  ///
  /// In de, this message translates to:
  /// **'Du bist in dieser Gruppe schon als {name} verbunden.'**
  String remoteErrorAlreadyConnected(String name);

  /// No description provided for @remoteErrorAlreadyConnectedNoName.
  ///
  /// In de, this message translates to:
  /// **'Du bist in dieser Gruppe schon verbunden.'**
  String get remoteErrorAlreadyConnectedNoName;

  /// No description provided for @remoteErrorMemberGone.
  ///
  /// In de, this message translates to:
  /// **'Diese Person gibt es in der Gruppe nicht mehr. Wähl eine andere.'**
  String get remoteErrorMemberGone;

  /// No description provided for @remoteErrorNotOwner.
  ///
  /// In de, this message translates to:
  /// **'Das kann nur, wer die Gruppe erstellt hat.'**
  String get remoteErrorNotOwner;

  /// No description provided for @remoteErrorNotMember.
  ///
  /// In de, this message translates to:
  /// **'Du bist nicht mehr in dieser Gruppe. Deine Daten bleiben auf diesem Handy.'**
  String get remoteErrorNotMember;

  /// No description provided for @remoteErrorCannotRemoveSelf.
  ///
  /// In de, this message translates to:
  /// **'Dich selbst kannst du hier nicht entfernen.'**
  String get remoteErrorCannotRemoveSelf;

  /// No description provided for @remoteErrorVersionTooOld.
  ///
  /// In de, this message translates to:
  /// **'Diese Version kann nicht mehr teilen. Aktualisiere mitlio.'**
  String get remoteErrorVersionTooOld;

  /// No description provided for @remoteErrorServerDown.
  ///
  /// In de, this message translates to:
  /// **'Der Server antwortet gerade nicht. Wir versuchen es gleich nochmal.'**
  String get remoteErrorServerDown;

  /// No description provided for @remoteErrorRejected.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy.'**
  String remoteErrorRejected(String title);

  /// No description provided for @remoteErrorRejectedNoTitle.
  ///
  /// In de, this message translates to:
  /// **'Das konnte nicht geteilt werden. Es ist nur auf diesem Handy.'**
  String get remoteErrorRejectedNoTitle;

  /// No description provided for @remoteErrorPullFailed.
  ///
  /// In de, this message translates to:
  /// **'Neue Änderungen aus der Gruppe konnten nicht übernommen werden. Deine eigenen Daten sind sicher. Versuch es später nochmal oder aktualisiere mitlio.'**
  String get remoteErrorPullFailed;

  /// No description provided for @errorSettingNotSaved.
  ///
  /// In de, this message translates to:
  /// **'Die Einstellung konnte nicht gespeichert werden. Versuch es nochmal.'**
  String get errorSettingNotSaved;

  /// No description provided for @errorUndoFailed.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig machen hat nicht geklappt. Prüf den Stand und versuch es nochmal.'**
  String get errorUndoFailed;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get retry;

  /// Button above the iOS number pad that closes the keyboard.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get keyboardDone;

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

  /// No description provided for @hideSnackBar.
  ///
  /// In de, this message translates to:
  /// **'Ausblenden'**
  String get hideSnackBar;

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

  /// No description provided for @groupsArchivedEntry.
  ///
  /// In de, this message translates to:
  /// **'Archiviert ({count})'**
  String groupsArchivedEntry(int count);

  /// No description provided for @groupsArchivedTitle.
  ///
  /// In de, this message translates to:
  /// **'Archivierte Gruppen'**
  String get groupsArchivedTitle;

  /// No description provided for @groupRestore.
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get groupRestore;

  /// No description provided for @groupRestoreLabel.
  ///
  /// In de, this message translates to:
  /// **'{name} wiederherstellen'**
  String groupRestoreLabel(String name);

  /// No description provided for @groupRestored.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ wiederhergestellt'**
  String groupRestored(String name);

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

  /// No description provided for @memberNameTaken.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ ist schon in der Gruppe. Nimm einen anderen Namen.'**
  String memberNameTaken(String name);

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

  /// No description provided for @memberDisconnect.
  ///
  /// In de, this message translates to:
  /// **'Verbindung trennen'**
  String get memberDisconnect;

  /// No description provided for @memberDisconnectFor.
  ///
  /// In de, this message translates to:
  /// **'Verbindung trennen, {name}'**
  String memberDisconnectFor(String name);

  /// No description provided for @memberDisconnected.
  ///
  /// In de, this message translates to:
  /// **'{name} ist nicht mehr verbunden'**
  String memberDisconnected(String name);

  /// No description provided for @memberDisconnectOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Nichts geändert: {name} bleibt verbunden. Versuch es nochmal, sobald du online bist.'**
  String memberDisconnectOffline(String name);

  /// No description provided for @memberDisconnectServerDown.
  ///
  /// In de, this message translates to:
  /// **'Der Server antwortet gerade nicht. Nichts geändert: {name} bleibt verbunden. Versuch es in ein paar Minuten nochmal.'**
  String memberDisconnectServerDown(String name);

  /// No description provided for @memberDisconnectNothingChanged.
  ///
  /// In de, this message translates to:
  /// **'Nichts geändert.'**
  String get memberDisconnectNothingChanged;

  /// No description provided for @memberThatsMe.
  ///
  /// In de, this message translates to:
  /// **'Das bin ich'**
  String get memberThatsMe;

  /// No description provided for @memberThatsMeFor.
  ///
  /// In de, this message translates to:
  /// **'Das bin ich, {name}'**
  String memberThatsMeFor(String name);

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

  /// No description provided for @balancesOpenRides.
  ///
  /// In de, this message translates to:
  /// **'inkl. {count, plural, =1{1 offene Fahrt} other{{count} offene Fahrten}} ({amount})'**
  String balancesOpenRides(int count, String amount);

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

  /// No description provided for @statsMenu.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statsMenu;

  /// No description provided for @statsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statsTitle;

  /// No description provided for @statsPeriodLabel.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get statsPeriodLabel;

  /// No description provided for @statsPeriodMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get statsPeriodMonth;

  /// No description provided for @statsPeriod3Months.
  ///
  /// In de, this message translates to:
  /// **'3 Monate'**
  String get statsPeriod3Months;

  /// No description provided for @statsPeriodYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get statsPeriodYear;

  /// No description provided for @statsPeriodAll.
  ///
  /// In de, this message translates to:
  /// **'Alles'**
  String get statsPeriodAll;

  /// No description provided for @statsHeadlineMonth.
  ///
  /// In de, this message translates to:
  /// **'Diesen Monat'**
  String get statsHeadlineMonth;

  /// No description provided for @statsHeadline3Months.
  ///
  /// In de, this message translates to:
  /// **'Letzte 3 Monate'**
  String get statsHeadline3Months;

  /// No description provided for @statsHeadlineYear.
  ///
  /// In de, this message translates to:
  /// **'Dieses Jahr'**
  String get statsHeadlineYear;

  /// No description provided for @statsHeadlineAll.
  ///
  /// In de, this message translates to:
  /// **'Insgesamt'**
  String get statsHeadlineAll;

  /// No description provided for @statsTopCategory.
  ///
  /// In de, this message translates to:
  /// **'meist {category} ({percent} %)'**
  String statsTopCategory(String category, int percent);

  /// No description provided for @statsExpenseCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Ausgabe} other{{count} Ausgaben}}'**
  String statsExpenseCount(int count);

  /// No description provided for @statsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Nichts in diesem Zeitraum'**
  String get statsEmptyTitle;

  /// No description provided for @statsEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen anderen Zeitraum oder trag eine Ausgabe ein.'**
  String get statsEmptyMessage;

  /// No description provided for @statsByCategory.
  ///
  /// In de, this message translates to:
  /// **'Nach Kategorie'**
  String get statsByCategory;

  /// No description provided for @statsCategoryNone.
  ///
  /// In de, this message translates to:
  /// **'Ohne Kategorie'**
  String get statsCategoryNone;

  /// No description provided for @statsPercent.
  ///
  /// In de, this message translates to:
  /// **'{percent} %'**
  String statsPercent(int percent);

  /// No description provided for @statsCategorySpoken.
  ///
  /// In de, this message translates to:
  /// **'{category}: {amount}, {percent} Prozent'**
  String statsCategorySpoken(String category, String amount, int percent);

  /// No description provided for @statsByMember.
  ///
  /// In de, this message translates to:
  /// **'Pro Person'**
  String get statsByMember;

  /// No description provided for @statsPaid.
  ///
  /// In de, this message translates to:
  /// **'Bezahlt'**
  String get statsPaid;

  /// No description provided for @statsConsumed.
  ///
  /// In de, this message translates to:
  /// **'Verbraucht'**
  String get statsConsumed;

  /// No description provided for @statsMemberSpoken.
  ///
  /// In de, this message translates to:
  /// **'{name}: bezahlt {paid}, verbraucht {consumed}'**
  String statsMemberSpoken(String name, String paid, String consumed);

  /// No description provided for @statsOverTime.
  ///
  /// In de, this message translates to:
  /// **'Letzte 6 Monate'**
  String get statsOverTime;

  /// No description provided for @statsMonthSpoken.
  ///
  /// In de, this message translates to:
  /// **'{month}: {amount}'**
  String statsMonthSpoken(String month, String amount);

  /// No description provided for @statsRides.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get statsRides;

  /// No description provided for @statsKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String statsKm(String km);

  /// No description provided for @statsRideSpoken.
  ///
  /// In de, this message translates to:
  /// **'{month}: {km} Kilometer, {amount}'**
  String statsRideSpoken(String month, String km, String amount);

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

  /// No description provided for @expenseHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf'**
  String get expenseHistory;

  /// No description provided for @expenseHistoryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Änderungen'**
  String get expenseHistoryEmpty;

  /// No description provided for @expenseHistoryRestore.
  ///
  /// In de, this message translates to:
  /// **'Diese Version wiederherstellen'**
  String get expenseHistoryRestore;

  /// No description provided for @expenseHistoryRestored.
  ///
  /// In de, this message translates to:
  /// **'Version wiederhergestellt'**
  String get expenseHistoryRestored;

  /// No description provided for @expenseHistoryNoVisibleChange.
  ///
  /// In de, this message translates to:
  /// **'Keine sichtbare Änderung'**
  String get expenseHistoryNoVisibleChange;

  /// No description provided for @expenseHistoryByAuthor.
  ///
  /// In de, this message translates to:
  /// **'{when} · {name}'**
  String expenseHistoryByAuthor(String when, String name);

  /// No description provided for @expenseHistoryTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel „{from}“ → „{to}“'**
  String expenseHistoryTitle(String from, String to);

  /// No description provided for @expenseHistoryAmount.
  ///
  /// In de, this message translates to:
  /// **'Betrag {from} → {to}'**
  String expenseHistoryAmount(String from, String to);

  /// No description provided for @expenseHistoryRate.
  ///
  /// In de, this message translates to:
  /// **'Kurs {from} → {to}'**
  String expenseHistoryRate(String from, String to);

  /// No description provided for @expenseHistoryDate.
  ///
  /// In de, this message translates to:
  /// **'Datum {from} → {to}'**
  String expenseHistoryDate(String from, String to);

  /// No description provided for @expenseHistoryCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie {from} → {to}'**
  String expenseHistoryCategory(String from, String to);

  /// No description provided for @expenseHistorySplit.
  ///
  /// In de, this message translates to:
  /// **'Aufteilung {from} → {to}'**
  String expenseHistorySplit(String from, String to);

  /// No description provided for @expenseHistoryTrip.
  ///
  /// In de, this message translates to:
  /// **'Reisedaten geändert'**
  String get expenseHistoryTrip;

  /// No description provided for @expenseHistoryPayerAdded.
  ///
  /// In de, this message translates to:
  /// **'{name} hat jetzt mitbezahlt'**
  String expenseHistoryPayerAdded(String name);

  /// No description provided for @expenseHistoryPayerRemoved.
  ///
  /// In de, this message translates to:
  /// **'{name} hat nicht mehr bezahlt'**
  String expenseHistoryPayerRemoved(String name);

  /// No description provided for @expenseHistoryPaid.
  ///
  /// In de, this message translates to:
  /// **'{name} hat {to} statt {from} bezahlt'**
  String expenseHistoryPaid(String name, String from, String to);

  /// No description provided for @expenseHistoryParticipantAdded.
  ///
  /// In de, this message translates to:
  /// **'{name} jetzt beteiligt'**
  String expenseHistoryParticipantAdded(String name);

  /// No description provided for @expenseHistoryParticipantRemoved.
  ///
  /// In de, this message translates to:
  /// **'{name} nicht mehr beteiligt'**
  String expenseHistoryParticipantRemoved(String name);

  /// No description provided for @expenseHistoryShare.
  ///
  /// In de, this message translates to:
  /// **'Anteil von {name}: {from} → {to}'**
  String expenseHistoryShare(String name, String from, String to);

  /// No description provided for @expenseHistoryUnknownMember.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get expenseHistoryUnknownMember;

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

  /// No description provided for @expenseRateSuggestion.
  ///
  /// In de, this message translates to:
  /// **'1 {from} = {rate} {symbol} · EZB, {date}'**
  String expenseRateSuggestion(
    String from,
    String rate,
    String symbol,
    String date,
  );

  /// No description provided for @expenseRateUse.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get expenseRateUse;

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

  /// No description provided for @tripTooFar.
  ///
  /// In de, this message translates to:
  /// **'Das ist weiter, als eine Fahrt sein kann. Maximal {max} km.'**
  String tripTooFar(String max);

  /// No description provided for @tripTooHigh.
  ///
  /// In de, this message translates to:
  /// **'Das ist unwahrscheinlich hoch. Maximal {max}.'**
  String tripTooHigh(String max);

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

  /// No description provided for @vehicleCatalogEngine.
  ///
  /// In de, this message translates to:
  /// **'{litres} l'**
  String vehicleCatalogEngine(String litres);

  /// No description provided for @vehicleCatalogPower.
  ///
  /// In de, this message translates to:
  /// **'{kw} kW'**
  String vehicleCatalogPower(int kw);

  /// No description provided for @vehicleCatalogHybrid.
  ///
  /// In de, this message translates to:
  /// **'{fuel}-Hybrid'**
  String vehicleCatalogHybrid(String fuel);

  /// No description provided for @vehicleCatalogConsumptionLitre.
  ///
  /// In de, this message translates to:
  /// **'{value} l/100 km'**
  String vehicleCatalogConsumptionLitre(String value);

  /// No description provided for @vehicleCatalogConsumptionKwh.
  ///
  /// In de, this message translates to:
  /// **'{value} kWh/100 km'**
  String vehicleCatalogConsumptionKwh(String value);

  /// No description provided for @vehicleCatalogSuggestions.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeugvorschläge'**
  String get vehicleCatalogSuggestions;

  /// No description provided for @vehicleCatalogSource.
  ///
  /// In de, this message translates to:
  /// **'Daten: EEA, CC BY 4.0'**
  String get vehicleCatalogSource;

  /// No description provided for @vehicleCatalogNoMatch.
  ///
  /// In de, this message translates to:
  /// **'Nicht dabei? Trag den Verbrauch selbst ein, z. B. aus deinem Bordcomputer.'**
  String get vehicleCatalogNoMatch;

  /// No description provided for @vehicleCatalogUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Fahrzeugliste konnte nicht geladen werden. Trag den Verbrauch selbst ein, z. B. aus deinem Bordcomputer.'**
  String get vehicleCatalogUnavailable;

  /// No description provided for @vehicleCatalogWltpNote.
  ///
  /// In de, this message translates to:
  /// **'Herstellerangabe (WLTP). Im Alltag verbrauchst du meist etwa 20 % mehr.'**
  String get vehicleCatalogWltpNote;

  /// No description provided for @vehicleCatalogWltpNoteElectric.
  ///
  /// In de, this message translates to:
  /// **'Herstellerangabe (WLTP). Im Alltag brauchst du meist etwas mehr.'**
  String get vehicleCatalogWltpNoteElectric;

  /// No description provided for @vehicleCatalogRealisticNote.
  ///
  /// In de, this message translates to:
  /// **'Geschätzter Alltagswert: Herstellerangabe (WLTP) plus etwa 20 %. Das ist eine Schätzung, kein offizieller Wert.'**
  String get vehicleCatalogRealisticNote;

  /// No description provided for @vehicleCatalogUseRealistic.
  ///
  /// In de, this message translates to:
  /// **'Realistischen Wert übernehmen: {value} l/100 km'**
  String vehicleCatalogUseRealistic(String value);

  /// No description provided for @vehicleCatalogPicked.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ übernommen. Dein Verbrauch wurde ersetzt.'**
  String vehicleCatalogPicked(String name);

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
  /// **'Die Fahrten zählen schon im Saldo. Beim Abrechnen werden sie gesperrt und pro Fahrer zu einer Ausgabe. Du kannst das gleich rückgängig machen.'**
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

  /// No description provided for @ridesDriversTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer fährt?'**
  String get ridesDriversTitle;

  /// No description provided for @ridesDriversHelp.
  ///
  /// In de, this message translates to:
  /// **'Nur Fahrer werden als Nächstes vorgeschlagen.'**
  String get ridesDriversHelp;

  /// No description provided for @ridesDriverSwitch.
  ///
  /// In de, this message translates to:
  /// **'Fährt selbst'**
  String get ridesDriverSwitch;

  /// No description provided for @ridesDriverNowDrives.
  ///
  /// In de, this message translates to:
  /// **'{name} wird wieder vorgeschlagen'**
  String ridesDriverNowDrives(String name);

  /// No description provided for @ridesDriverNotSuggested.
  ///
  /// In de, this message translates to:
  /// **'{name} wird nicht mehr vorgeschlagen'**
  String ridesDriverNotSuggested(String name);

  /// No description provided for @ridesFairnessNotDriving.
  ///
  /// In de, this message translates to:
  /// **'Fährt nicht · wird nicht vorgeschlagen'**
  String get ridesFairnessNotDriving;

  /// No description provided for @ridesFairnessChangeDrivers.
  ///
  /// In de, this message translates to:
  /// **'Fahrer ändern'**
  String get ridesFairnessChangeDrivers;

  /// No description provided for @ridesFairnessHow.
  ///
  /// In de, this message translates to:
  /// **'Wie wird das berechnet?'**
  String get ridesFairnessHow;

  /// No description provided for @ridesFairnessHowText.
  ///
  /// In de, this message translates to:
  /// **'Vorgeschlagen wird, wer bisher am wenigsten gefahren ist – km gefahren minus km mitgefahren seit der letzten Abrechnung. Bei Gleichstand ist dran, wer am längsten nicht gefahren ist. Nur Mitglieder, die als Fahrer markiert sind, werden vorgeschlagen.'**
  String get ridesFairnessHowText;

  /// No description provided for @ridesDriverPromptTitle.
  ///
  /// In de, this message translates to:
  /// **'Fährt {name} nicht selbst?'**
  String ridesDriverPromptTitle(String name);

  /// No description provided for @ridesDriverPromptBody.
  ///
  /// In de, this message translates to:
  /// **'{name} ist bei {n} Fahrten mitgefahren, aber noch nie gefahren. Als Nichtfahrer wird {name} nicht mehr als Nächstes vorgeschlagen.'**
  String ridesDriverPromptBody(String name, int n);

  /// No description provided for @ridesDriverPromptMark.
  ///
  /// In de, this message translates to:
  /// **'Als Nichtfahrer markieren'**
  String get ridesDriverPromptMark;

  /// No description provided for @ridesDriverPromptKeep.
  ///
  /// In de, this message translates to:
  /// **'{name} fährt auch'**
  String ridesDriverPromptKeep(String name);

  /// No description provided for @ridesDriverPromptManage.
  ///
  /// In de, this message translates to:
  /// **'Fahrer verwalten'**
  String get ridesDriverPromptManage;

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
  /// **'Fahrt {distance} km: {total} gesamt\nJede Person zahlt {amount} an {name}'**
  String tripShareText(
    String distance,
    String total,
    String amount,
    String name,
  );

  /// No description provided for @balancesEmptyAction.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe eintragen'**
  String get balancesEmptyAction;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @privacySection.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get privacySection;

  /// No description provided for @privacySummary.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten bleiben auf diesem Gerät. Nur für Spritpreise und Wechselkurse fragt die App unseren Server; Standort nur, wenn du \"In meiner Nähe\" antippst. Absturzberichte sind aus, bis du sie einschaltest.'**
  String get privacySummary;

  /// No description provided for @privacyPolicyEntry.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get privacyPolicyEntry;

  /// No description provided for @imprintEntry.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get imprintEntry;

  /// No description provided for @crashReportsLabel.
  ///
  /// In de, this message translates to:
  /// **'Absturzberichte senden'**
  String get crashReportsLabel;

  /// No description provided for @crashReportsHint.
  ///
  /// In de, this message translates to:
  /// **'Nur bei einem Absturz: technische Fehlerdaten ohne Namen, Beträge, Notizen oder IBAN. Standardmäßig aus.'**
  String get crashReportsHint;

  /// No description provided for @crashReportsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'In dieser Version nicht verfügbar.'**
  String get crashReportsUnavailable;

  /// No description provided for @deleteMyDataEntry.
  ///
  /// In de, this message translates to:
  /// **'Alle meine Daten löschen'**
  String get deleteMyDataEntry;

  /// No description provided for @deleteMyDataEntryHint.
  ///
  /// In de, this message translates to:
  /// **'Gruppen, Ausgaben und Fahrten von diesem Gerät entfernen'**
  String get deleteMyDataEntryHint;

  /// No description provided for @licensesEntry.
  ///
  /// In de, this message translates to:
  /// **'Quellen und Lizenzen'**
  String get licensesEntry;

  /// No description provided for @licensesEntryHint.
  ///
  /// In de, this message translates to:
  /// **'Daten und Schriften, die mitlio nutzt'**
  String get licensesEntryHint;

  /// No description provided for @creditLead.
  ///
  /// In de, this message translates to:
  /// **'Mit'**
  String get creditLead;

  /// No description provided for @creditMid.
  ///
  /// In de, this message translates to:
  /// **'gemacht von'**
  String get creditMid;

  /// No description provided for @creditName.
  ///
  /// In de, this message translates to:
  /// **'Michael Albrecht'**
  String get creditName;

  /// No description provided for @creditOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Link ließ sich nicht öffnen. Wir haben ihn kopiert, du kannst ihn in deinen Browser einfügen.'**
  String get creditOpenFailed;

  /// No description provided for @licensesTitle.
  ///
  /// In de, this message translates to:
  /// **'Quellen und Lizenzen'**
  String get licensesTitle;

  /// No description provided for @licensesEeaTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeugliste'**
  String get licensesEeaTitle;

  /// No description provided for @licensesEea.
  ///
  /// In de, this message translates to:
  /// **'Daten: Europäische Umweltagentur (EEA), Überwachung der CO2-Emissionen von neuen Pkw (Verordnung (EU) 2019/631), CC BY 4.0. Die Werte sind Herstellerangaben (WLTP). mitlio hat sie nur zusammengefasst und nicht verändert.'**
  String get licensesEea;

  /// No description provided for @licensesFontTitle.
  ///
  /// In de, this message translates to:
  /// **'Schrift im PDF'**
  String get licensesFontTitle;

  /// No description provided for @licensesFont.
  ///
  /// In de, this message translates to:
  /// **'Roboto, Apache License 2.0.'**
  String get licensesFont;

  /// No description provided for @deleteMyDataTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle meine Daten löschen'**
  String get deleteMyDataTitle;

  /// No description provided for @deleteMyDataWhatTitle.
  ///
  /// In de, this message translates to:
  /// **'Das wird gelöscht'**
  String get deleteMyDataWhatTitle;

  /// No description provided for @deleteMyDataWhat.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät: alle Gruppen, Mitglieder, Ausgaben, Fahrten, Ausgleiche, Zahlungsdaten (auch IBAN und der zugehörige Schlüssel) und deine Einstellungen. Danach startet die App wie neu.'**
  String get deleteMyDataWhat;

  /// No description provided for @deleteMyDataServer.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Server: deine Verknüpfungen mit Gruppen und dein Konto, falls du eins hast.'**
  String get deleteMyDataServer;

  /// No description provided for @deleteMyDataStaysTitle.
  ///
  /// In de, this message translates to:
  /// **'Das bleibt'**
  String get deleteMyDataStaysTitle;

  /// No description provided for @deleteMyDataStays.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Gruppendaten, die andere Mitglieder auf ihren Geräten haben, bleiben bei ihnen erhalten. Sie gehören der Gruppe, nicht dir allein.'**
  String get deleteMyDataStays;

  /// No description provided for @deleteMyDataIrreversible.
  ///
  /// In de, this message translates to:
  /// **'Das lässt sich nicht rückgängig machen.'**
  String get deleteMyDataIrreversible;

  /// No description provided for @deleteMyDataConfirmWord.
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get deleteMyDataConfirmWord;

  /// No description provided for @deleteMyDataConfirmLabel.
  ///
  /// In de, this message translates to:
  /// **'Zur Bestätigung LÖSCHEN eintippen'**
  String get deleteMyDataConfirmLabel;

  /// No description provided for @deleteMyDataAction.
  ///
  /// In de, this message translates to:
  /// **'Alles endgültig löschen'**
  String get deleteMyDataAction;

  /// No description provided for @deleteMyDataFailed.
  ///
  /// In de, this message translates to:
  /// **'Löschen hat nicht geklappt. Es wurde nichts gelöscht. Bitte versuche es noch einmal.'**
  String get deleteMyDataFailed;

  /// No description provided for @fuelChipsLabel.
  ///
  /// In de, this message translates to:
  /// **'Spritpreis übernehmen'**
  String get fuelChipsLabel;

  /// No description provided for @fuelGradeE5.
  ///
  /// In de, this message translates to:
  /// **'E5'**
  String get fuelGradeE5;

  /// No description provided for @fuelGradeE10.
  ///
  /// In de, this message translates to:
  /// **'E10'**
  String get fuelGradeE10;

  /// No description provided for @fuelGradeDiesel.
  ///
  /// In de, this message translates to:
  /// **'Diesel'**
  String get fuelGradeDiesel;

  /// No description provided for @fuelScopeNational.
  ///
  /// In de, this message translates to:
  /// **'Ø Deutschland'**
  String get fuelScopeNational;

  /// No description provided for @fuelScopePlz.
  ///
  /// In de, this message translates to:
  /// **'Ø PLZ {plz}'**
  String fuelScopePlz(String plz);

  /// No description provided for @fuelScopeNearby.
  ///
  /// In de, this message translates to:
  /// **'Ø in deiner Nähe'**
  String get fuelScopeNearby;

  /// No description provided for @fuelAgeNow.
  ///
  /// In de, this message translates to:
  /// **'gerade eben'**
  String get fuelAgeNow;

  /// No description provided for @fuelAgeMinutes.
  ///
  /// In de, this message translates to:
  /// **'vor {count} min'**
  String fuelAgeMinutes(int count);

  /// No description provided for @fuelAgeHours.
  ///
  /// In de, this message translates to:
  /// **'vor {count} Std.'**
  String fuelAgeHours(int count);

  /// No description provided for @fuelAgeDays.
  ///
  /// In de, this message translates to:
  /// **'vor {count} Tagen'**
  String fuelAgeDays(int count);

  /// No description provided for @fuelAgeSince.
  ///
  /// In de, this message translates to:
  /// **'Stand {date}'**
  String fuelAgeSince(String date);

  /// No description provided for @fuelOfflineNote.
  ///
  /// In de, this message translates to:
  /// **'offline, zuletzt bekannt'**
  String get fuelOfflineNote;

  /// No description provided for @fuelStaleRateLimited.
  ///
  /// In de, this message translates to:
  /// **'zu viele Anfragen, zuletzt bekannt'**
  String get fuelStaleRateLimited;

  /// No description provided for @fuelStaleRateLimitedIn.
  ///
  /// In de, this message translates to:
  /// **'zu viele Anfragen, in {minutes} Min. nochmal, zuletzt bekannt'**
  String fuelStaleRateLimitedIn(int minutes);

  /// No description provided for @fuelStaleServer.
  ///
  /// In de, this message translates to:
  /// **'Preisdienst nicht erreichbar, zuletzt bekannt'**
  String get fuelStaleServer;

  /// No description provided for @fuelRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Preisabfragen – versuch es in ein paar Minuten nochmal.'**
  String get fuelRateLimited;

  /// No description provided for @fuelRateLimitedIn.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Preisabfragen – versuch es in {minutes} Min. nochmal.'**
  String fuelRateLimitedIn(int minutes);

  /// No description provided for @fuelOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Prüf dein Netz oder trag den Preis selbst ein.'**
  String get fuelOffline;

  /// No description provided for @fuelServerDown.
  ///
  /// In de, this message translates to:
  /// **'Preisdienst gerade nicht erreichbar. Versuch es später nochmal oder trag den Preis selbst ein.'**
  String get fuelServerDown;

  /// No description provided for @fuelAreasUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Postleitzahl und „In meiner Nähe“ gibt es auf diesem Server nicht. Es gilt der Bundesdurchschnitt, den Preis kannst du auch selbst eintragen.'**
  String get fuelAreasUnavailable;

  /// No description provided for @fuelNoPrice.
  ///
  /// In de, this message translates to:
  /// **'Gerade kein aktueller Preis verfügbar. Trag ihn einfach selbst ein.'**
  String get fuelNoPrice;

  /// No description provided for @fuelNearby.
  ///
  /// In de, this message translates to:
  /// **'In meiner Nähe'**
  String get fuelNearby;

  /// No description provided for @fuelNearbyDenied.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht freigegeben, es gilt der Bundesdurchschnitt.'**
  String get fuelNearbyDenied;

  /// No description provided for @fuelNearbyBlocked.
  ///
  /// In de, this message translates to:
  /// **'Standort ist in den Einstellungen gesperrt, es gilt der Bundesdurchschnitt.'**
  String get fuelNearbyBlocked;

  /// No description provided for @fuelNearbyUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Standort gerade nicht verfügbar.'**
  String get fuelNearbyUnavailable;

  /// No description provided for @fuelPlzAction.
  ///
  /// In de, this message translates to:
  /// **'PLZ eingeben'**
  String get fuelPlzAction;

  /// No description provided for @fuelPlzLabel.
  ///
  /// In de, this message translates to:
  /// **'Postleitzahl'**
  String get fuelPlzLabel;

  /// No description provided for @fuelPlzInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte fünf Ziffern'**
  String get fuelPlzInvalid;

  /// No description provided for @fuelPlzApply.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get fuelPlzApply;

  /// No description provided for @fuelNationalAction.
  ///
  /// In de, this message translates to:
  /// **'Bundesweit'**
  String get fuelNationalAction;

  /// No description provided for @fuelAttributionFallback.
  ///
  /// In de, this message translates to:
  /// **'Spritpreisdaten'**
  String get fuelAttributionFallback;

  /// No description provided for @routeToggle.
  ///
  /// In de, this message translates to:
  /// **'Start und Ziel eingeben, Strecke berechnen'**
  String get routeToggle;

  /// No description provided for @routeStartLabel.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get routeStartLabel;

  /// No description provided for @routeEndLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get routeEndLabel;

  /// No description provided for @routeResult.
  ///
  /// In de, this message translates to:
  /// **'{km} km, Strecke über die Straße'**
  String routeResult(String km);

  /// No description provided for @routeRecalculate.
  ///
  /// In de, this message translates to:
  /// **'Neu berechnen'**
  String get routeRecalculate;

  /// No description provided for @routeSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche läuft …'**
  String get routeSearching;

  /// No description provided for @routeCalculating.
  ///
  /// In de, this message translates to:
  /// **'Strecke wird berechnet …'**
  String get routeCalculating;

  /// No description provided for @routeNoMatches.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer. Probier einen anderen Ort oder trag die Kilometer selbst ein.'**
  String get routeNoMatches;

  /// No description provided for @routeSavedHome.
  ///
  /// In de, this message translates to:
  /// **'Zuhause'**
  String get routeSavedHome;

  /// No description provided for @routeSavedWork.
  ///
  /// In de, this message translates to:
  /// **'Arbeit'**
  String get routeSavedWork;

  /// No description provided for @routeSaveAsHome.
  ///
  /// In de, this message translates to:
  /// **'Als Zuhause merken'**
  String get routeSaveAsHome;

  /// No description provided for @routeSaveAsWork.
  ///
  /// In de, this message translates to:
  /// **'Als Arbeit merken'**
  String get routeSaveAsWork;

  /// No description provided for @routeSavedAsHome.
  ///
  /// In de, this message translates to:
  /// **'Als Zuhause gemerkt'**
  String get routeSavedAsHome;

  /// No description provided for @routeSavedAsWork.
  ///
  /// In de, this message translates to:
  /// **'Als Arbeit gemerkt'**
  String get routeSavedAsWork;

  /// No description provided for @routeOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung, trag die Kilometer einfach selbst ein.'**
  String get routeOffline;

  /// No description provided for @routeRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Streckenanfragen. Versuch es später nochmal oder trag die Kilometer selbst ein.'**
  String get routeRateLimited;

  /// No description provided for @routeRateLimitedIn.
  ///
  /// In de, this message translates to:
  /// **'Zu viele Streckenanfragen. Versuch es in {minutes} Min. nochmal oder trag die Kilometer selbst ein.'**
  String routeRateLimitedIn(int minutes);

  /// No description provided for @routeNoRoute.
  ///
  /// In de, this message translates to:
  /// **'Zwischen diesen Orten gibt es keine Straßenverbindung. Prüf Start und Ziel oder trag die Kilometer selbst ein.'**
  String get routeNoRoute;

  /// No description provided for @routeServerDown.
  ///
  /// In de, this message translates to:
  /// **'Der Routendienst ist gerade nicht erreichbar. Versuch es später nochmal oder trag die Kilometer selbst ein.'**
  String get routeServerDown;

  /// No description provided for @routeUnconfigured.
  ///
  /// In de, this message translates to:
  /// **'Die Streckenberechnung gibt es auf diesem Server nicht. Trag die Kilometer einfach selbst ein.'**
  String get routeUnconfigured;

  /// No description provided for @routeInvalid.
  ///
  /// In de, this message translates to:
  /// **'Start und Ziel passen nicht zusammen. Wähl zwei verschiedene Orte oder trag die Kilometer selbst ein.'**
  String get routeInvalid;

  /// No description provided for @routeAttributionFallback.
  ///
  /// In de, this message translates to:
  /// **'Karten- und Routendaten © OpenStreetMap-Mitwirkende'**
  String get routeAttributionFallback;

  /// No description provided for @shareUploadPartial.
  ///
  /// In de, this message translates to:
  /// **'{uploaded} von {total} {total, plural, =1{Eintrag} other{Einträgen}} hochgeladen. Auf diesem Handy ist alles unverändert. Wir versuchen es weiter.'**
  String shareUploadPartial(int uploaded, int total);

  /// No description provided for @shareGroupMissing.
  ///
  /// In de, this message translates to:
  /// **'Diese Gruppe gibt es auf diesem Handy nicht mehr. Lade die Gruppenliste neu.'**
  String get shareGroupMissing;

  /// No description provided for @syncStatusUpToDate.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get syncStatusUpToDate;

  /// No description provided for @syncStatusSending.
  ///
  /// In de, this message translates to:
  /// **'Wird gesendet …'**
  String get syncStatusSending;

  /// No description provided for @syncStatusPending.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Änderung wartet} other{{count} Änderungen warten}}'**
  String syncStatusPending(int count);

  /// No description provided for @syncRejectedLine.
  ///
  /// In de, this message translates to:
  /// **'Eine Änderung konnte nicht geteilt werden.'**
  String get syncRejectedLine;

  /// No description provided for @syncRejectedShow.
  ///
  /// In de, this message translates to:
  /// **'Ansehen'**
  String get syncRejectedShow;

  /// No description provided for @syncRejectedSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Nicht geteilt'**
  String get syncRejectedSheetTitle;

  /// No description provided for @syncRejectedOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get syncRejectedOk;

  /// No description provided for @syncUpdateAction.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get syncUpdateAction;

  /// No description provided for @syncUpdateOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Store lässt sich nicht öffnen. Öffne ihn selbst und aktualisiere mitlio.'**
  String get syncUpdateOpenFailed;

  /// No description provided for @syncStatusUploading.
  ///
  /// In de, this message translates to:
  /// **'Wird hochgeladen …'**
  String get syncStatusUploading;

  /// No description provided for @syncStatusUploadingLeft.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Wird hochgeladen … noch 1 Eintrag} other{Wird hochgeladen … noch {count} Einträge}}'**
  String syncStatusUploadingLeft(int count);

  /// No description provided for @shareMenu.
  ///
  /// In de, this message translates to:
  /// **'Gruppe teilen'**
  String get shareMenu;

  /// No description provided for @shareSheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Gruppe teilen'**
  String get shareSheetTitle;

  /// No description provided for @sharePreparing.
  ///
  /// In de, this message translates to:
  /// **'Link wird vorbereitet …'**
  String get sharePreparing;

  /// No description provided for @shareLinkButton.
  ///
  /// In de, this message translates to:
  /// **'Link teilen'**
  String get shareLinkButton;

  /// No description provided for @shareQrLabel.
  ///
  /// In de, this message translates to:
  /// **'QR-Code zum Beitreten der Gruppe {name}'**
  String shareQrLabel(String name);

  /// No description provided for @inviteShareText.
  ///
  /// In de, this message translates to:
  /// **'Komm in die Gruppe {name} bei mitlio: {link}'**
  String inviteShareText(String name, String link);

  /// No description provided for @inviteRotate.
  ///
  /// In de, this message translates to:
  /// **'Neuen Link erstellen'**
  String get inviteRotate;

  /// No description provided for @inviteRotateWarning.
  ///
  /// In de, this message translates to:
  /// **'Der alte Link funktioniert dann nicht mehr.'**
  String get inviteRotateWarning;

  /// No description provided for @inviteRotateCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get inviteRotateCancel;

  /// No description provided for @inviteLinkRotated.
  ///
  /// In de, this message translates to:
  /// **'Dieser Link gilt nicht mehr. Frag, wer die Gruppe erstellt hat, nach dem neuen.'**
  String get inviteLinkRotated;

  /// No description provided for @inviteNoLinkMember.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Handy ist kein Link gespeichert. Frag, wer die Gruppe erstellt hat, nach dem Link.'**
  String get inviteNoLinkMember;

  /// No description provided for @inviteStoreUnreadable.
  ///
  /// In de, this message translates to:
  /// **'Der gespeicherte Link ließ sich nicht lesen. Starte mitlio neu und versuch es nochmal.'**
  String get inviteStoreUnreadable;

  /// No description provided for @inviteNotSaved.
  ///
  /// In de, this message translates to:
  /// **'Der Link konnte auf diesem Handy nicht gespeichert werden. Teile ihn jetzt, später brauchst du einen neuen Link.'**
  String get inviteNotSaved;

  /// No description provided for @joinTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer bist du?'**
  String get joinTitle;

  /// No description provided for @joinJoining.
  ///
  /// In de, this message translates to:
  /// **'Du trittst der Gruppe bei …'**
  String get joinJoining;

  /// No description provided for @joinConnected.
  ///
  /// In de, this message translates to:
  /// **'verbunden'**
  String get joinConnected;

  /// No description provided for @joinNewHere.
  ///
  /// In de, this message translates to:
  /// **'Ich bin neu hier'**
  String get joinNewHere;

  /// No description provided for @joinNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get joinNameLabel;

  /// No description provided for @joinNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt du? Trag deinen Namen ein.'**
  String get joinNameRequired;

  /// No description provided for @joinNameConfirm.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get joinNameConfirm;

  /// No description provided for @joinSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get joinSkip;

  /// No description provided for @joinConnecting.
  ///
  /// In de, this message translates to:
  /// **'Einen Moment …'**
  String get joinConnecting;

  /// No description provided for @joinOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Du bist der Gruppe noch nicht beigetreten und auf diesem Handy wurde nichts angelegt. Verbinde dich mit dem Internet und öffne den Link nochmal.'**
  String get joinOffline;

  /// No description provided for @joinLocalFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Gruppe konnte auf diesem Handy nicht gespeichert werden. Prüfe den freien Speicher und öffne den Link nochmal.'**
  String get joinLocalFailed;

  /// No description provided for @joinOpenGroup.
  ///
  /// In de, this message translates to:
  /// **'Zur Gruppe'**
  String get joinOpenGroup;

  /// No description provided for @joinClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get joinClose;

  /// No description provided for @joinConnectOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung. Du bist in der Gruppe, aber noch mit niemandem verbunden. Versuch es nochmal, sobald du online bist.'**
  String get joinConnectOffline;

  /// No description provided for @setupStepProgress.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String setupStepProgress(int current, int total);

  /// No description provided for @setupNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get setupNext;

  /// No description provided for @setupSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get setupSkip;

  /// No description provided for @setupBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get setupBack;

  /// No description provided for @setupYes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get setupYes;

  /// No description provided for @setupNo.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get setupNo;

  /// No description provided for @setupFinishDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get setupFinishDone;

  /// No description provided for @setupCelebration.
  ///
  /// In de, this message translates to:
  /// **'Geschafft'**
  String get setupCelebration;

  /// No description provided for @carsEntry.
  ///
  /// In de, this message translates to:
  /// **'Meine Autos'**
  String get carsEntry;

  /// No description provided for @carsEntryHint.
  ///
  /// In de, this message translates to:
  /// **'Deine Autos und was ein Kilometer kostet'**
  String get carsEntryHint;

  /// No description provided for @carsTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Autos'**
  String get carsTitle;

  /// No description provided for @carsEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Auto'**
  String get carsEmptyTitle;

  /// No description provided for @carsEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Richte dein Auto einmal ein, dann siehst du, was jeder Kilometer kostet.'**
  String get carsEmptyMessage;

  /// No description provided for @carsAdd.
  ///
  /// In de, this message translates to:
  /// **'Auto hinzufügen'**
  String get carsAdd;

  /// No description provided for @carsAnother.
  ///
  /// In de, this message translates to:
  /// **'Noch ein Auto?'**
  String get carsAnother;

  /// No description provided for @carRemoved.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernt'**
  String carRemoved(String name);

  /// No description provided for @carRemoveLabel.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen'**
  String carRemoveLabel(String name);

  /// No description provided for @carRowSubtitle.
  ///
  /// In de, this message translates to:
  /// **'{fuel}, {consumption}'**
  String carRowSubtitle(String fuel, String consumption);

  /// No description provided for @carFuelPetrol.
  ///
  /// In de, this message translates to:
  /// **'Benzin'**
  String get carFuelPetrol;

  /// No description provided for @carFuelDiesel.
  ///
  /// In de, this message translates to:
  /// **'Diesel'**
  String get carFuelDiesel;

  /// No description provided for @carFuelElectric.
  ///
  /// In de, this message translates to:
  /// **'Strom'**
  String get carFuelElectric;

  /// No description provided for @carFuelOther.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get carFuelOther;

  /// No description provided for @carUnitLitres.
  ///
  /// In de, this message translates to:
  /// **'l/100 km'**
  String get carUnitLitres;

  /// No description provided for @carUnitKwh.
  ///
  /// In de, this message translates to:
  /// **'kWh/100 km'**
  String get carUnitKwh;

  /// No description provided for @carHasCarTitle.
  ///
  /// In de, this message translates to:
  /// **'Hast du ein Auto?'**
  String get carHasCarTitle;

  /// No description provided for @carNameTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt dein Auto?'**
  String get carNameTitle;

  /// No description provided for @carNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name, z. B. Golf'**
  String get carNameLabel;

  /// No description provided for @carTypeSmall.
  ///
  /// In de, this message translates to:
  /// **'Kleinwagen'**
  String get carTypeSmall;

  /// No description provided for @carTypeCompact.
  ///
  /// In de, this message translates to:
  /// **'Kompakt'**
  String get carTypeCompact;

  /// No description provided for @carTypeSuv.
  ///
  /// In de, this message translates to:
  /// **'SUV'**
  String get carTypeSuv;

  /// No description provided for @carTypeVan.
  ///
  /// In de, this message translates to:
  /// **'Van'**
  String get carTypeVan;

  /// No description provided for @carFuelTitle.
  ///
  /// In de, this message translates to:
  /// **'Womit fährt es?'**
  String get carFuelTitle;

  /// No description provided for @carConsumptionTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viel verbraucht es?'**
  String get carConsumptionTitle;

  /// No description provided for @carConsumptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch'**
  String get carConsumptionLabel;

  /// No description provided for @carConsumptionDontKnow.
  ///
  /// In de, this message translates to:
  /// **'Weiß ich nicht'**
  String get carConsumptionDontKnow;

  /// No description provided for @carConsumptionTypical.
  ///
  /// In de, this message translates to:
  /// **'Typisch für dein Auto: {value} {unit}'**
  String carConsumptionTypical(String value, String unit);

  /// No description provided for @carConsumptionInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib eine Zahl wie 6,5 ein.'**
  String get carConsumptionInvalid;

  /// No description provided for @carExtraTitle.
  ///
  /// In de, this message translates to:
  /// **'Was kostet dich ein Kilometer noch?'**
  String get carExtraTitle;

  /// No description provided for @carExtraFlat.
  ///
  /// In de, this message translates to:
  /// **'Pauschale (≈ {value} ct/km)'**
  String carExtraFlat(String value);

  /// No description provided for @carExtraFlatHint.
  ///
  /// In de, this message translates to:
  /// **'Schnell: nur ein Zuschlag für Verschleiß'**
  String get carExtraFlatHint;

  /// No description provided for @carExtraExact.
  ///
  /// In de, this message translates to:
  /// **'Genau ausrechnen (2 Min.)'**
  String get carExtraExact;

  /// No description provided for @carExtraExactHint.
  ///
  /// In de, this message translates to:
  /// **'Versicherung, Steuer, Reparaturen und mehr einmal eintragen'**
  String get carExtraExactHint;

  /// No description provided for @carPerKm.
  ///
  /// In de, this message translates to:
  /// **'≈ {value} ct/km'**
  String carPerKm(String value);

  /// No description provided for @carFinishTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Auto kostet ≈ {value} ct/km'**
  String carFinishTitle(String value);

  /// No description provided for @carSummaryCar.
  ///
  /// In de, this message translates to:
  /// **'{name}, {fuel}'**
  String carSummaryCar(String name, String fuel);

  /// No description provided for @carSummaryConsumption.
  ///
  /// In de, this message translates to:
  /// **'Verbrauch: {value} {unit}'**
  String carSummaryConsumption(String value, String unit);

  /// No description provided for @carSummaryExtraFlat.
  ///
  /// In de, this message translates to:
  /// **'Pauschale: {value} ct/km'**
  String carSummaryExtraFlat(String value);

  /// No description provided for @carSummaryExtraExact.
  ///
  /// In de, this message translates to:
  /// **'Eigene Kosten: {value} ct/km'**
  String carSummaryExtraExact(String value);

  /// No description provided for @carSave.
  ///
  /// In de, this message translates to:
  /// **'Auto speichern'**
  String get carSave;

  /// No description provided for @carChartLabel.
  ///
  /// In de, this message translates to:
  /// **'Kosten pro Kilometer nach Art'**
  String get carChartLabel;

  /// No description provided for @carPartValue.
  ///
  /// In de, this message translates to:
  /// **'{label}: {value} ct/km'**
  String carPartValue(String label, String value);

  /// No description provided for @carPartFuel.
  ///
  /// In de, this message translates to:
  /// **'Kraftstoff'**
  String get carPartFuel;

  /// No description provided for @carPartFlat.
  ///
  /// In de, this message translates to:
  /// **'Pauschale'**
  String get carPartFlat;

  /// No description provided for @carPartInsurance.
  ///
  /// In de, this message translates to:
  /// **'Versicherung'**
  String get carPartInsurance;

  /// No description provided for @carPartVehicleTax.
  ///
  /// In de, this message translates to:
  /// **'Kfz-Steuer'**
  String get carPartVehicleTax;

  /// No description provided for @carPartMaintenance.
  ///
  /// In de, this message translates to:
  /// **'Wartung und TÜV'**
  String get carPartMaintenance;

  /// No description provided for @carPartTyres.
  ///
  /// In de, this message translates to:
  /// **'Reifen'**
  String get carPartTyres;

  /// No description provided for @carPartRepairs.
  ///
  /// In de, this message translates to:
  /// **'Reparaturen'**
  String get carPartRepairs;

  /// No description provided for @carPartLoan.
  ///
  /// In de, this message translates to:
  /// **'Kredit oder Leasing'**
  String get carPartLoan;

  /// No description provided for @carPartDepreciation.
  ///
  /// In de, this message translates to:
  /// **'Wertverlust'**
  String get carPartDepreciation;

  /// No description provided for @carPartParking.
  ///
  /// In de, this message translates to:
  /// **'Parken'**
  String get carPartParking;

  /// No description provided for @carPartOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get carPartOther;

  /// No description provided for @carCostKmTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viele Kilometer fährst du im Jahr?'**
  String get carCostKmTitle;

  /// No description provided for @carCostKmLabel.
  ///
  /// In de, this message translates to:
  /// **'Kilometer pro Jahr'**
  String get carCostKmLabel;

  /// No description provided for @carCostKmInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib ganze Kilometer ein, z. B. 15000.'**
  String get carCostKmInvalid;

  /// No description provided for @carCostKmPreset.
  ///
  /// In de, this message translates to:
  /// **'{count} Tkm'**
  String carCostKmPreset(int count);

  /// No description provided for @carCostAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get carCostAmountLabel;

  /// No description provided for @carCostAmountInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Betrag wie 45 oder 45,50 ein.'**
  String get carCostAmountInvalid;

  /// No description provided for @carCostMonth.
  ///
  /// In de, this message translates to:
  /// **'pro Monat'**
  String get carCostMonth;

  /// No description provided for @carCostYear.
  ///
  /// In de, this message translates to:
  /// **'pro Jahr'**
  String get carCostYear;

  /// No description provided for @carCostInsuranceTitle.
  ///
  /// In de, this message translates to:
  /// **'Was zahlst du für die Versicherung?'**
  String get carCostInsuranceTitle;

  /// No description provided for @carCostTaxTitle.
  ///
  /// In de, this message translates to:
  /// **'Was zahlst du für die Kfz-Steuer?'**
  String get carCostTaxTitle;

  /// No description provided for @carCostMaintenanceTitle.
  ///
  /// In de, this message translates to:
  /// **'Was kosten Wartung und TÜV?'**
  String get carCostMaintenanceTitle;

  /// No description provided for @carCostTyresTitle.
  ///
  /// In de, this message translates to:
  /// **'Was kosten Reifen?'**
  String get carCostTyresTitle;

  /// No description provided for @carCostRepairsTitle.
  ///
  /// In de, this message translates to:
  /// **'Was kosten Reparaturen?'**
  String get carCostRepairsTitle;

  /// No description provided for @carCostLoanTitle.
  ///
  /// In de, this message translates to:
  /// **'Zahlst du Kredit oder Leasing?'**
  String get carCostLoanTitle;

  /// No description provided for @carCostPurchaseTitle.
  ///
  /// In de, this message translates to:
  /// **'Was hat das Auto gekostet?'**
  String get carCostPurchaseTitle;

  /// No description provided for @carCostResaleTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ist es später noch wert?'**
  String get carCostResaleTitle;

  /// No description provided for @carCostYearsTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie viele Jahre behältst du es?'**
  String get carCostYearsTitle;

  /// No description provided for @carCostYearsLabel.
  ///
  /// In de, this message translates to:
  /// **'Jahre'**
  String get carCostYearsLabel;

  /// No description provided for @carCostYearsInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib ganze Jahre ein, z. B. 5.'**
  String get carCostYearsInvalid;

  /// No description provided for @carCostParkingTitle.
  ///
  /// In de, this message translates to:
  /// **'Was kostet das Parken?'**
  String get carCostParkingTitle;

  /// No description provided for @carCostOtherTitle.
  ///
  /// In de, this message translates to:
  /// **'Gibt es sonstige Kosten?'**
  String get carCostOtherTitle;

  /// No description provided for @carCostSoFar.
  ///
  /// In de, this message translates to:
  /// **'Bisher ≈ {value} ct/km extra'**
  String carCostSoFar(String value);

  /// No description provided for @carCostBasisTitle.
  ///
  /// In de, this message translates to:
  /// **'Welche Kosten sollen Mitfahrende teilen?'**
  String get carCostBasisTitle;

  /// No description provided for @carCostBasisRunning.
  ///
  /// In de, this message translates to:
  /// **'Nur laufende Kosten (≈ {value} ct/km)'**
  String carCostBasisRunning(String value);

  /// No description provided for @carCostBasisRunningHint.
  ///
  /// In de, this message translates to:
  /// **'Wartung, Reifen, Reparaturen, Wertverlust. Empfohlen.'**
  String get carCostBasisRunningHint;

  /// No description provided for @carCostBasisFull.
  ///
  /// In de, this message translates to:
  /// **'Alle Kosten (≈ {value} ct/km)'**
  String carCostBasisFull(String value);

  /// No description provided for @carCostBasisFullHint.
  ///
  /// In de, this message translates to:
  /// **'Zusätzlich Versicherung, Steuer, Kredit, Parken.'**
  String get carCostBasisFullHint;

  /// No description provided for @carCostResultTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Auto kostet ≈ {value} ct/km extra'**
  String carCostResultTitle(String value);

  /// No description provided for @carCostResultAccept.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get carCostResultAccept;

  /// No description provided for @carHintOperatingCost.
  ///
  /// In de, this message translates to:
  /// **'Hinweis: Zahlen Mitfahrende zusammen mehr als Kraftstoff und laufende Kosten, kann das rechtlich als gewerbliche Personenbeförderung gelten (PBefG). Keine Rechtsberatung.'**
  String get carHintOperatingCost;

  /// No description provided for @carHintCheck.
  ///
  /// In de, this message translates to:
  /// **'Bitte prüfen: Dieser Wert ist ungewöhnlich hoch. Hast du dich vertippt?'**
  String get carHintCheck;

  /// No description provided for @carNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Gib deinem Auto einen Namen'**
  String get carNameRequired;
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
