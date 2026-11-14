import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/amount_parser.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Cents-safe amount input. Accepts `12,34` and `12.34`, reports integer
/// minor units through [onChanged] (`null` while empty or invalid) and never
/// parses through a `double`.
class AmountField extends StatefulWidget {
  const AmountField({
    required this.currency,
    required this.onChanged,
    required this.label,
    this.cents,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final Currency currency;
  final ValueChanged<int?> onChanged;

  /// Localised field label (the caller owns the copy).
  final String label;

  /// Current value; the field adopts changes that did not come from typing.
  final int? cents;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  final _controller = TextEditingController();
  int? _emitted;
  bool _invalid = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _adopt(widget.cents);
    }
  }

  @override
  void didUpdateWidget(AmountField old) {
    super.didUpdateWidget(old);
    if (widget.cents != _emitted) _adopt(widget.cents);
  }

  void _adopt(int? cents) {
    _emitted = cents;
    _invalid = false;
    _controller.text = cents == null
        ? ''
        : MoneyFormat.of(context).formatPlain(cents, widget.currency);
  }

  void _onChanged(String text) {
    final cents = parseAmountCents(text, widget.currency);
    setState(() {
      _emitted = cents;
      _invalid = text.trim().isNotEmpty && cents == null;
    });
    widget.onChanged(cents);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
      ],
      style: MitlioTypography.tabular(
        Theme.of(context).textTheme.headlineMedium,
      ),
      onChanged: _onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: MoneyFormat.of(context).currencySymbol(widget.currency),
        errorText: _invalid ? l10n.amountInvalid : null,
      ),
    );
  }
}
