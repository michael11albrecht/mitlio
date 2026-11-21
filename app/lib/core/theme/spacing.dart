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

  /// The brand mark on the first-run screen.
  static const double brandMark = 72;

  /// Widest a calm single-column screen gets on tablets and desktop.
  static const double contentMaxWidth = 480;

  /// Edge of a payment QR code (large enough for banking apps to scan).
  static const double qrCode = 208;

  /// Bottom padding of lists with an extended floating action button, so the
  /// last row can scroll clear of it.
  static const double fabClearance = 88;

  /// Width of the currency dropdown next to the amount (label plus a
  /// three-letter code).
  static const double currencyPicker = 112;

  /// Thickness of a bar in the statistics bar lists.
  static const double barHeight = 8;

  /// Minimum height of a yes/no card in a setup flow (a big, calm target).
  static const double choiceCard = 72;

  /// Diameter of the avatar preview on the profile avatar step and card.
  static const double profileAvatar = 96;

  /// Height of the picture slot above a setup step (illustrations, PU-T06).
  static const double stepVisual = 120;

  /// Edge of the finish-screen celebration.
  static const double celebration = 120;

  /// Edge of the placeholder slot for a setup step's illustration (PU-T06
  /// replaces its content).
  static const double illustration = 96;

  /// Height of the stacked cost bar and the dot in front of a legend row.
  static const double stackedBar = 24;
  static const double legendDot = 12;

  /// Height of one day of the rides calendar (day number plus an avatar).
  static const double calendarCell = 64;
}
