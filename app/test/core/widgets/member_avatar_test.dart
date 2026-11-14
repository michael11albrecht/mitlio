import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';

import '../../helpers/a11y.dart';
import '../../helpers/themed_app.dart';

void main() {
  forEachMode(
    'MemberAvatar meets a11y guidelines',
    () => const MemberAvatar(memberId: 'm1', name: 'Anna Berg'),
    (tester, _, _) => expectAccessible(tester),
  );

  group('initials', () {
    test('first and last word', () {
      expect(MemberAvatar.initials('anna berg'), 'AB');
      expect(MemberAvatar.initials('Anna Maria von Berg'), 'AB');
    });
    test('single word, blank, whitespace, non-BMP', () {
      expect(MemberAvatar.initials('Anna'), 'A');
      expect(MemberAvatar.initials(''), '?');
      expect(MemberAvatar.initials('   '), '?');
      expect(MemberAvatar.initials('  Äsop  '), 'Ä');
      expect(MemberAvatar.initials('😀 Smile'), '😀S');
    });
  });

  group('colorIndex', () {
    test('is deterministic and in range', () {
      expect(
        MemberAvatar.colorIndex('abc', 8),
        MemberAvatar.colorIndex('abc', 8),
      );
      for (final id in ['', 'a', 'member-1', 'x' * 500]) {
        expect(MemberAvatar.colorIndex(id, 8), inInclusiveRange(0, 7));
      }
    });
    test('pinned values (stable across platforms)', () {
      // FNV-1a 32 of "a" = 0xE40C292C; of "" = 0x811C9DC5.
      expect(MemberAvatar.colorIndex('a', 8), 0xE40C292C % 8);
      expect(MemberAvatar.colorIndex('', 8), 0x811C9DC5 % 8);
    });
    test('spreads ids over the palette', () {
      final used = {
        for (var i = 0; i < 64; i++) MemberAvatar.colorIndex('member-$i', 8),
      };
      expect(used.length, greaterThanOrEqualTo(6));
    });
  });

  testWidgets('uses palette colour of the id and labels the name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      themedApp(const MemberAvatar(memberId: 'a', name: 'Anna Berg')),
    );
    final expected =
        MitlioColors.light.avatars[MemberAvatar.colorIndex(
          'a',
          MitlioColors.light.avatars.length,
        )];
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MemberAvatar),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      (box.decoration as BoxDecoration).color,
      expected.background,
    );
    expect(find.bySemanticsLabel('Anna Berg'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('grows with text scale but caps at 2x', (tester) async {
    await tester.pumpWidget(
      themedApp(const MemberAvatar(memberId: 'a', name: 'A'), textScale: 3),
    );
    expect(tester.getSize(find.byType(MemberAvatar)), const Size(80, 80));
  });
}
