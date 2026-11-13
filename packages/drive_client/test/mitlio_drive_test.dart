import 'package:mitlio_drive/mitlio_drive.dart';
import 'package:test/test.dart';

void main() {
  group('extensionName', () {
    test('adds the prefix to short names', () {
      expect(extensionName('ping'), 'ext.mitlio.ping');
    });

    test('keeps already qualified names', () {
      expect(extensionName('ext.mitlio.ping'), 'ext.mitlio.ping');
    });
  });
}
