import 'package:material_ui/material_ui.dart';

/// mitlio palette: "Nordic petrol". One accent (deep petrol-teal, the colour
/// of a fuel gauge at night) on cool, slightly green-tinted neutrals. Calm
/// rather than loud: no red/green money semantics, errors are a muted brick.
/// All text pairs are >= 4.5:1 (checked in `mitlio_theme_test.dart`).
abstract final class MitlioPalette {
  // Light
  static const Color lightBackground = Color(0xFFF4F7F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFE7EEEC);
  static const Color lightInk = Color(0xFF111E1C);
  static const Color lightInkMuted = Color(0xFF475856);
  static const Color lightOutline = Color(0xFF6E807D);
  static const Color lightOutlineSoft = Color(0xFFCBD7D4);
  static const Color lightAccent = Color(0xFF0B6B63);
  static const Color lightOnAccent = Color(0xFFFFFFFF);
  static const Color lightAccentContainer = Color(0xFFD3EEE9);
  static const Color lightOnAccentContainer = Color(0xFF063A35);
  static const Color lightError = Color(0xFFA3321C);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFF8DDD6);
  static const Color lightOnErrorContainer = Color(0xFF5A1A0C);

  // Dark
  static const Color darkBackground = Color(0xFF0C1413);
  static const Color darkSurface = Color(0xFF152120);
  static const Color darkSurfaceMuted = Color(0xFF1E2D2B);
  static const Color darkInk = Color(0xFFE6EFED);
  static const Color darkInkMuted = Color(0xFFA6B9B5);
  static const Color darkOutline = Color(0xFF7F9591);
  static const Color darkOutlineSoft = Color(0xFF2F403D);
  static const Color darkAccent = Color(0xFF5ED0C0);
  static const Color darkOnAccent = Color(0xFF03211D);
  static const Color darkAccentContainer = Color(0xFF0F4A44);
  static const Color darkOnAccentContainer = Color(0xFFC4F0E9);
  static const Color darkError = Color(0xFFFFA18C);
  static const Color darkOnError = Color(0xFF4A1307);
  static const Color darkErrorContainer = Color(0xFF6B2412);
  static const Color darkOnErrorContainer = Color(0xFFFFDDD4);
}

/// Background/foreground pair for a member avatar.
class AvatarColors {
  const AvatarColors(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Theme extension for colours Material's `ColorScheme` has no slot for.
class MitlioColors extends ThemeExtension<MitlioColors> {
  const MitlioColors({required this.avatars});

  /// Eight member colours, chosen by a stable hash of the member id.
  final List<AvatarColors> avatars;

  static const light = MitlioColors(
    avatars: [
      AvatarColors(Color(0xFF0B6B63), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF8A4B08), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF6B4FA3), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFFA23B5A), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF2F5D9E), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF576511), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF9A3E1F), Color(0xFFFFFFFF)),
      AvatarColors(Color(0xFF475A70), Color(0xFFFFFFFF)),
    ],
  );

  static const dark = MitlioColors(
    avatars: [
      AvatarColors(Color(0xFF7FD6C8), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFF0B86E), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFB9A5F0), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFF29BB4), Color(0xFF0C1413)),
      AvatarColors(Color(0xFF8FB4F0), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFC3D56B), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFF2A98C), Color(0xFF0C1413)),
      AvatarColors(Color(0xFFAEBBCC), Color(0xFF0C1413)),
    ],
  );

  /// Colours of the ambient theme.
  static MitlioColors of(BuildContext context) =>
      Theme.of(context).extension<MitlioColors>()!;

  @override
  MitlioColors copyWith({List<AvatarColors>? avatars}) =>
      MitlioColors(avatars: avatars ?? this.avatars);

  @override
  MitlioColors lerp(MitlioColors? other, double t) =>
      t < 0.5 ? this : other ?? this;
}
