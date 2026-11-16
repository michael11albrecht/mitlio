import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/settings/data/repositories/legal_links_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';

/// Public origin of the website. Keep in sync with `web/site.config.mjs`;
/// override at build time with `--dart-define=SITE_URL=...`.
const siteUrl = String.fromEnvironment(
  'SITE_URL',
  defaultValue: 'https://mitlio.web.app',
);

/// Override in tests with a fake launcher via `linkLauncherProvider`.
final legalLinksRepositoryProvider = Provider<LegalLinksRepository>(
  (ref) => LegalLinksRepository(
    launcher: ref.watch(linkLauncherProvider),
    siteUrl: siteUrl,
  ),
);
