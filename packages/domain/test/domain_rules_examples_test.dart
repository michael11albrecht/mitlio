import 'dart:io';

import 'package:test/test.dart';

import 'support/domain_rules_examples.dart';

/// Every examples block in docs/domain-rules.md. Adding a block to the doc
/// requires listing it here and consuming it in a test.
const _expected = {
  'allocate',
  'split',
  'balances',
  'simplify',
  'trip',
  'fx',
  'paypal',
  'iban',
  'epc',
  'rides',
};

void main() {
  test('the doc contains exactly the expected examples blocks', () {
    expect(allDomainRulesExamples().keys.toSet(), _expected);
  });

  test('every block is non-empty', () {
    for (final name in _expected) {
      // Most blocks are arrays of rows; `rides` is one object.
      expect(domainRulesExamples(name), isNotEmpty, reason: name);
    }
  });

  test('a missing block fails loudly', () {
    expect(() => domainRulesExamples('nope'), throwsStateError);
  });

  test('every examples block is consumed by some test', () {
    final sources = [
      for (final f in Directory('test').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('_test.dart') &&
            !f.path.endsWith('domain_rules_examples_test.dart'))
          f.readAsStringSync(),
    ];
    for (final name in _expected) {
      final pattern = RegExp("domainRules(Rows|Examples)\\('$name'\\)");
      expect(
        sources.any(pattern.hasMatch),
        isTrue,
        reason: 'no test loads examples:$name',
      );
    }
  });
}
