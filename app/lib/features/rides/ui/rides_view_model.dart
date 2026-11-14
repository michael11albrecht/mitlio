import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/rides/data/repositories/rides_providers.dart';
import 'package:mitlio/features/rides/data/repositories/rides_repository.dart';
import 'package:mitlio/features/rides/ui/rides_calculator.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The Views name the stored ride type; they may not import data/ themselves.
export 'package:mitlio/features/members/data/repositories/members_repository.dart'
    show GroupMember;
export 'package:mitlio/features/rides/data/repositories/rides_repository.dart'
    show RideEntry;

/// `YYYY-MM-DD` of the UTC calendar day (the form that DebugDrive speaks).
String rideDayKey(DateTime date) {
  final d = date.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Every ride, whatever its date: one query backs the calendar, the list and
/// the fair-driver suggestion (a commuter group logs a few hundred a year).
final _everything = Custom(DateTime.utc(2000), DateTime.utc(2100));

/// The "Heute gefahren" card: everything derived for the next ride. The
/// user's overrides live in the ViewModel; this is what they add up to.
final class QuickLog {
  const QuickLog({
    required this.template,
    required this.vehicle,
    required this.driverId,
    required this.passengerIds,
    required this.priceMilli,
    required this.date,
    required this.isToday,
    required this.preview,
    required this.collapsed,
    required this.saving,
  });

  /// Null while several templates exist and none was picked (the one tap
  /// that cannot be defaulted).
  final RideTemplate? template;
  final Vehicle? vehicle;
  final String? driverId;
  final Set<String> passengerIds;

  /// Fuel price per litre or kWh in thousandths.
  final int priceMilli;

  /// Midnight UTC of the day the ride is logged for.
  final DateTime date;
  final bool isToday;

  /// What the ride would cost, live; null until it is valid.
  final RideSummary? preview;

  /// Today already has a ride: show the calm "done" state, not the form.
  final bool collapsed;
  final bool saving;

  bool get usesKmRate => vehicle?.kmRateMilliPerKm != null;

  bool get canSave =>
      template != null && driverId != null && preview != null && !saving;
}

sealed class RidesState {
  const RidesState();
}

final class RidesLoading extends RidesState {
  const RidesLoading();
}

final class RidesFailure extends RidesState {
  const RidesFailure(this.error);

  final RepositoryError error;
}

final class RidesLoaded extends RidesState {
  const RidesLoaded({
    required this.group,
    required this.members,
    required this.vehicles,
    required this.templates,
    required this.entries,
    required this.month,
    required this.today,
    required this.quick,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;
  final List<Vehicle> vehicles;
  final List<RideTemplate> templates;

  /// Every live ride, by date and id.
  final List<RideEntry> entries;

  /// The month the calendar and the list show.
  final Month month;

  /// Midnight UTC of the current day (from the injected clock).
  final DateTime today;

  /// Null while there is no template to log with.
  final QuickLog? quick;

  /// Nothing to log with yet: the first-run state.
  bool get isOnboarding => templates.isEmpty;

  bool get hasMembers => members.isNotEmpty;

  List<RideEntry> get monthEntries => [
    for (final e in entries)
      if (month.contains(e.ride.date)) e,
  ];

  List<RideEntry> entriesOn(DateTime day) => [
    for (final e in entries)
      if (Day(day).contains(e.ride.date)) e,
  ];

  /// Drivers of [day], first to last, each once.
  List<String> driversOn(DateTime day) => [
    ...{for (final e in entriesOn(day)) e.ride.driverId},
  ];

  GroupMember? member(String id) =>
      members.where((m) => m.id == id).firstOrNull;

  Vehicle? vehicle(String id) => vehicles.where((v) => v.id == id).firstOrNull;

  /// Total and per-passenger amounts of [entry]; null if its vehicle is gone
  /// or the domain rejects it.
  RideSummary? summary(RideEntry entry) {
    final v = vehicle(entry.ride.vehicleId);
    return v == null
        ? null
        : summarizeRide(entry.ride, v, group.currency, [
            for (final m in members) m.toDomain(),
          ]);
  }
}

/// A ride that was just saved: what to tell the user and how to take it
/// back.
final class LoggedRide {
  const LoggedRide({
    required this.entry,
    required this.currency,
    required this.driverName,
    required this.totalCents,
    required this.owes,
    required this.undo,
  });

  final RideEntry entry;
  final Currency currency;
  final String driverName;
  final int totalCents;

  /// Passengers (name, cents) in member order.
  final List<({String name, int cents})> owes;

  /// Deletes the ride again.
  final Undo undo;
}

/// Group detail, rides tab: the calendar, the month's list and the quick log
/// ("Heute gefahren"). `logRide` is the one command behind the card's save
/// button and `ext.mitlio.rides.log`.
class RidesViewModel extends Notifier<RidesState> {
  RidesViewModel(this.groupId);

  final String groupId;

  Group? _group;
  var _groupKnown = false;
  List<GroupMember>? _members;
  List<Vehicle>? _vehicles;
  List<RideTemplate>? _templates;
  List<RideEntry>? _entries;
  RepositoryError? _failure;
  Month? _month;

  // The user's overrides of the quick log; null means "use the default".
  String? _templateId;
  String? _driverId;
  Set<String>? _passengerIds;
  int? _priceMilli;
  DateTime? _date;
  var _expanded = false;
  var _saving = false;

  /// Deleted by the user and gone from the list at once; kept until the
  /// repository stream confirms, or the delete fails.
  final _hidden = <String>{};

  @override
  RidesState build() {
    _group = null;
    _groupKnown = false;
    _members = null;
    _vehicles = null;
    _templates = null;
    _entries = null;
    _failure = null;
    _hidden.clear();
    final subs = [
      _listen(ref.watch(groupsRepositoryProvider).watchGroups(), (groups) {
        _group = groups.where((g) => g.id == groupId).firstOrNull;
        _groupKnown = true;
      }),
      _listen(
        ref.watch(membersRepositoryProvider).watchMembers(groupId),
        (members) => _members = members,
      ),
      _listen(
        ref.watch(vehiclesRepositoryProvider).watchVehicles(groupId),
        (vehicles) => _vehicles = vehicles,
      ),
      _listen(
        ref.watch(rideTemplatesRepositoryProvider).watchTemplates(groupId),
        (templates) => _templates = templates,
      ),
      _listen(
        ref.watch(ridesRepositoryProvider).watchRides(groupId, _everything),
        (entries) {
          _entries = entries;
          _hidden.retainAll({for (final e in entries) e.ride.id});
        },
      ),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        unawaited(s.cancel());
      }
    });
    return const RidesLoading();
  }

  StreamSubscription<T> _listen<T>(Stream<T> stream, void Function(T) onData) =>
      stream.listen(
        (data) {
          onData(data);
          _emit();
        },
        onError: (Object e) {
          _failure = e is RepositoryError ? e : Storage(e);
          _emit();
        },
      );

  void _emit() {
    if (!ref.mounted) return;
    final members = _members;
    final vehicles = _vehicles;
    final templates = _templates;
    final entries = _entries;
    if (_failure != null) {
      state = RidesFailure(_failure!);
    } else if (!_groupKnown ||
        members == null ||
        vehicles == null ||
        templates == null ||
        entries == null) {
      state = const RidesLoading();
    } else if (_group == null) {
      state = RidesFailure(NotFound('group', groupId));
    } else {
      final now = ref.read(clockProvider).now();
      final today = DateTime.utc(now.year, now.month, now.day);
      final live = [
        for (final e in entries)
          if (!_hidden.contains(e.ride.id)) e,
      ];
      state = RidesLoaded(
        group: _group!,
        members: members,
        vehicles: vehicles,
        templates: templates,
        entries: live,
        month: _month ?? Month(today.year, today.month),
        today: today,
        quick: _quick(
          group: _group!,
          members: members,
          vehicles: vehicles,
          templates: templates,
          entries: live,
          today: today,
        ),
      );
    }
  }

  QuickLog? _quick({
    required Group group,
    required List<GroupMember> members,
    required List<Vehicle> vehicles,
    required List<RideTemplate> templates,
    required List<RideEntry> entries,
    required DateTime today,
  }) {
    if (templates.isEmpty || members.isEmpty) return null;
    final picked = templates.where((t) => t.id == _templateId).firstOrNull;
    final template = picked ?? (templates.length == 1 ? templates.first : null);
    final date = _date ?? today;
    final isToday = date == today;
    final collapsed =
        isToday &&
        !_expanded &&
        entries.any((e) => Day(today).contains(e.ride.date));
    final rides = [for (final e in entries) e.ride];
    final vehicle = template == null
        ? null
        : vehicles.where((v) => v.id == template.vehicleId).firstOrNull;
    final ids = [for (final m in members) m.id];
    final driver = template == null
        ? null
        : (_driverId != null && ids.contains(_driverId))
        ? _driverId
        : suggestDriver(
            members: ids,
            template: template,
            history: rides,
            unsettled: [
              for (final e in entries)
                if (!e.isSettled) e.ride,
            ],
          );
    final passengers = template == null || driver == null
        ? const <String>{}
        : {
            for (final id
                in _passengerIds ?? defaultPassengers(template, driver))
              if (id != driver && ids.contains(id)) id,
          };
    final price =
        _priceMilli ??
        (vehicle == null ? 0 : suggestedPriceMilli(vehicle, rides));
    RideSummary? preview;
    if (template != null && vehicle != null && driver != null) {
      preview = summarizeRide(
        _rideOf(
          id: 'preview',
          template: template,
          vehicle: vehicle,
          driverId: driver,
          passengerIds: passengers,
          date: date,
          priceMilli: price,
        ),
        vehicle,
        group.currency,
        [for (final m in members) m.toDomain()],
      );
    }
    return QuickLog(
      template: template,
      vehicle: vehicle,
      driverId: driver,
      passengerIds: passengers,
      priceMilli: price,
      date: date,
      isToday: isToday,
      preview: preview,
      collapsed: collapsed,
      saving: _saving,
    );
  }

  Ride _rideOf({
    required String id,
    required RideTemplate template,
    required Vehicle vehicle,
    required String driverId,
    required Set<String> passengerIds,
    required DateTime date,
    required int priceMilli,
  }) => Ride(
    id: id,
    date: date,
    distanceMeters: template.distanceMeters,
    roundTrip: template.roundTrip,
    tollsCents: template.tollsCents,
    vehicleId: vehicle.id,
    driverId: driverId,
    passengerIds: passengerIds,
    pricePerUnitMilli: priceMilli,
    useKmRate: vehicle.kmRateMilliPerKm != null,
  );

  void retry() {
    state = const RidesLoading();
    ref.invalidateSelf();
  }

  // --- calendar ---

  /// Moves the calendar by [months] (negative goes back).
  void shiftMonth(int months) {
    final current = switch (state) {
      RidesLoaded(:final month) => month,
      _ => _month,
    };
    if (current == null) return;
    final index = current.year * 12 + (current.month - 1) + months;
    _month = Month(index ~/ 12, index % 12 + 1);
    _emit();
  }

  // --- quick log ---

  /// Picks the template (needed when there are several).
  void selectTemplate(String id) {
    _templateId = id;
    _driverId = null;
    _passengerIds = null;
    _priceMilli = null;
    _emit();
  }

  /// Picks the driver; the carpool follows (the previous driver rides
  /// along) unless the passengers were chosen by hand.
  void selectDriver(String id) {
    _driverId = id;
    _passengerIds = null;
    _emit();
  }

  /// Toggles [id] among the passengers.
  void togglePassenger(String id) {
    final quick = switch (state) {
      RidesLoaded(:final quick) => quick,
      _ => null,
    };
    if (quick == null) return;
    final next = {...quick.passengerIds};
    if (!next.remove(id)) next.add(id);
    _passengerIds = next;
    _emit();
  }

  /// Overrides the frozen fuel price (thousandths); null goes back to the
  /// suggestion.
  void setPrice(int? milli) {
    _priceMilli = milli;
    _emit();
  }

  /// Logs for [day] instead of today; null goes back to today.
  void setDate(DateTime? day) {
    _date = day == null ? null : DateTime.utc(day.year, day.month, day.day);
    _expanded = false;
    _emit();
  }

  /// Reopens the card after today's ride was saved ("Weitere Fahrt").
  void expand() {
    _expanded = true;
    _emit();
  }

  /// Saves the ride the card shows.
  Future<RepoResult<LoggedRide>> saveQuickLog() async {
    final quick = switch (state) {
      RidesLoaded(:final quick) => quick,
      _ => null,
    };
    final template = quick?.template;
    final driver = quick?.driverId;
    if (quick == null || template == null || driver == null) {
      return const Err(InvalidData('pick a template and a driver'));
    }
    _saving = true;
    _emit();
    final result = await logRide(
      templateId: template.id,
      driverId: driver,
      passengerIds: quick.passengerIds,
      date: quick.date,
      priceMilli: quick.priceMilli,
    );
    _saving = false;
    if (result is Ok) {
      // A fresh start for the next ride; today now has one, so the card
      // collapses (unless it was a backdated ride).
      _templateId = null;
      _driverId = null;
      _passengerIds = null;
      _priceMilli = null;
      _date = null;
      _expanded = false;
    }
    _emit();
    return result;
  }

  /// Logs one ride. Template (or vehicle and distance), driver, passengers
  /// and price default exactly like the card does. Reads the repositories
  /// directly, so it works before the screen has loaded (DebugDrive).
  Future<RepoResult<LoggedRide>> logRide({
    required String driverId,
    String? templateId,
    String? vehicleId,
    int? distanceMeters,
    bool roundTrip = false,
    int tollsCents = 0,
    Set<String>? passengerIds,
    DateTime? date,
    int? priceMilli,
  }) async {
    try {
      return await _logRide(
        driverId: driverId,
        templateId: templateId,
        vehicleId: vehicleId,
        distanceMeters: distanceMeters,
        roundTrip: roundTrip,
        tollsCents: tollsCents,
        passengerIds: passengerIds,
        date: date,
        priceMilli: priceMilli,
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  Future<RepoResult<LoggedRide>> _logRide({
    required String driverId,
    String? templateId,
    String? vehicleId,
    int? distanceMeters,
    bool roundTrip = false,
    int tollsCents = 0,
    Set<String>? passengerIds,
    DateTime? date,
    int? priceMilli,
  }) async {
    final templates = ref.read(rideTemplatesRepositoryProvider);
    final vehicles = ref.read(vehiclesRepositoryProvider);
    final rides = ref.read(ridesRepositoryProvider);

    RideTemplate template;
    if (templateId != null) {
      final got = await templates.get(templateId);
      if (got case Err(:final error)) return Err(error);
      template = (got as Ok<RideTemplate, RepositoryError>).value;
    } else if (vehicleId != null && distanceMeters != null) {
      template = RideTemplate(
        id: '',
        name: '',
        distanceMeters: distanceMeters,
        vehicleId: vehicleId,
        roundTrip: roundTrip,
        tollsCents: tollsCents,
      );
    } else {
      return const Err(InvalidData('need a template or vehicle and distance'));
    }
    final vehicleResult = await vehicles.get(template.vehicleId);
    if (vehicleResult case Err(:final error)) return Err(error);
    final vehicle = (vehicleResult as Ok<Vehicle, RepositoryError>).value;
    final groupResult = await ref.read(groupsRepositoryProvider).get(groupId);
    if (groupResult case Err(:final error)) return Err(error);
    final group = (groupResult as Ok<Group, RepositoryError>).value;
    final members = (await ref.read(membersRepositoryProvider).list(groupId))
        .orThrow();
    final history = [
      for (final e in await rides.watchRides(groupId, _everything).first)
        e.ride,
    ];

    final now = ref.read(clockProvider).now();
    final day = date ?? now;
    final ride = _rideOf(
      id: ref.read(idGeneratorProvider).newId(),
      template: template,
      vehicle: vehicle,
      driverId: driverId,
      passengerIds: passengerIds ?? defaultPassengers(template, driverId),
      date: DateTime.utc(day.year, day.month, day.day),
      priceMilli: priceMilli ?? suggestedPriceMilli(vehicle, history),
    );
    final domainMembers = [for (final m in members) m.toDomain()];
    final cost = rideCost(ride, vehicle, group.currency, domainMembers);
    if (cost case Err(:final error)) {
      return Err(InvalidData('ride rejected: $error'));
    }
    final stored = await rides.log(groupId, ride);
    if (stored case Err(:final error)) return Err(error);
    final entry = (stored as Ok<RideEntry, RepositoryError>).value;
    final summary = summarizeRide(
      ride,
      vehicle,
      group.currency,
      domainMembers,
    )!;
    String nameOf(String id) =>
        members.where((m) => m.id == id).firstOrNull?.name ?? '';
    return Ok(
      LoggedRide(
        entry: entry,
        currency: group.currency,
        driverName: nameOf(driverId),
        totalCents: summary.totalCents,
        owes: [
          for (final s in summary.owes)
            (name: nameOf(s.memberId), cents: s.cents),
        ],
        undo: Undo(() async {
          final deleted = await rides.softDelete(ride.id);
          return switch (deleted) {
            Ok() => const Ok<void, RepositoryError>(null),
            Err(:final error) => Err<void, RepositoryError>(error),
          };
        }),
      ),
    );
  }

  // --- list ---

  /// Soft delete; the returned [Undo] brings the ride back. The row
  /// disappears at once and comes back if the repository refuses ([Locked]
  /// for rides of a settled period).
  Future<RepoResult<Undo>> deleteRide(String id) async {
    _hidden.add(id);
    _emit();
    final result = await ref.read(ridesRepositoryProvider).softDelete(id);
    if (result is Err) {
      _hidden.remove(id);
      _emit();
    }
    return result;
  }

  /// The rides of [month] as of now (for DebugDrive; the UI watches the
  /// state).
  Future<RepoResult<List<RideEntry>>> list(Month month) async {
    try {
      return Ok(
        await ref
            .read(ridesRepositoryProvider)
            .watchRides(groupId, month)
            .first,
      );
    } on Object catch (e) {
      return Err(e is RepositoryError ? e : Storage(e));
    }
  }

  JsonMap debugSnapshot() => switch (state) {
    RidesLoading() => {'status': 'loading', 'groupId': groupId},
    RidesFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    RidesLoaded(
      :final group,
      :final month,
      :final monthEntries,
      :final quick,
      :final templates,
      :final vehicles,
      :final isOnboarding,
    ) =>
      {
        'status': isOnboarding ? 'empty' : 'data',
        'groupId': group.id,
        'currency': group.currency.code,
        'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
        'vehicles': vehicles.length,
        'templates': templates.length,
        'rides': [for (final e in monthEntries) rideJson(e)],
        'quick': quick == null
            ? null
            : {
                'templateId': quick.template?.id,
                'driverId': quick.driverId,
                'passengerIds': quick.passengerIds.toList()..sort(),
                'priceMilli': quick.priceMilli,
                'date': rideDayKey(quick.date),
                'collapsed': quick.collapsed,
                'canSave': quick.canSave,
              },
      },
  };
}

/// JSON shape of a ride in snapshots and DebugDrive results.
JsonMap rideJson(RideEntry e) => {
  'id': e.ride.id,
  'date': rideDayKey(e.ride.date),
  'distanceMeters': e.ride.distanceMeters,
  'roundTrip': e.ride.roundTrip,
  'tollsCents': e.ride.tollsCents,
  'vehicleId': e.ride.vehicleId,
  'driverId': e.ride.driverId,
  'passengerIds': e.ride.passengerIds.toList()..sort(),
  'priceMilli': e.ride.pricePerUnitMilli,
  'useKmRate': e.ride.useKmRate,
  'locked': e.isSettled,
};

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final ridesViewModelProvider =
    NotifierProvider.family<RidesViewModel, RidesState, String>(
      RidesViewModel.new,
    );

/// Whether a group has a ride template: the home screen offers its
/// "Heute gefahren" shortcut only then.
// ignore: specify_nonobvious_property_types, the family provider type is not exported
final hasRideTemplatesProvider = StreamProvider.family<bool, String>(
  (ref, groupId) => ref
      .watch(rideTemplatesRepositoryProvider)
      .watchTemplates(groupId)
      .map((t) => t.isNotEmpty),
);
