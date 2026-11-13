/// Splits [total] into one share per weight using the largest remainder method.
///
/// Index order is the tie order. See docs/domain-rules.md, "Allocation".
///
/// Throws [ArgumentError] if [total] is negative, [weights] is empty, any
/// weight is negative, or the weights sum to zero.
List<int> allocate(int total, List<int> weights) {
  if (total < 0) {
    throw ArgumentError('total must not be negative');
  }
  if (weights.isEmpty) {
    throw ArgumentError('weights must not be empty');
  }
  // BigInt throughout: the sum and products can exceed 2^53 (dart2js) or 2^63.
  var sum = BigInt.zero;
  for (final w in weights) {
    if (w < 0) {
      throw ArgumentError('weights must not be negative');
    }
    sum += BigInt.from(w);
  }
  if (sum == BigInt.zero) {
    throw ArgumentError('weights must not sum to zero');
  }

  final bigTotal = BigInt.from(total);
  final result = List<int>.filled(weights.length, 0);
  final remainders = List<BigInt>.filled(weights.length, BigInt.zero);
  var left = total;
  for (var i = 0; i < weights.length; i++) {
    final product = bigTotal * BigInt.from(weights[i]);
    result[i] = (product ~/ sum).toInt();
    remainders[i] = product % sum;
    left -= result[i];
  }

  final order = List<int>.generate(weights.length, (i) => i)
    ..sort((a, b) {
      final byRemainder = remainders[b].compareTo(remainders[a]);
      return byRemainder != 0 ? byRemainder : a.compareTo(b);
    });
  for (var k = 0; k < left; k++) {
    result[order[k]]++;
  }
  return result;
}
