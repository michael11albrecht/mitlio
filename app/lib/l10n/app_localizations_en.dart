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
}
