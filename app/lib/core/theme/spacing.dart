import 'package:material_ui/material_ui.dart';

/// Spacing scale (4 px grid). The only source of paddings and gaps.
abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Horizontal screen gutter.
  static const double gutter = md;

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// Default content padding of screens.
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: gutter,
    vertical: md,
  );
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}

/// Fixed component sizes.
abstract final class Sizes {
  /// Minimum interactive size (Material/Android guideline, one-handed use).
  static const double tapTarget = 48;

  static const double avatar = 40;
  static const double avatarSmall = 28;
  static const double stateIcon = 56;

  /// Edge of a payment QR code (large enough for banking apps to scan).
  static const double qrCode = 208;

  /// Bottom padding of lists with an extended floating action button, so the
  /// last row can scroll clear of it.
  static const double fabClearance = 88;

  /// Height of one day of the rides calendar (day number plus an avatar).
  static const double calendarCell = 64;
}
