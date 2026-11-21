import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_config.dart';
import 'package:mitlio/features/profile/data/repositories/profile_bank_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/data/repositories/profile_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Id of the profile flow: the key of its saved progress and the `flowId` of
/// `ext.mitlio.setup.*`. Never rename after release.
const profileFlowId = 'profile';

/// Step ids (the keys of the stored answers). Never rename after release.
const profileStepName = 'name';
const profileStepAvatar = 'avatar';
const profileStepPaypalWanted = 'paypal_wanted';
const profileStepPaypalMe = 'paypal_me';
const profileStepBankWanted = 'bank_wanted';
const profileStepIban = 'iban';

/// Keys of the answer map of the [profileStepAvatar] step.
const profileAnswerColor = 'color';
const profileAnswerEmoji = 'emoji';

/// Keys of the answer map of the [profileStepIban] step.
const profileAnswerIban = 'iban';
const profileAnswerHolder = 'holder';

/// What the flow remembers as the answer of the IBAN step. The IBAN itself
/// goes to the local bank table only: never into the plain-text progress.
const profileIbanStored = true;

/// The profile flow (PU-T07, ADR-25): name, avatar, PayPal yes/no and
/// PayPal.Me, bank transfer yes/no and IBAN. Only the name is required.
/// Every step stores its answer in the profile repositories on "Weiter", so
/// leaving and resuming loses nothing. Register it in
/// `setupFlowConfigsProvider` for DebugDrive.
final profileSetupFlow = SetupFlowConfig(
  id: profileFlowId,
  steps: [
    const SetupStepSpec(
      profileStepName,
      skippable: false,
      validate: _validateName,
      commit: _commitName,
    ),
    const SetupStepSpec(
      profileStepAvatar,
      validate: _validateAvatar,
      commit: _commitAvatar,
    ),
    SetupStepSpec(
      profileStepPaypalWanted,
      validate: (a) => a is bool ? null : 'answer is not yes or no',
      commit: _commitPaypalWanted,
    ),
    SetupStepSpec(
      profileStepPaypalMe,
      visibleWhen: (a) => a[profileStepPaypalWanted] == true,
      validate: _validatePaypalMe,
      commit: _commitPaypalMe,
    ),
    SetupStepSpec(
      profileStepBankWanted,
      validate: (a) => a is bool ? null : 'answer is not yes or no',
      commit: _commitBankWanted,
    ),
    SetupStepSpec(
      profileStepIban,
      visibleWhen: (a) => a[profileStepBankWanted] == true,
      validate: _validateIban,
      commit: _commitIban,
    ),
  ],
);

String? _validateName(Object answer) {
  if (answer is! String) return 'name is not text';
  final name = answer.trim();
  return name.isEmpty || name.length > 60 ? 'name must be 1..60 chars' : null;
}

String? _validateAvatar(Object answer) {
  if (answer is! Map) return 'avatar is not a map';
  final color = answer[profileAnswerColor];
  final emoji = answer[profileAnswerEmoji];
  return (color == null || color is int) && (emoji == null || emoji is String)
      ? null
      : 'avatar has the wrong shape';
}

String? _validatePaypalMe(Object answer) =>
    answer is String && PaypalMeHandle.parse(answer) is Ok
    ? null
    : 'not a PayPal.Me handle';

String? _validateIban(Object answer) {
  if (answer is! Map) return 'bank details are not a map';
  final iban = answer[profileAnswerIban];
  final holder = answer[profileAnswerHolder];
  if (iban is! String || normalizeIban(iban) is! Ok) return 'invalid IBAN';
  if (holder is! String || holder.trim().isEmpty) return 'holder is missing';
  return null;
}

/// Saves the profile with [change] applied to the stored one (name first:
/// creates it). [stored] is what the flow remembers on success.
Future<RepoResult<Object>> _editProfile(
  Ref ref,
  Object stored,
  UserProfile Function(UserProfile? current) change,
) async {
  final repo = ref.read(profileRepositoryProvider);
  final current = await repo.get();
  if (current is Err<UserProfile?, RepositoryError>) {
    return Err(current.error);
  }
  final base = (current as Ok<UserProfile?, RepositoryError>).value;
  final next = change(base);
  final saved = await repo.save(
    displayName: next.displayName,
    avatarColor: next.avatarColor,
    avatarEmoji: next.avatarEmoji,
    paypalMe: next.paypalMe,
  );
  return switch (saved) {
    Ok() => Ok(stored),
    Err(:final error) => Err(error),
  };
}

Future<RepoResult<Object>> _commitName(Ref ref, Object answer) {
  final name = (answer as String).trim();
  return _editProfile(
    ref,
    name,
    (p) => UserProfile(
      displayName: name,
      avatarColor: p?.avatarColor,
      avatarEmoji: p?.avatarEmoji,
      paypalMe: p?.paypalMe,
    ),
  );
}

/// The profile exists after the name step; without it the avatar has no
/// profile to belong to.
Future<RepoResult<Object>> _editExisting(
  Ref ref,
  Object stored,
  UserProfile Function(UserProfile current) change,
) async {
  final current = await ref.read(profileRepositoryProvider).get();
  return switch (current) {
    Err(:final error) => Err(error),
    Ok(value: null) => const Err(NotFound('profile', 'me')),
    Ok(:final value?) => _editProfile(ref, stored, (_) => change(value)),
  };
}

