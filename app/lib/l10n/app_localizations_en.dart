// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'mitlio';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorMessage => 'Give it another try in a moment.';

  @override
  String get retry => 'Try again';

  @override
  String get amountInvalid => 'That is not a valid amount';

  @override
  String currencyName(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        'EUR': 'euros',
        'USD': 'US dollars',
        'GBP': 'pounds',
        'CHF': 'Swiss francs',
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
  String get undo => 'Undo';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get groupsEmptyTitle => 'No group yet';

  @override
  String get groupsEmptyMessage => 'Create your first one.';

  @override
  String get groupNew => 'New group';

  @override
  String get groupCreate => 'Create group';

  @override
  String get groupEditTitle => 'Edit group';

  @override
  String get groupNameLabel => 'Name';

  @override
  String get groupNameHint => 'e.g. Weekend trip';

  @override
  String get groupNameRequired => 'Give the group a name';

  @override
  String get groupCurrencyLabel => 'Currency';

  @override
  String get groupCurrencyLocked =>
      'The currency can\'t be changed once there are expenses.';

  @override
  String get groupSave => 'Save';

  @override
  String get groupMenu => 'More';

  @override
  String get groupArchive => 'Archive group';

  @override
  String groupArchived(String name) {
    return '“$name” archived';
  }

  @override
  String get membersEmptyTitle => 'Nobody here yet';

  @override
  String get membersEmptyMessage => 'Add the people you share with.';

  @override
  String get memberAddLabel => 'Add a name';

  @override
  String get memberAdd => 'Add';

  @override
  String get memberNameLabel => 'Name';

  @override
  String get memberRenameSave => 'Save name';

  @override
  String memberRemove(String name) {
    return 'Remove $name';
  }

  @override
  String memberRemoved(String name) {
    return '“$name” removed';
  }

  @override
  String get memberOrderHint =>
      'Drag to reorder. When a split leaves spare cents, people higher up pay the extra cent first.';

  @override
  String memberInUse(String name) {
    return '$name has expenses or payments, so they stay in the group.';
  }

  @override
  String get balancesTitle => 'Balances';

  @override
  String get balancesOpen => 'Who gets what';

  @override
  String balanceGets(String name) {
    return '$name gets';
  }

  @override
  String balanceOwes(String name) {
    return '$name owes';
  }

  @override
  String balanceEven(String name) {
    return '$name is all square';
  }

  @override
  String get balancesSettledTitle => 'All square';

  @override
  String get balancesSettledMessage => 'Nobody owes anybody anything.';

  @override
  String get balancesEmptyTitle => 'Nothing to settle yet';

  @override
  String get balancesEmptyMessage =>
      'Once there are expenses, you will see here who owes whom.';

  @override
  String get balancesTransfersTitle => 'Who pays whom';

  @override
  String get balancesModeSimplified => 'Simple';

  @override
  String get balancesModeDirect => 'Direct';

  @override
  String get balancesModeSimplifiedHint => 'As few payments as possible.';

  @override
  String get balancesModeDirectHint =>
      'Every debt on its own, between the people involved.';

  @override
  String balancesTransfer(String from, String to) {
    return '$from pays $to';
  }

  @override
  String get tripAdd => 'Add a trip';

  @override
  String get tripFormTitle => 'Trip';

  @override
  String get tripDefaultTitle => 'Trip';

  @override
  String get tripResultCaption => 'Everyone pays';

  @override
  String get tripResultCaptionRounded => 'Everyone pays about';

  @override
  String tripResultDriverGets(String name, String amount) {
    return '$name gets $amount';
  }

  @override
  String get tripHintFuel =>
      'Enter distance, consumption and price. You see the result right away.';

  @override
  String get tripHintKmRate =>
      'Enter distance and km rate. You see the result right away.';

  @override
  String get tripNoParticipants => 'Pick at least one person who rides along.';

  @override
  String get tripTooLarge =>
      'That is too large to calculate. Check the numbers.';

  @override
  String get tripNumberInvalid => 'That is not a valid number';

  @override
  String get tripDistanceLabel => 'Distance (one way)';

  @override
  String get tripUnitKm => 'km';

  @override
  String get tripRoundTrip => 'Round trip';

  @override
  String get tripEnergyFuel => 'Petrol / diesel';

  @override
  String get tripEnergyElectric => 'Electric';

  @override
  String get tripConsumptionLabel => 'Consumption';

  @override
  String get tripUnitLitersPer100 => 'l/100 km';

  @override
  String get tripUnitKwhPer100 => 'kWh/100 km';

  @override
  String get tripPriceFuelLabel => 'Price per litre';

  @override
  String get tripPriceElectricLabel => 'Price per kWh';

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
  String get tripWearLabel => 'Wear and tear (optional)';

  @override
  String get tripKmRateToggle => 'Flat rate per km';

  @override
  String get tripKmRateHint => 'Replaces fuel and wear';

  @override
  String get tripKmRateLabel => 'Rate per km';

  @override
  String get tripTollsLabel => 'Tolls (optional)';

  @override
  String get tripFerryLabel => 'Ferry (optional)';

  @override
  String get tripDriverLabel => 'Who drives?';

  @override
  String get tripPassengersLabel => 'Who rides along?';

  @override
  String get tripDriverPays => 'Driver pays too';

  @override
  String get tripTitleLabel => 'Where to? (optional)';

  @override
  String get tripSave => 'Save trip';

  @override
  String get tripSaved => 'Trip saved';

  @override
  String get tripBreakdown => 'Details';

  @override
  String get tripBreakdownFuel => 'Fuel';

  @override
  String get tripBreakdownElectric => 'Electricity';

  @override
  String get tripBreakdownWear => 'Wear and tear';

  @override
  String get tripBreakdownKmRate => 'Flat rate per km';

  @override
  String get tripBreakdownTolls => 'Tolls';

  @override
  String get tripBreakdownFerry => 'Ferry';

  @override
  String get tripBreakdownTotal => 'Total';

  @override
  String get tripBreakdownPerPerson => 'Per person';
}
