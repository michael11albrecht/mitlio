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
  String get errorNotFound =>
      'That no longer exists. Go back a step and reload.';

  @override
  String get errorConflict =>
      'That is not possible right now because something changed. Check the current state and try again.';

  @override
  String get errorLocked =>
      'That is already settled and can no longer be changed.';

  @override
  String get errorInvalidData =>
      'That input does not fit. Check it and try again.';

  @override
  String get errorStorage =>
      'That did not work. Check your device\'s free storage and try again.';

  @override
  String get shareFailed => 'Sharing did not work. Try again.';

  @override
  String get errorRateLimited =>
      'Too many requests. Try again in a few minutes.';

  @override
  String errorRateLimitedIn(int minutes) {
    return 'Too many requests. Try again in $minutes min.';
  }

  @override
  String get remoteErrorOffline =>
      'No connection. Your changes are saved and will go out as soon as you are online.';

  @override
  String get remoteErrorRateLimited =>
      'Too many attempts. Try again in a few minutes.';

  @override
  String remoteErrorRateLimitedIn(int minutes) {
    return 'Too many attempts. Try again in $minutes min.';
  }

  @override
  String get remoteErrorInviteInvalid =>
      'This link is no longer valid. Ask for a new link.';

  @override
  String remoteErrorMemberAlreadyClaimed(String name) {
    return '$name is already connected to another phone. Pick a different person.';
  }

  @override
  String get remoteErrorMemberAlreadyClaimedNoName =>
      'This person is already connected to another phone. Pick a different person.';

  @override
  String remoteErrorAlreadyConnected(String name) {
    return 'You are already connected to this group as $name.';
  }

  @override
  String get remoteErrorAlreadyConnectedNoName =>
      'You are already connected to this group.';

  @override
  String get remoteErrorMemberGone =>
      'This person is no longer in the group. Pick a different one.';

  @override
  String get remoteErrorNotOwner =>
      'Only the person who created the group can do this.';

  @override
  String get remoteErrorNotMember =>
      'You are no longer in this group. Your data stays on this phone.';

  @override
  String get remoteErrorCannotRemoveSelf => 'You cannot remove yourself here.';

  @override
  String get remoteErrorVersionTooOld =>
      'This version can no longer share. Update mitlio.';

  @override
  String get remoteErrorServerDown =>
      'The server is not responding right now. We will try again shortly.';

  @override
  String remoteErrorRejected(String title) {
    return '“$title” could not be shared. It is only on this phone.';
  }

  @override
  String get remoteErrorRejectedNoTitle =>
      'This could not be shared. It is only on this phone.';

  @override
  String get errorSettingNotSaved =>
      'The setting could not be saved. Try again.';

  @override
  String get errorUndoFailed =>
      'Undo did not work. Check the current state and try again.';

  @override
  String get retry => 'Try again';

  @override
  String get keyboardDone => 'Done';

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
  String get hideSnackBar => 'Dismiss';

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
  String groupsArchivedEntry(int count) {
    return 'Archived ($count)';
  }

  @override
  String get groupsArchivedTitle => 'Archived groups';

  @override
  String get groupRestore => 'Restore';

  @override
  String groupRestoreLabel(String name) {
    return 'Restore $name';
  }

  @override
  String groupRestored(String name) {
    return '“$name” restored';
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
  String get paymentSectionTitle => 'Payment details';

  @override
  String paymentOpen(String name) {
    return 'Payment details of $name';
  }

  @override
  String get paymentPaypalLabel => 'PayPal.Me name';

  @override
  String get paymentIbanLabel => 'IBAN';

  @override
  String get paymentBicLabel => 'BIC (optional)';

  @override
  String get paymentAccountNameLabel => 'Account holder';

  @override
  String get paymentPrivacyHint =>
      'IBAN, BIC and account holder stay on this device only.';

  @override
  String get paymentSave => 'Save';

  @override
  String get paymentErrorPaypal => 'That is not a valid PayPal.Me name.';

  @override
  String get paymentErrorIban => 'That is not a valid IBAN.';

  @override
  String get paymentErrorIbanChecksum =>
      'The IBAN check digits do not match. A typo?';

  @override
  String get paymentErrorIbanMissing => 'We need an IBAN first.';

  @override
  String get paymentErrorBic => 'That is not a valid BIC.';

  @override
  String get paymentErrorAccountName =>
      'The name can be 70 characters at most.';

  @override
  String get paymentLinkCopied => 'Link copied';

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
  String balancesOpenRides(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open rides',
      one: '1 open ride',
    );
    return 'incl. $_temp0 ($amount)';
  }

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
  String get statsMenu => 'Statistics';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsPeriodLabel => 'Period';

  @override
  String get statsPeriodMonth => 'Month';

  @override
  String get statsPeriod3Months => '3 months';

  @override
  String get statsPeriodYear => 'Year';

  @override
  String get statsPeriodAll => 'All';

  @override
  String get statsHeadlineMonth => 'This month';

  @override
  String get statsHeadline3Months => 'Last 3 months';

  @override
  String get statsHeadlineYear => 'This year';

  @override
  String get statsHeadlineAll => 'In total';

  @override
  String statsTopCategory(String category, int percent) {
    return 'mostly $category ($percent %)';
  }

  @override
  String statsExpenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get statsEmptyTitle => 'Nothing in this period';

  @override
  String get statsEmptyMessage => 'Pick another period or add an expense.';

  @override
  String get statsByCategory => 'By category';

  @override
  String get statsCategoryNone => 'No category';

  @override
  String statsPercent(int percent) {
    return '$percent %';
  }

  @override
  String statsCategorySpoken(String category, String amount, int percent) {
    return '$category: $amount, $percent percent';
  }

  @override
  String get statsByMember => 'By person';

  @override
  String get statsPaid => 'Paid';

  @override
  String get statsConsumed => 'Consumed';

  @override
  String statsMemberSpoken(String name, String paid, String consumed) {
    return '$name: paid $paid, consumed $consumed';
  }

  @override
  String get statsOverTime => 'Last 6 months';

  @override
  String statsMonthSpoken(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String get statsRides => 'Rides';

  @override
  String statsKm(String km) {
    return '$km km';
  }

  @override
  String statsRideSpoken(String month, String km, String amount) {
    return '$month: $km kilometres, $amount';
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
  String get expenseHistory => 'History';

  @override
  String get expenseHistoryEmpty => 'No changes yet';

  @override
  String get expenseHistoryRestore => 'Restore this version';

  @override
  String get expenseHistoryRestored => 'Version restored';

  @override
  String get expenseHistoryNoVisibleChange => 'No visible change';

  @override
  String expenseHistoryByAuthor(String when, String name) {
    return '$when · $name';
  }

  @override
  String expenseHistoryTitle(String from, String to) {
    return 'Title “$from” → “$to”';
  }

  @override
  String expenseHistoryAmount(String from, String to) {
    return 'Amount $from → $to';
  }

  @override
  String expenseHistoryRate(String from, String to) {
    return 'Rate $from → $to';
  }

  @override
  String expenseHistoryDate(String from, String to) {
    return 'Date $from → $to';
  }

  @override
  String expenseHistoryCategory(String from, String to) {
    return 'Category $from → $to';
  }

  @override
  String expenseHistorySplit(String from, String to) {
    return 'Split $from → $to';
  }

  @override
  String get expenseHistoryTrip => 'Trip details changed';

  @override
  String expenseHistoryPayerAdded(String name) {
    return '$name now paid too';
  }

  @override
  String expenseHistoryPayerRemoved(String name) {
    return '$name no longer paid';
  }

  @override
  String expenseHistoryPaid(String name, String from, String to) {
    return '$name paid $to instead of $from';
  }

  @override
  String expenseHistoryParticipantAdded(String name) {
    return '$name now takes part';
  }

  @override
  String expenseHistoryParticipantRemoved(String name) {
    return '$name no longer takes part';
  }

  @override
  String expenseHistoryShare(String name, String from, String to) {
    return '$name’s share: $from → $to';
  }

  @override
  String get expenseHistoryUnknownMember => 'Unknown';

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
  String get expenseCurrencyLabel => 'Currency';

  @override
  String get expenseRateLabel => 'Rate';

  @override
  String get expenseErrorRate => 'Enter the exchange rate';

  @override
  String get rateInvalid => 'That is not a valid rate';

  @override
  String expenseRateSuggestion(
    String from,
    String rate,
    String symbol,
    String date,
  ) {
    return '1 $from = $rate $symbol · ECB, $date';
  }

  @override
  String get expenseRateUse => 'Use';

  @override
  String expenseConverted(String amount) {
    return '= $amount (group currency)';
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
  String ridesDayDrivers(int count, String date, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$date, $names drove',
      one: '$date, $names drove',
    );
    return '$_temp0';
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

  @override
  String ridesSettleCardTitle(String month, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
    );
    return 'Settle $month · $_temp0';
  }

  @override
  String get ridesSettleCardAction => 'Review';

  @override
  String get ridesSettleMenu => 'Settle month';

  @override
  String get ridesMonthMenu => 'Month menu';

  @override
  String get ridesSettleNothing =>
      'This month is already settled or has no rides.';

  @override
  String ridesSettleTitle(String month) {
    return 'Settle $month';
  }

  @override
  String ridesSettleDriverLine(String name, String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rides',
      one: '1 ride',
    );
    return '$name gets $amount for $_temp0';
  }

  @override
  String get ridesSettleNote =>
      'The rides already count in the balances. Settling locks them and creates one expense per driver. You can undo it right away.';

  @override
  String get ridesSettleAction => 'Settle';

  @override
  String ridesSettleDone(String month) {
    return '$month settled';
  }

  @override
  String ridesSettleExpenseTitle(String period, String name) {
    return 'Rides $period · $name';
  }

  @override
  String get ridesFairnessTitle => 'Fairness';

  @override
  String ridesFairnessNext(String name) {
    return 'Up next: $name';
  }

  @override
  String ridesFairnessKm(String driven, String ridden) {
    return '$driven km driven · $ridden km ridden';
  }

  @override
  String get ridesDriversTitle => 'Who drives?';

  @override
  String get ridesDriversHelp => 'Only drivers are suggested as next.';

  @override
  String get ridesDriverSwitch => 'Drives';

  @override
  String ridesDriverNowDrives(String name) {
    return '$name is suggested again';
  }

  @override
  String ridesDriverNotSuggested(String name) {
    return '$name is no longer suggested';
  }

  @override
  String get ridesFairnessNotDriving => 'Doesn\'t drive · not suggested';

  @override
  String get ridesFairnessChangeDrivers => 'Change drivers';

  @override
  String get ridesFairnessHow => 'How is this calculated?';

  @override
  String get ridesFairnessHowText =>
      'The person who has driven the least is suggested: km driven minus km ridden since the last settlement. On a tie, whoever drove longest ago is next. Only members marked as drivers are suggested.';

  @override
  String ridesDriverPromptTitle(String name) {
    return 'Doesn\'t $name drive?';
  }

  @override
  String ridesDriverPromptBody(String name, int n) {
    return '$name rode along on $n rides but has never driven. As a non-driver, $name is no longer suggested as next.';
  }

  @override
  String get ridesDriverPromptMark => 'Mark as non-driver';

  @override
  String ridesDriverPromptKeep(String name) {
    return '$name drives too';
  }

  @override
  String get ridesDriverPromptManage => 'Manage drivers';

  @override
  String get settleOpen => 'Settle up';

  @override
  String get settleTitle => 'Settle up';

  @override
  String get settleOpenTitle => 'Still to pay';

  @override
  String settleTransfer(String from, String to) {
    return '$from → $to';
  }

  @override
  String get settleSettledTitle => 'All square';

  @override
  String get settleSettledMessage => 'Nobody has anything left to pay.';

  @override
  String get settleHistoryTitle => 'Settlements';

  @override
  String get settleHistoryEmpty =>
      'Nothing paid yet. Once someone pays, you will see it here.';

  @override
  String get settleHistoryDelete => 'Delete settlement';

  @override
  String get settleHistoryDeleted => 'Settlement deleted';

  @override
  String get settleShare => 'Share summary';

  @override
  String settlePaidDone(String from, String to) {
    return '$from → $to marked as paid';
  }

  @override
  String get settleAmountLabel => 'Amount';

  @override
  String settleAmountTooHigh(String amount) {
    return 'That is more than the $amount still open.';
  }

  @override
  String get settlePartialHint => 'Partial payment: the rest stays open.';

  @override
  String get settlePayPal => 'Pay with PayPal';

  @override
  String get settleBankTitle => 'Bank transfer';

  @override
  String get settleQrHint => 'Scan with your banking app';

  @override
  String settleQrLabel(String name) {
    return 'QR code for the bank transfer to $name';
  }

  @override
  String get settleCopyIban => 'Copy IBAN';

  @override
  String get settleIbanCopied => 'IBAN copied';

  @override
  String settleNoDetails(String name) {
    return '$name has no payment details yet — mark as paid anyway?';
  }

  @override
  String get settleMarkPaid => 'Mark as paid';

  @override
  String get settleActionFailed => 'That did not work. Please try again.';

  @override
  String get exportMenu => 'Export';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportCsv => 'Spreadsheet (CSV)';

  @override
  String get exportCsvHint => 'All expenses and balances';

  @override
  String get exportPdf => 'Settlement report (PDF)';

  @override
  String get exportPdfHint => 'Who pays whom, with the expense list';

  @override
  String get exportFailed => 'That did not work. Please try again.';

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColTitle => 'Title';

  @override
  String get exportColCategory => 'Category';

  @override
  String get exportColAmount => 'Amount';

  @override
  String get exportColCurrency => 'Currency';

  @override
  String get exportColPaidBy => 'Paid by';

  @override
  String get exportColMember => 'Person';

  @override
  String get exportColBalance => 'Balance';

  @override
  String get exportColPaid => 'Paid';

  @override
  String get exportColShare => 'Share';

  @override
  String get exportBalances => 'Balances';

  @override
  String get exportReportTitle => 'Settlement report';

  @override
  String exportPeriod(String from, String to) {
    return 'Period: $from – $to';
  }

  @override
  String get exportPeriodNone => 'No expenses yet';

  @override
  String get exportMembers => 'People';

  @override
  String get exportTotals => 'Totals per person';

  @override
  String get exportTransfers => 'Settle up';

  @override
  String get exportAllSettled => 'All settled';

  @override
  String get exportExpenses => 'Expenses';

  @override
  String exportPaypal(String handle) {
    return 'PayPal: $handle';
  }

  @override
  String exportIbanHint(String hint) {
    return 'IBAN $hint';
  }

  @override
  String get exportCategoryFood => 'Food';

  @override
  String get exportCategoryStay => 'Stay';

  @override
  String get exportCategoryTransport => 'Transport';

  @override
  String get exportCategoryFun => 'Fun';

  @override
  String get exportCategoryOther => 'Other';

  @override
  String get onboardingTitle => 'Welcome to mitlio';

  @override
  String get onboardingValue =>
      'Split ride costs and expenses fairly — no sign-up, no ads.';

  @override
  String get onboardingCommute => 'Start a carpool';

  @override
  String get onboardingCommuteHint =>
      'Set up the car and route once, then 2 taps per ride.';

  @override
  String get onboardingCommuteGroupName => 'Carpool';

  @override
  String get onboardingGroup => 'Create a group for expenses';

  @override
  String get onboardingGroupHint =>
      'For trips, your flat or a night out together.';

  @override
  String get onboardingTripOnly => 'Just calculate one trip';

  @override
  String tripSeatName(int number) {
    return 'Person $number';
  }

  @override
  String get tripShare => 'Share result';

  @override
  String tripShareText(String amount) {
    return 'Trip cost: each person pays $amount';
  }

  @override
  String get balancesEmptyAction => 'Add an expense';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get privacySection => 'Privacy';

  @override
  String get crashReportsLabel => 'Send crash reports';

  @override
  String get crashReportsHint =>
      'Only on a crash: technical error data without names, amounts, notes or IBAN. Off by default.';

  @override
  String get crashReportsUnavailable => 'Not available in this version.';

  @override
  String get deleteMyDataEntry => 'Delete all my data';

  @override
  String get deleteMyDataEntryHint =>
      'Remove groups, expenses and rides from this device';

  @override
  String get deleteMyDataTitle => 'Delete all my data';

  @override
  String get deleteMyDataWhatTitle => 'What gets deleted';

  @override
  String get deleteMyDataWhat =>
      'On this device: all groups, members, expenses, rides, settlements, payment details (including IBAN and its key) and your settings. Afterwards the app starts as if new.';

  @override
  String get deleteMyDataServer =>
      'On the server: your links to groups and your account, if you have one.';

  @override
  String get deleteMyDataStaysTitle => 'What stays';

  @override
  String get deleteMyDataStays =>
      'Shared group data that other members have on their devices stays with them. It belongs to the group, not to you alone.';

  @override
  String get deleteMyDataIrreversible => 'This cannot be undone.';

  @override
  String get deleteMyDataConfirmWord => 'DELETE';

  @override
  String get deleteMyDataConfirmLabel => 'Type DELETE to confirm';

  @override
  String get deleteMyDataAction => 'Delete everything for good';

  @override
  String get deleteMyDataFailed =>
      'Deleting did not work. Nothing was deleted. Please try again.';

  @override
  String get fuelChipsLabel => 'Use a fuel price';

  @override
  String get fuelGradeE5 => 'E5';

  @override
  String get fuelGradeE10 => 'E10';

  @override
  String get fuelGradeDiesel => 'Diesel';

  @override
  String get fuelScopeNational => 'Ø Germany';

  @override
  String fuelScopePlz(String plz) {
    return 'Ø postcode $plz';
  }

  @override
  String get fuelScopeNearby => 'Ø near you';

  @override
  String get fuelAgeNow => 'just now';

  @override
  String fuelAgeMinutes(int count) {
    return '$count min ago';
  }

  @override
  String fuelAgeHours(int count) {
    return '$count h ago';
  }

  @override
  String fuelAgeDays(int count) {
    return '$count days ago';
  }

  @override
  String fuelAgeSince(String date) {
    return 'as of $date';
  }

  @override
  String get fuelOfflineNote => 'offline, last known';

  @override
  String get fuelStaleRateLimited => 'too many requests, last known';

  @override
  String fuelStaleRateLimitedIn(int minutes) {
    return 'too many requests, retry in $minutes min, last known';
  }

  @override
  String get fuelStaleServer => 'price service unreachable, last known';

  @override
  String get fuelRateLimited =>
      'Too many price requests – try again in a few minutes.';

  @override
  String fuelRateLimitedIn(int minutes) {
    return 'Too many price requests – try again in $minutes min.';
  }

  @override
  String get fuelOffline =>
      'No connection. Check your network or enter the price yourself.';

  @override
  String get fuelServerDown =>
      'The price service is unreachable right now. Try again later or enter the price yourself.';

  @override
  String get fuelNoPrice =>
      'No current price available right now. Just enter it yourself.';

  @override
  String get fuelNearby => 'Near me';

  @override
  String get fuelNearbyDenied =>
      'Location not shared, the national average applies.';

  @override
  String get fuelNearbyBlocked =>
      'Location is blocked in the system settings, the national average applies.';

  @override
  String get fuelNearbyUnavailable => 'Location not available right now.';

  @override
  String get fuelPlzAction => 'Enter postcode';

  @override
  String get fuelPlzLabel => 'Postcode';

  @override
  String get fuelPlzInvalid => 'Please enter five digits';

  @override
  String get fuelPlzApply => 'Apply';

  @override
  String get fuelNationalAction => 'Nationwide';

  @override
  String get fuelAttributionFallback => 'Fuel price data';

  @override
  String get routeToggle =>
      'Enter start and destination to calculate the distance';

  @override
  String get routeStartLabel => 'Start';

  @override
  String get routeEndLabel => 'Destination';

  @override
  String routeResult(String km) {
    return '$km km by road';
  }

  @override
  String get routeRecalculate => 'Recalculate';

  @override
  String get routeSearching => 'Searching …';

  @override
  String get routeCalculating => 'Calculating the distance …';

  @override
  String get routeNoMatches =>
      'No matches. Try another place or enter the kilometres yourself.';

  @override
  String get routeSavedHome => 'Home';

  @override
  String get routeSavedWork => 'Work';

  @override
  String get routeSaveAsHome => 'Save as home';

  @override
  String get routeSaveAsWork => 'Save as work';

  @override
  String get routeSavedAsHome => 'Saved as home';

  @override
  String get routeSavedAsWork => 'Saved as work';

  @override
  String get routeOffline =>
      'No connection. Just enter the kilometres yourself.';

  @override
  String get routeRateLimited =>
      'Too many route requests. Try again later or enter the kilometres yourself.';

  @override
  String routeRateLimitedIn(int minutes) {
    return 'Too many route requests. Try again in $minutes min or enter the kilometres yourself.';
  }

  @override
  String get routeNoRoute =>
      'There is no road connection between these places. Check start and destination or enter the kilometres yourself.';

  @override
  String get routeServerDown =>
      'The route service is unreachable right now. Try again later or enter the kilometres yourself.';

  @override
  String get routeInvalid =>
      'Start and destination do not fit together. Pick two different places or enter the kilometres yourself.';

  @override
  String get routeAttributionFallback =>
      'Map and route data © OpenStreetMap contributors';
}
