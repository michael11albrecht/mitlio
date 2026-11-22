import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/support/data/repositories/support_repository.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio/features/support/ui/support_prompt_view_model.dart';
import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.support.*` (P7-T09, ADR-28; keys without the `ext.mitlio.`
/// prefix): the tip jar through the same ViewModel and repository calls the
/// screens use.
///
/// - `support.state`: the flag and the success-screen line's local state.
/// - `support.setFlag` `{enabled}`: stands in for the owner flipping
///   `app_config.support_tips_enabled`; writes the flag cache the repository
///   trusts for 12 hours.
/// - `support.setPrompt` `{settled?, lastShownDaysAgo?, dismissed?}`: scripts
///   the local state (counter, last shown, dismissed).
/// - `support.reached`: one visit of the "all settled" screen.
/// - `support.dismiss`: "Nicht mehr zeigen".
/// - `support.tips` / `support.tip` `{size}`: load the sizes, buy one.
Map<String, DriveHandler> supportDriveHandlers(ProviderContainer c) => {
  'support.state': (_) => _state(c),
  'support.setFlag': (p) => _setFlag(c, p),
  'support.setPrompt': (p) => _setPrompt(c, p),
  'support.reached': (_) => _reached(c),
  'support.dismiss': (_) => _dismiss(c),
  'support.tips': (_) => _tips(c),
  'support.tip': (p) => _tip(c, p),
};

Future<DriveResult> _state(ProviderContainer c) async {
  final repo = c.read(supportRepositoryProvider);
  final prompt = await repo.promptState();
  return {
    'enabled': await repo.tipsEnabled(),
    ...switch (prompt) {
      Ok(:final value) => {
        'settledSinceShown': value.settledSinceShown,
        'lastShown': value.lastShown?.toUtc().toIso8601String(),
        'dismissed': value.dismissed,
      },
      Err(:final error) => {'error': 'internal', 'message': '$error'},
    },
  };
}

Future<DriveResult> _setFlag(ProviderContainer c, Map<String, String> p) async {
  final enabled = switch (p['enabled']) {
    'true' => true,
    'false' => false,
    _ => null,
  };
  if (enabled == null) return invalidParams('param enabled must be true|false');
  final dao = c.read(appDatabaseProvider).syncStateDao;
  await dao.putSetting(supportFlagSetting, enabled ? '1' : '0');
  await dao.putSetting(
    supportFlagCheckedAtSetting,
    c.read(clockProvider).now().toUtc().toIso8601String(),
  );
  return {'enabled': enabled};
}

Future<DriveResult> _setPrompt(
  ProviderContainer c,
  Map<String, String> p,
) async {
  final settled = p['settled'] == null ? null : int.tryParse(p['settled']!);
  final days = p['lastShownDaysAgo'] == null
      ? null
      : int.tryParse(p['lastShownDaysAgo']!);
  if ((p['settled'] != null && settled == null) ||
      (p['lastShownDaysAgo'] != null && days == null)) {
    return invalidParams('settled and lastShownDaysAgo must be integers');
  }
  final repo = c.read(supportRepositoryProvider);
  final current = switch (await repo.promptState()) {
    Ok(:final value) => value,
    Err() => const SupportPromptState(),
  };
  final now = c.read(clockProvider).now();
  final next = SupportPromptState(
    settledSinceShown: settled ?? current.settledSinceShown,
    lastShown: days == null
        ? current.lastShown
        : now.subtract(Duration(days: days)),
    dismissed: p['dismissed'] == null
        ? current.dismissed
        : p['dismissed'] == 'true',
  );
  return switch (await repo.savePromptState(next)) {
    Ok() => _state(c),
    Err(:final error) => driveError(error),
  };
}

Future<DriveResult> _reached(ProviderContainer c) async {
  // Keeps the autoDispose ViewModel alive while it decides.
  final sub = c.listen(supportPromptViewModelProvider, (_, _) {});
  try {
    await c
        .read(supportPromptViewModelProvider.notifier)
        .settledScreenReached();
    return {'visible': c.read(supportPromptViewModelProvider)};
  } finally {
    sub.close();
  }
}

Future<DriveResult> _dismiss(ProviderContainer c) async {
  final sub = c.listen(supportPromptViewModelProvider, (_, _) {});
  try {
    return switch (await c
        .read(supportPromptViewModelProvider.notifier)
        .dismissForever()) {
      Ok() => {'dismissed': true},
      Err(:final error) => driveError(error),
    };
  } finally {
    sub.close();
  }
}

DriveResult _jar(TipJarState s) => switch (s) {
  TipJarLoading() => {'state': 'loading'},
  TipJarUnavailable(:final failure) => {
    'state': 'unavailable',
    'error': failure.name,
  },
  TipJarReady(:final products, :final buying, :final error) => {
    'state': 'ready',
    'products': [
      for (final p in products) {'size': p.size.name, 'price': p.price},
    ],
    'buying': buying?.name,
    'error': error?.name,
  },
  TipJarThanks() => {'state': 'thanks'},
};

Future<DriveResult> _tips(ProviderContainer c) async {
  final sub = c.listen(tipJarViewModelProvider, (_, _) {});
  try {
    await c.read(tipJarViewModelProvider.notifier).load();
    return _jar(c.read(tipJarViewModelProvider));
  } finally {
    sub.close();
  }
}

Future<DriveResult> _tip(ProviderContainer c, Map<String, String> p) async {
  final size = TipSize.values.asNameMap()[p['size']];
  if (size == null) {
    return invalidParams('param size must be one of small|medium|large');
  }
  final sub = c.listen(tipJarViewModelProvider, (_, _) {});
  try {
    final vm = c.read(tipJarViewModelProvider.notifier);
    await vm.load();
    await vm.tip(size);
    return _jar(c.read(tipJarViewModelProvider));
  } finally {
    sub.close();
  }
}
