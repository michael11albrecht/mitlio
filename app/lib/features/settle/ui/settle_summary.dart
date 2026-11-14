/// One "who pays whom" line of the share text, already in display form.
typedef SummaryTransfer = ({String from, String to, String amount});

/// `Urlaub Italien: Ben → Anna 12,40 €, Carla → Anna 8,10 €`. The caller
/// formats amounts for the locale. Empty if there is nothing to pay.
String buildSettleSummary(String groupName, List<SummaryTransfer> transfers) {
  if (transfers.isEmpty) return '';
  final parts = [for (final t in transfers) '${t.from} → ${t.to} ${t.amount}'];
  return '$groupName: ${parts.join(', ')}';
}
