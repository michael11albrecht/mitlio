import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:test/test.dart';

void main() {
  test('domain rules version is defined', () {
    expect(domainRulesVersion, greaterThanOrEqualTo(1));
  });
}
