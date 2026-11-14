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
  String get tabMembers => 'Members';

  @override
  String get tabExpenses => 'Expenses';

  @override
  String get expensesEmptyTitle => 'No expenses yet';

  @override
  String get expensesEmptyMessage => 'Add the first one.';

  @override
  String get expenseAdd => 'Add expense';

  @override
  String get expensesNoMembersMessage =>
      'First add the people who share costs.';

  @override
  String get expensesNoMembersAction => 'Add members';

  @override
  String get expenseToday => 'Today';

  @override
  String get expenseYesterday => 'Yesterday';

  @override
  String expensePaidBy(String name) {
    return '$name paid';
  }

  @override
  String expensePaidByMore(String name, int count) {
    return '$name +$count paid';
  }

  @override
  String expenseDeleted(String title) {
    return '“$title” deleted';
  }

  @override
  String get expenseDelete => 'Delete';

  @override
  String get expenseFilterPerson => 'Person';

  @override
  String get expenseFilterCategory => 'Category';

  @override
  String get expenseFilterAll => 'All';

  @override
  String get expenseFilterEmptyTitle => 'Nothing found';

  @override
  String get expenseFilterReset => 'Reset filters';

  @override
  String get expenseCategoryFood => 'Food & drinks';

  @override
  String get expenseCategoryStay => 'Accommodation';

  @override
  String get expenseCategoryTransport => 'Transport';

  @override
  String get expenseCategoryFun => 'Leisure';

  @override
  String get expenseCategoryOther => 'Other';

  @override
  String get expenseFormNew => 'New expense';

  @override
  String get expenseFormEdit => 'Edit expense';

  @override
  String get expenseAmountLabel => 'Amount';

  @override
  String get expenseTitleLabel => 'What for?';

  @override
  String get expenseTitleHint => 'e.g. Pizza';

  @override
  String get expenseDateChange => 'Change date';

  @override
  String get expensePayerSection => 'Who paid?';

  @override
  String get expensePayerMulti => 'Several people paid';

  @override
  String get expensePayerSingle => 'Only one person paid';

  @override
  String get expenseSplitSection => 'Split';

  @override
  String get expenseSplitEqual => 'Equal';

  @override
  String get expenseSplitShares => 'Shares';

  @override
  String get expenseSplitPercent => 'Percent';

  @override
  String get expenseSplitExact => 'Exact';

  @override
  String get expenseCategorySection => 'Category (optional)';

  @override
  String get expenseSave => 'Save';

  @override
  String get expenseErrorTitle => 'Give the expense a title';

  @override
  String get expenseErrorAmount => 'Enter an amount';

  @override
  String get expenseErrorNoParticipants => 'Pick at least one person';

  @override
  String get expenseErrorNoPayer => 'Pick who paid';

  @override
  String get expenseErrorGeneric => 'That doesn\'t add up yet';

  @override
  String expenseLeftOver(String amount) {
    return '$amount left to assign';
  }

  @override
  String expenseOver(String amount) {
    return '$amount too much';
  }

  @override
  String expensePercentSum(String sum) {
    return 'Total $sum, it must be 100 %';
  }

  @override
  String expenseSharesFewer(String name) {
    return 'Fewer shares for $name';
  }

  @override
  String expenseSharesMore(String name) {
    return 'More shares for $name';
  }

  @override
  String get expenseExcluded => 'Not included';

  @override
  String get tabRides => 'Rides';

  @override
  String get ridesEmptyTitle => 'No route yet';

  @override
  String get ridesEmptyMessage =>
      'Add your car and your route, then two taps log a ride.';

  @override
  String get ridesEmptyActionVehicle => 'Add car and route';

  @override
  String get ridesEmptyActionTemplate => 'Add a route';

  @override
  String get ridesNoMembersMessage => 'Add the people who ride along first.';

  @override
  String get ridesSettings => 'Cars and routes';

  @override
  String get quickLogTitleToday => 'Drove today';

  @override
  String quickLogTitleDate(String date) {
    return 'Drove on $date';
  }

  @override
  String get quickLogPickRoute => 'Pick your route.';

  @override
  String get quickLogDriver => 'Who drives?';

  @override
  String get quickLogPassengers => 'Who rides along?';

  @override
  String get quickLogSave => 'Save';

  @override
  String get quickLogAnother => 'Another ride';

  @override
  String quickLogDone(String name) {
    return '$name drove';
  }

  @override
  String quickLogPrice(String price, String unit) {
    return 'Fuel $price per $unit';
  }

  @override
  String quickLogPriceLabel(String unit) {
    return 'Price per $unit';
  }

  @override
  String get quickLogPriceSet => 'Apply';

  @override
  String get quickLogBackToToday => 'Back to today';

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
    return '$name pays $amount';
  }

  @override
  String get ridesNobodyOwes => 'No passengers, nothing to split';

  @override
  String ridesSaved(String summary) {
    return 'Saved · $summary';
  }

  @override
  String get ridesRideDeleted => 'Ride deleted';

  @override
  String get ridesLocked => 'Settled, locked';

  @override
  String get ridesMonthPrev => 'Previous month';

  @override
  String get ridesMonthNext => 'Next month';

  @override
  String get ridesMonthEmpty => 'No ride this month yet';

  @override
  String ridesDayDrivers(String date, String names) {
    return '$date: $names';
  }

  @override
  String get ridesDayNoRides => 'No ride on this day';

  @override
  String get ridesDayLog => 'Log a ride for this day';

  @override
  String ridesRideTitle(String name, String distance) {
    return '$name drove · $distance';
  }

  @override
  String ridesRidePassengers(String names) {
    return 'with $names';
  }

  @override
  String get ridesRideDelete => 'Delete ride';

  @override
  String get ridesSettingsTitle => 'Cars and routes';

  @override
  String get ridesVehicles => 'Cars';

  @override
  String get ridesTemplates => 'Routes';

  @override
  String get ridesVehiclesEmpty => 'No car yet';

  @override
  String get ridesTemplatesEmpty => 'No route yet';

  @override
  String get ridesVehicleAdd => 'Add a car';

  @override
  String get ridesTemplateAdd => 'Add a route';

  @override
  String ridesVehicleDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String ridesTemplateDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String get ridesVehicleInUse => 'A route still uses this car.';

  @override
  String ridesVehicleLine(String fuel, String consumption, String unit) {
    return '$fuel · $consumption $unit/100 km';
  }

  @override
  String get ridesDelete => 'Delete';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelDiesel => 'Diesel';

  @override
  String get fuelElectric => 'Electric';

  @override
  String get fuelOther => 'Other';

  @override
  String get vehicleFormNew => 'New car';

  @override
  String get vehicleFormEdit => 'Edit car';

  @override
  String get vehicleNameLabel => 'Name';

  @override
  String get vehicleNameHint => 'e.g. Golf';

  @override
  String get vehicleFuelSection => 'Fuel';

  @override
  String get vehicleConsumptionLitre => 'Consumption (l/100 km)';

  @override
  String get vehicleConsumptionKwh => 'Consumption (kWh/100 km)';

  @override
  String get vehicleWearLabel => 'Wear per km (optional)';

  @override
  String get vehicleKmRateLabel => 'Rate per km (optional)';

  @override
  String get vehicleKmRateHelper =>
      'With a rate, the amount per km replaces fuel and wear.';

  @override
  String get vehicleErrorName => 'Enter a name';

  @override
  String get vehicleErrorConsumption => 'Enter the consumption';

  @override
  String get vehicleSave => 'Save';

  @override
  String get templateFormNew => 'New route';

  @override
  String get templateFormEdit => 'Edit route';

  @override
  String get templateNameLabel => 'Name';

  @override
  String get templateNameHint => 'e.g. Work';

  @override
  String get templateDistanceLabel => 'One-way distance (km)';

  @override
  String get templateRoundTrip => 'Round trip';

  @override
  String get templateVehicleSection => 'Car';

  @override
  String get templateDriverSection => 'Driver';

  @override
  String get templateDriverNone => 'Alternates';

  @override
  String get templatePassengersSection => 'Rides along';

  @override
  String get templateTollsLabel => 'Tolls (optional)';

  @override
  String get templateErrorName => 'Enter a name';

  @override
  String get templateErrorDistance => 'Enter the distance';

  @override
  String get templateNoVehicle => 'Add a car first.';

  @override
  String get templateNoVehicleAction => 'Add a car';

  @override
  String get templateSave => 'Save';
}