Future<RepoResult<Object>> _commitAvatar(Ref ref, Object answer) {
  final map = answer as Map;
  final color = map[profileAnswerColor] as int?;
  final emoji = map[profileAnswerEmoji] as String?;
  return _editExisting(
    ref,
    {profileAnswerColor: color, profileAnswerEmoji: emoji},
    (p) => UserProfile(
      displayName: p.displayName,
      avatarColor: color,
      avatarEmoji: emoji,
      paypalMe: p.paypalMe,
    ),
  );
}

/// "No" means no PayPal.Me: forget one entered earlier. "Yes" changes
/// nothing until the handle is given.
Future<RepoResult<Object>> _commitPaypalWanted(Ref ref, Object answer) {
  final wanted = answer as bool;
  if (wanted) return Future.value(const Ok(true));
  return _editExisting(
    ref,
    false,
    (p) => UserProfile(
      displayName: p.displayName,
      avatarColor: p.avatarColor,
      avatarEmoji: p.avatarEmoji,
    ),
  );
}

Future<RepoResult<Object>> _commitPaypalMe(Ref ref, Object answer) {
  final handle = (PaypalMeHandle.parse(
    answer as String,
  ) as Ok<PaypalMeHandle, PayPalError>).value.value;
  return _editExisting(
    ref,
    handle,
    (p) => UserProfile(
      displayName: p.displayName,
      avatarColor: p.avatarColor,
      avatarEmoji: p.avatarEmoji,
      paypalMe: handle,
    ),
  );
}

/// "No" means no bank transfer: forget an IBAN entered earlier.
Future<RepoResult<Object>> _commitBankWanted(Ref ref, Object answer) async {
  final wanted = answer as bool;
  if (wanted) return const Ok(true);
  final cleared = await ref.read(profileBankRepositoryProvider).clear();
  return switch (cleared) {
    Ok() => const Ok(false),
    Err(:final error) => Err(error),
  };
}

Future<RepoResult<Object>> _commitIban(Ref ref, Object answer) async {
  final map = answer as Map;
  final saved = await ref
      .read(profileBankRepositoryProvider)
      .save(
        iban: map[profileAnswerIban]! as String,
        accountName: (map[profileAnswerHolder]! as String).trim(),
      );
  return switch (saved) {
    Ok() => const Ok(profileIbanStored),
    Err(:final error) => Err(error),
  };
}

/// What [ProfileSetupViewModel.openPaypalLink] did.
enum PaypalLinkOutcome { opened, copied, invalid }

/// The commands of the profile flow's screens that are not "answer a step":
/// test or create a PayPal.Me link, paste, read the stored IBAN back.
class ProfileSetupViewModel {
  const ProfileSetupViewModel({required this.links, required this.bank});

  final ProfileLinksRepository links;
  final ProfileBankRepository bank;

  /// "Link testen": opens the link of [handle] (any accepted form).
  Future<PaypalLinkOutcome> openPaypalLink(String handle) async {
    final parsed = PaypalMeHandle.parse(handle);
    if (parsed is! Ok<PaypalMeHandle, PayPalError>) {
      return PaypalLinkOutcome.invalid;
    }
    final uri = parsed.value.link();
    if (uri is! Ok<Uri, PayPalError>) return PaypalLinkOutcome.invalid;
    return await links.open(uri.value)
        ? PaypalLinkOutcome.opened
        : PaypalLinkOutcome.copied;
  }

  /// "Noch kein PayPal.Me? Jetzt erstellen". False means the link was
  /// copied instead.
  Future<bool> openCreatePaypalMe() =>
      links.open(ProfileLinksRepository.createPaypalMeUri);

  /// "Einfügen": the clipboard text, null if there is none.
  Future<String?> paste() => links.pasteText();

  /// The stored bank details, to fill the IBAN step when coming back to it.
  Future<RepoResult<ProfileBank?>> storedBank() => bank.get();
}

final profileSetupViewModelProvider = Provider<ProfileSetupViewModel>(
  (ref) => ProfileSetupViewModel(
    links: ref.watch(profileLinksRepositoryProvider),
    bank: ref.watch(profileBankRepositoryProvider),
  ),
);

/// What the profile card shows. The IBAN is never in here, only its last
/// four characters.
final class ProfileCardData {
  const ProfileCardData({required this.profile, this.ibanTail});

  final UserProfile profile;
  final String? ibanTail;
}

/// The saved profile for the card on the finish screen; null while there is
/// none.
final FutureProvider<RepoResult<ProfileCardData?>> profileCardProvider =
    FutureProvider.autoDispose<RepoResult<ProfileCardData?>>((ref) async {
      final profile = await ref.watch(profileRepositoryProvider).get();
      if (profile is Err<UserProfile?, RepositoryError>) {
        return Err(profile.error);
      }
      final saved = (profile as Ok<UserProfile?, RepositoryError>).value;
      if (saved == null) return const Ok(null);
      final bank = await ref.watch(profileBankRepositoryProvider).get();
      return switch (bank) {
        Err(:final error) => Err(error),
        Ok(:final value) => Ok(
          ProfileCardData(
            profile: saved,
            ibanTail: value?.iban.substring(value.iban.length - 4),
          ),
        ),
      };
    });
