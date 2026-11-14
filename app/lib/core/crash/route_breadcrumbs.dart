import 'package:flutter/widgets.dart';
import 'package:mitlio/core/crash/crash_reporter.dart';

/// Navigation breadcrumbs for crash reports: the route template (for example
/// `groups/:id`), never the concrete location, so no ids or text.
class RouteBreadcrumbObserver extends NavigatorObserver {
  RouteBreadcrumbObserver(this.reporter);

  final CrashReporter reporter;

  void _report(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) reporter.breadcrumb('navigation', name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _report(newRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _report(previousRoute);
}
