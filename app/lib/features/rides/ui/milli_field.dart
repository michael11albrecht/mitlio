import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Decimal input in thousandths: litres per 100 km, a price per litre, a
/// rate per km, kilometres (km x 1000 = metres). Accepts `6,5` and `6.5`,
/// reports the value through [onChanged] (`null` while empty or invalid) and
/// never parses through a `double`.
class MilliField extends StatefulWidget {
  const MilliField({
    required this.label,
    required this.onChanged,
    this.milli,
    this.suffix,
    this.helper,
    this.errorText,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final ValueChanged<int?> onChanged;

  /// Current value; the field adopts changes that did not come from typing.
  final int? milli;
  final String? suffix;
  final String? helper;

  /// Shown instead of the "not a valid number" message when set.
  final String? errorText;
  final bool autofocus;

  @override
  State<MilliField> createState() => _MilliFieldState();
}

class _MilliFieldState extends State<MilliField> {
  final _controller = TextEditingController();
  int? _emitted;
  bool _invalid = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _adopt(widget.milli);
    }
  }

  @override
  void didUpdateWidget(MilliField old) {
    super.didUpdateWidget(old);
    if (widget.milli != _emitted) _adopt(widget.milli);
  }

  void _adopt(int? milli) {
    _emitted = milli;
    _invalid = false;
    _controller.text = milli == null
        ? ''
        : formatMilli(
            milli,
            separator: MoneyFormat.of(context).decimalSeparator,
          );
  }

  void _onChanged(String text) {
    final milli = parseMilli(text);
    setState(() {
      _emitted = milli;
      _invalid = text.trim().isNotEmpty && milli == null;
    });
    widget.onChanged(milli);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      onChanged: _onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix,
        helperText: widget.helper,
        helperMaxLines: 3,
        errorText:
            widget.errorText ??
            (_invalid ? AppLocalizations.of(context).amountInvalid : null),
      ),
    );
  }
}
