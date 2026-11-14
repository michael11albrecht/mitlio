import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/features/balances/ui/balances_view.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/groups/ui/group_form_view.dart';
import 'package:mitlio/features/groups/ui/groups_view.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view.dart';
import 'package:mitlio/features/rides/ui/template_form_view.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view.dart';
import 'package:mitlio/features/settle/ui/settle_view.dart';
import 'package:mitlio/features/statistics/ui/statistics_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart'
    show standaloneTripGroupId;

/// App routes: home is the group list. Detail and edit nest under it, so
/// back always returns to the list.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
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
            path: 'groups/new',
            builder: (context, state) => const GroupFormView(),
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
