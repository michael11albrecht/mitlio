import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// Round avatar with the member's initials on a colour derived from the
/// member id (stable across launches and devices, drawn from theme tokens).
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.memberId,
    required this.name,
    this.size = Sizes.avatar,
    super.key,
  });

  final String memberId;
  final String name;

  /// Diameter at text scale 1.0; grows with the user's text scale (max 2x).
  final double size;

  /// Up to two initials: first letters of first and last word, upper-cased.
  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
    return words.length == 1
        ? first(words.first)
        : first(words.first) + first(words.last);
  }

  /// Index into the palette: FNV-1a over UTF-16 units (String.hashCode is not
  /// guaranteed stable across runs/platforms).
  static int colorIndex(String memberId, int paletteSize) {
    var hash = 0x811c9dc5;
    for (final unit in memberId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash % paletteSize;
  }

  @override
  Widget build(BuildContext context) {
    final palette = MitlioColors.of(context).avatars;
    final colors = palette[colorIndex(memberId, palette.length)];
    final diameter = MediaQuery.textScalerOf(
      context,
    ).scale(size).clamp(size, size * 2);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.background,
            shape: BoxShape.circle,
          ),
          // The circle already scales; keep initials inside it.
          child: Center(
            child: MediaQuery.withNoTextScaling(
              child: Text(
                initials(name),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.foreground,
                  fontSize: diameter * 0.4,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
