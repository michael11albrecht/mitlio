import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/member_avatar.dart';
import 'package:mitlio/features/profile/ui/profile_photo_view_model.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// Id the profile's default avatar colour is derived from.
const _selfId = 'me';

/// The profile's round avatar: an emoji or the initials on the chosen
/// colour ([color] is its ARGB value), else on the colour derived from the
/// name. A [photo] (the processed PNG) replaces all of that.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    this.color,
    this.emoji,
    this.photo,
    this.size = Sizes.avatar,
    super.key,
  });

  final String name;
  final int? color;
  final String? emoji;
  final Uint8List? photo;
  final double size;

  /// The theme colour pair for [argb] if it is one of the avatar palette
  /// colours (either theme), else null.
  static AvatarColors? paletteColors(int argb) {
    for (final palette in [MitlioColors.light, MitlioColors.dark]) {
      for (final c in palette.avatars) {
        if (c.background.toARGB32() == argb) return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = MitlioColors.of(context).avatars;
    final derived = palette[MemberAvatar.colorIndex(_selfId, palette.length)];
    final chosen = color == null ? null : paletteColors(color!);
    final background = color == null
        ? derived.background
        : (chosen?.background ?? Color(color!));
    final foreground =
        chosen?.foreground ??
        (color == null
            ? derived.foreground
            : Theme.of(context).colorScheme.onSurface);
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
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: photo != null
              ? ClipOval(
                  child: Image.memory(
                    photo!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                )
              : Center(
                  child: MediaQuery.withNoTextScaling(
                    child: Text(
                      emoji ?? MemberAvatar.initials(name),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
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

/// The profile as friends will see it: avatar, name, the PayPal.Me link and
/// the end of the IBAN (never all of it).
class ProfileCard extends ConsumerWidget {
  const ProfileCard({required this.data, super.key});

  final ProfileCardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = data.profile;
    final lines = [
      if (profile.paypalMe != null) l10n.profileCardPaypal(profile.paypalMe!),
      if (data.ibanTail != null) l10n.profileCardIban(data.ibanTail!),
    ];
    return Card(
      child: Padding(
        padding: Spacing.allMd,
        child: Row(
          children: [
            ProfileAvatar(
              name: profile.displayName,
              color: profile.avatarColor,
              emoji: profile.avatarEmoji,
              photo: ref.watch(profilePhotoViewModelProvider).photo,
              size: Sizes.profileAvatar / 2,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (lines.isEmpty)
                    Text(
                      l10n.profileCardNoPayment,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  for (final line in lines)
                    Text(
                      line,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
