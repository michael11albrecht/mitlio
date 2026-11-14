import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitlio/features/groups/ui/group_detail_view.dart';
import 'package:mitlio/features/groups/ui/group_form_view.dart';
import 'package:mitlio/features/groups/ui/groups_view.dart';

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
            path: 'groups/new',
            builder: (context, state) => const GroupFormView(),
          ),
          GoRoute(
            path: 'groups/:id',
            builder: (context, state) =>
                GroupDetailView(groupId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    GroupFormView(groupId: state.pathParameters['id']),
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
