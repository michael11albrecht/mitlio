import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/routes/ui/route_distance_view_model.dart';

/// `ext.mitlio.route.*`: the "Strecke berechnen" commands of the ride and
/// trip forms (keys without the `ext.mitlio.` prefix), through the same
/// [RouteDistanceViewModel] the forms use. The ViewModel is kept alive between
/// calls so a scenario can pick places, edit the kilometres and pick again;
/// `route.reset` starts over.
Map<String, DriveHandler> routeDriveHandlers(ProviderContainer c) {
  ProviderSubscription<RouteDistanceState>? keep;
  RouteDistanceViewModel vm() {
    keep ??= c.listen(routeDistanceViewModelProvider, (_, _) {});
    return c.read(routeDistanceViewModelProvider.notifier);
  }

  DriveResult snapshot(RouteDistanceViewModel model) => {
    ...model.debugSnapshot(),
    'fillMeters': model.current.fill?.meters,
  };

  PlaceSuggestion? place(Map<String, String> p, String prefix) {
    final label = p['${prefix}Label'];
    final lat = double.tryParse(p['${prefix}Lat'] ?? '');
    final lng = double.tryParse(p['${prefix}Lng'] ?? '');
    if (label == null || label.isEmpty || lat == null || lng == null) {
      return null;
    }
    return PlaceSuggestion(label: label, lat: lat, lng: lng);
  }

  return {
    'route.suggest': (p) async {
      final text = p['text'];
      final field = RouteField.values.asNameMap()[p['field'] ?? 'start'];
      if (text == null || field == null) {
        return invalidParams('params text and field (start or end)');
      }
      final model = vm();
      await model.search(field, text, lang: p['lang'] ?? 'de');
      final s = model.current;
      return {
        'suggestions': [
          for (final x in s.suggestions)
            {'label': x.label, 'lat': x.lat, 'lng': x.lng},
        ],
        'failure': s.failure?.name,
        'retryAfterMinutes': s.retryAfter?.inMinutes,
        'attribution': s.attribution,
        'available': s.available,
      };
    },
    'route.distance': (p) async {
      final from = place(p, 'from');
      final to = place(p, 'to');
      if (from == null || to == null) {
        return invalidParams(
          'params fromLabel/fromLat/fromLng and toLabel/toLat/toLng',
        );
      }
      final model = vm();
      await model.pick(RouteField.start, from);
      await model.pick(RouteField.end, to);
      return snapshot(model);
    },
    'route.manualEdit': (_) async {
      final model = vm()..noteManualEdit();
      return snapshot(model);
    },
    'route.recalculate': (_) async {
      final model = vm();
      await model.recalculate();
      return snapshot(model);
    },
    'route.reset': (_) async {
      keep?.close();
      keep = null;
      // Let the auto-dispose provider actually dispose before the next use.
      await Future<void>.delayed(Duration.zero);
      return {'ok': true};
    },
  };
}
