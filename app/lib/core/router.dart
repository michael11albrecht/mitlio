import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/core/crash/route_breadcrumbs.dart';
import 'package:mitlio/core/keyboard.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view.dart';
import 'package:mitlio/features/groups/ui/archived_groups_view.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/groups/ui/group_form_view.dart';
import 'package:mitlio/features/groups/ui/groups_view.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/template_form_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view.dart';
import 'package:mitlio/features/settings/ui/delete_my_data_view.dart';
import 'package:mitlio/features/settings/ui/licenses_view.dart';
import 'package:mitlio/features/settings/ui/settings_view.dart';
import 'package:mitlio/features/settle/ui/settle_view.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';
import 'package:mitlio/features/sync/data/invite_link.dart';
import 'package:mitlio/features/sync/ui/join_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart'
    show standaloneTripGroupId;

/// App routes: home is the group list. Detail and edit nest under it, so
/// back always returns to the list.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    observers: [
      RouteBreadcrumbObserver(ref.watch(crashReporterProvider)),
      KeyboardDismissObserver(),
    ],
    // `mitlio://join/<token>` arrives with the token as the path and "join" as
    // the host; the https app link already matches `/join/:token`.
    redirect: (context, state) => inviteLocationFor(state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const GroupsView(),
        routes: [
          GoRoute(
            path: 'welcome',
            builder: (context, state) => const OnboardingView(),
          ),
          // The trip calculator without a group (first run).
          GoRoute(
            path: 'trip',
            builder: (context, state) =>
                const TripFormView(groupId: standaloneTripGroupId),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsView(),
            routes: [
              GoRoute(
                path: 'delete-data',
                builder: (context, state) => const DeleteMyDataView(),
              ),
              GoRoute(
                path: 'licenses',
                builder: (context, state) => const LicensesView(),
              ),
            ],
          ),
          // Invite link (app links, `mitlio://join/<token>` and DebugDrive land here). Unnamed
          // on purpose: the token is a secret and must not reach breadcrumbs.
          GoRoute(
            path: 'join/:token',
            builder: (context, state) =>
                JoinView(token: state.pathParameters['token']!),
          ),
          GoRoute(
            path: 'groups/new',
            builder: (context, state) => const GroupFormView(),
          ),
          GoRoute(
            path: 'groups/archived',
            builder: (context, state) => const ArchivedGroupsView(),
          ),
          GoRoute(
            path: 'groups/:id',
            builder: (context, state) => GroupDetailView(
              groupId: state.pathParameters['id']!,
              initialTab: state.uri.queryParameters['tab'],
            ),
            routes: [
              GoRoute(
                path: 'balances',
                builder: (context, state) =>
                    BalancesView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'statistics',
                builder: (context, state) =>
                    StatisticsView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'settle',
                builder: (context, state) =>
                    SettleView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    GroupFormView(groupId: state.pathParameters['id']),
              ),
              GoRoute(
                path: 'rides/settings',
                builder: (context, state) =>
                    RidesSetupView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'rides/vehicles/new',
                builder: (context, state) => VehicleFormView(
                  groupId: state.pathParameters['id']!,
                  thenTemplate: state.uri.queryParameters['next'] == 'template',
                ),
              ),
              GoRoute(
                path: 'rides/vehicles/:vehicleId',
                builder: (context, state) => VehicleFormView(
                  groupId: state.pathParameters['id']!,
                  vehicleId: state.pathParameters['vehicleId'],
                ),
              ),
              GoRoute(
                path: 'rides/templates/new',
                builder: (context, state) =>
                    TemplateFormView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'rides/templates/:templateId',
                builder: (context, state) => TemplateFormView(
                  groupId: state.pathParameters['id']!,
                  templateId: state.pathParameters['templateId'],
                ),
              ),
              GoRoute(
                path: 'expenses/new',
                builder: (context, state) =>
                    ExpenseFormView(groupId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'expenses/:expenseId',
                builder: (context, state) => ExpenseFormView(
                  groupId: state.pathParameters['id']!,
                  expenseId: state.pathParameters['expenseId'],
                ),
              ),
              GoRoute(
                path: 'trip',
                builder: (context, state) =>
                    TripFormView(groupId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
