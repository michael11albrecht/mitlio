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
