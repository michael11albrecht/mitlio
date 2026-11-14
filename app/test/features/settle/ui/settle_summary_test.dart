import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/settle/ui/settle_summary.dart';

void main() {
  group('buildSettleSummary', () {
    test('lists every transfer after the group name', () {
      expect(
        buildSettleSummary('Urlaub Italien', [
          (from: 'Ben', to: 'Anna', amount: '12,40 €'),
          (from: 'Carla', to: 'Anna', amount: '8,10 €'),
        ]),
        'Urlaub Italien: Ben → Anna 12,40 €, Carla → Anna 8,10 €',
      );
    });

    test('one transfer has no separator', () {
      expect(
        buildSettleSummary('WG', [(from: 'Ben', to: 'Anna', amount: '€5.00')]),
        'WG: Ben → Anna €5.00',
      );
    });

    test('nothing to pay is an empty text', () {
      expect(buildSettleSummary('WG', const []), isEmpty);
    });

    test('names and amounts are passed through untouched', () {
      expect(
        buildSettleSummary('Ski, Hütte & Co', [
          (from: 'Zoë', to: 'Dino Kovač', amount: '1.234,56 €'),
        ]),
        'Ski, Hütte & Co: Zoë → Dino Kovač 1.234,56 €',
      );
    });
  });
}
