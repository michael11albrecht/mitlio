import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/decimal_parser.dart';
import 'package:mitlio/core/money_format.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Exchange-rate input: `1 USD = [0,92] €`. Reports parts per million
/// through [onChanged] (`null` while empty or invalid) and never parses
/// through a `double`; see `parseRatePpm`.
class RateField extends StatefulWidget {
  const RateField({
    required this.fromCode,
    required this.toSymbol,
    required this.onChanged,
    required this.label,
    this.ppm,
    this.errorText,
    super.key,
  });

  /// Shown before the number: the foreign currency (`1 USD =`).
  final String fromCode;

  /// Shown after the number: the group currency symbol.
  final String toSymbol;
  final ValueChanged<int?> onChanged;
  final String label;

  /// Current value; the field adopts changes that did not come from typing.
  final int? ppm;

  /// Shown instead of the "not a valid rate" note (e.g. a missing rate).
  final String? errorText;

  @override
  State<RateField> createState() => _RateFieldState();
}

class _RateFieldState extends State<RateField> {
  final _controller = TextEditingController();
  int? _emitted;
  bool _invalid = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      _adopt(widget.ppm);
    }
  }

  @override
  void didUpdateWidget(RateField old) {
    super.didUpdateWidget(old);
    if (widget.ppm != _emitted) _adopt(widget.ppm);
  }

  void _adopt(int? ppm) {
    _emitted = ppm;
    _invalid = false;
    _controller.text = ppm == null
        ? ''
        : MoneyFormat.of(context).formatRate(ppm);
  }

  void _onChanged(String text) {
    final ppm = parseRatePpm(text);
    setState(() {
      _emitted = ppm;
      _invalid = text.trim().isNotEmpty && ppm == null;
    });
    widget.onChanged(ppm);
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
      ],
      style: MitlioTypography.tabular(Theme.of(context).textTheme.titleLarge),
      onChanged: _onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixText: '1 ${widget.fromCode} = ',
        suffixText: widget.toSymbol,
        errorText: _invalid ? l10n.rateInvalid : widget.errorText,
      ),
    );
  }
}
