import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/amount_parser.dart';
import 'package:mitlio/core/decimal_parser.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_providers.dart';
import 'package:mitlio/features/expenses/data/repositories/expenses_repository.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart'
    show localOwnerId;
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_providers.dart';
import 'package:mitlio/features/trips/data/trip_meta.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

export 'package:mitlio/features/members/data/repositories/members_repository.dart'
    show GroupMember;
export 'package:mitlio/features/trips/data/trip_meta.dart' show TripEnergy;

/// The group id of the trip form without a group ("only calculate a trip",
/// first run). Nothing is stored in this mode; the result can be shared.
const standaloneTripGroupId = 'standalone';

/// Seats of the standalone trip form: the driver and up to four more.
const _standaloneSeats = 5;

/// Form fields that can hold a number the user typed.
enum TripField { distance, consumption, price, wear, kmRate, tolls, ferry }

/// Why there is no result yet.
enum TripBlocker {
  /// A required number is missing or unreadable.
  needsInput,

  /// Nobody takes part in the split.
  noParticipants,

  /// The total is too large to compute exactly.
  tooLarge,
}

/// What the user entered. Numbers stay as typed text (`.` or `,` as decimal
/// separator); they are converted to domain units only when computing.
final class TripInputs {
  const TripInputs({
    this.distance = '',
    this.roundTrip = false,
    this.energy = TripEnergy.fuel,
    this.useKmRate = false,
    this.consumption = '',
    this.price = '',
    this.wear = '',
    this.kmRate = '',
    this.tolls = '',
    this.ferry = '',
    this.driverId,
    this.passengerIds = const {},
    this.driverCounts = true,
    this.title = '',
  });

  /// One-way distance in km.
  final String distance;
  final bool roundTrip;
  final TripEnergy energy;

  /// A flat km rate replaces fuel and wear.
  final bool useKmRate;

  /// Litres or kWh per 100 km.
  final String consumption;

  /// Per litre or kWh.
  final String price;

  /// Optional, per km.
  final String wear;

  /// Per km.
  final String kmRate;

  /// Whole trip, in the group currency.
  final String tolls;
  final String ferry;
  final String? driverId;
  final Set<String> passengerIds;

  /// Whether the driver pays a share too.
  final bool driverCounts;
  final String title;

  TripInputs copyWith({
    String? distance,
    bool? roundTrip,
    TripEnergy? energy,
    bool? useKmRate,
    String? consumption,
    String? price,
    String? wear,
    String? kmRate,
    String? tolls,
    String? ferry,
    String? driverId,
    Set<String>? passengerIds,
    bool? driverCounts,
    String? title,
  }) => TripInputs(
    distance: distance ?? this.distance,
    roundTrip: roundTrip ?? this.roundTrip,
    energy: energy ?? this.energy,
    useKmRate: useKmRate ?? this.useKmRate,
    consumption: consumption ?? this.consumption,
    price: price ?? this.price,
    wear: wear ?? this.wear,
    kmRate: kmRate ?? this.kmRate,
    tolls: tolls ?? this.tolls,
    ferry: ferry ?? this.ferry,
    driverId: driverId ?? this.driverId,
    passengerIds: passengerIds ?? this.passengerIds,
    driverCounts: driverCounts ?? this.driverCounts,
    title: title ?? this.title,
  );

  JsonMap toJson() => {
    'distance': distance,
    'roundTrip': roundTrip,
    'energy': energy.name,
    'useKmRate': useKmRate,
    'consumption': consumption,
    'price': price,
    'wear': wear,
    'kmRate': kmRate,
    'tolls': tolls,
    'ferry': ferry,
    'driverId': driverId,
    'passengerIds': passengerIds.toList()..sort(),
    'driverCounts': driverCounts,
    'title': title,
  };
}

/// Outcome of computing a trip from [TripInputs]: a result, or why not.
final class TripEvaluation {
  const TripEvaluation._ok(TripInput this.input, TripCost this.cost)
    : blocker = null,
      invalid = const {};

  const TripEvaluation._blocked(
    TripBlocker this.blocker, [
    this.invalid = const {},
  ]) : input = null,
       cost = null;

  final TripInput? input;
  final TripCost? cost;
  final TripBlocker? blocker;

  /// Fields with text that is not a valid number (blank is not invalid).
  final Set<TripField> invalid;

  /// Share of every participant, `null` without a result.
  Map<String, int>? get participantShares {
    final c = cost;
    final i = input;
    if (c == null || i == null) return null;
    return {
      for (final id in [...i.passengerIds, if (i.driverCounts) i.driverId])
        id: c.shares[id]!,
    };
  }

  /// What each participant pays; the largest share when cents do not divide
  /// evenly (then [sharesEqual] is false).
  int? get perPersonCents {
    final shares = participantShares?.values;
    return shares == null || shares.isEmpty
        ? null
        : shares.reduce((a, b) => a > b ? a : b);
  }

  bool get sharesEqual {
    final shares = participantShares?.values.toSet();
    return shares != null && shares.length == 1;
  }

  /// What the others hand over to the driver: the total minus their own
  /// share.
  int? get driverGetsCents {
    final c = cost;
    final i = input;
    return c == null || i == null ? null : c.totalCents - c.shares[i.driverId]!;
  }
}

/// Converts [inputs] to a [TripInput] and computes it. Pure.
TripEvaluation evaluateTrip(
  TripInputs inputs,
  Currency currency,
  List<Member> members,
) {
  final invalid = <TripField>{};
  var missing = false;

  // Decimal text to domain units. Blank is missing (or [orZero]).
  int? units(TripField field, String text, int scale, {bool orZero = false}) {
    if (text.trim().isEmpty) {
      if (!orZero) missing = true;
      return orZero ? 0 : null;
    }
    final value = parseDecimal(text);
    final scaled = value == null ? null : scaleDecimal(value, scale).units;
    if (scaled == null) invalid.add(field);
    return scaled;
  }

  int? money(TripField field, String text) {
    if (text.trim().isEmpty) return 0;
    final cents = parseAmountCents(text, currency);
    if (cents == null) invalid.add(field);
    return cents;
  }

  final meters = units(TripField.distance, inputs.distance, kmToMeters);
  final TripCostMode? mode;
  if (inputs.useKmRate) {
    final rate = units(TripField.kmRate, inputs.kmRate, unitToMilli);
    mode = rate == null ? null : KmRate(rate);
  } else {
    final consumption = units(
      TripField.consumption,
      inputs.consumption,
      unitToMilli,
    );
    final price = units(TripField.price, inputs.price, unitToMilli);
    final wear = units(
      TripField.wear,
      inputs.wear,
      unitToMilli,
      orZero: true,
    );
    mode = consumption == null || price == null || wear == null
        ? null
        : Consumption(
            consumptionMilliPer100km: consumption,
            pricePerUnitMilli: price,
            wearMilliPerKm: wear,
          );
  }
  final tolls = money(TripField.tolls, inputs.tolls);
  final ferry = money(TripField.ferry, inputs.ferry);

  final driver = inputs.driverId;
  if (meters == null ||
      mode == null ||
      tolls == null ||
      ferry == null ||
      driver == null ||
      missing ||
      invalid.isNotEmpty) {
    return TripEvaluation._blocked(TripBlocker.needsInput, invalid);
  }
  final input = TripInput(
    distanceMeters: meters,
    roundTrip: inputs.roundTrip,
    currency: currency,
    mode: mode,
    tollsCents: tolls,
    ferryCents: ferry,
    driverId: driver,
    passengerIds: inputs.passengerIds,
    driverCounts: inputs.driverCounts,
  );
  final TripCost cost;
  try {
    switch (computeTripCost(input, members)) {
      case Ok<TripCost, TripError>(:final value):
        cost = value;
      case Err<TripCost, TripError>(error: TripNoParticipants()):
        return const TripEvaluation._blocked(TripBlocker.noParticipants);
      case Err<TripCost, TripError>():
        return const TripEvaluation._blocked(TripBlocker.needsInput);
    }
  } on MoneyOverflow {
    return const TripEvaluation._blocked(TripBlocker.tooLarge);
  }
  return TripEvaluation._ok(input, cost);
}

/// A saved trip: the new expense and a handle that takes it back.
final class TripSaved {
  const TripSaved({required this.entry, required this.undo});

  final ExpenseEntry entry;
  final Undo undo;
}

sealed class TripFormState {
  const TripFormState();
}

final class TripFormLoading extends TripFormState {
  const TripFormLoading();
}

final class TripFormFailure extends TripFormState {
  const TripFormFailure(this.error);

  final RepositoryError error;
}

final class TripFormLoaded extends TripFormState {
  const TripFormLoaded({
    required this.group,
    required this.members,
    required this.inputs,
    required this.evaluation,
    this.saving = false,
  });

  final Group group;

  /// In position order.
  final List<GroupMember> members;
  final TripInputs inputs;
  final TripEvaluation evaluation;
  final bool saving;

  bool get canSave => evaluation.cost != null && !saving;
}

/// Trip cost form: collects the inputs, shows the result at once and saves
/// the trip as an expense. Starts from the driver, passengers and vehicle
/// values of the group's last trip.
class TripFormViewModel extends Notifier<TripFormState> {
  TripFormViewModel(this.groupId);

  final String groupId;

  /// Whether this is the form without a group (see [standaloneTripGroupId]).
  bool get isStandalone => groupId == standaloneTripGroupId;

  @override
  TripFormState build() {
    unawaited(_load());
    return const TripFormLoading();
  }

  Future<void> _load() async {
    final TripFormState next;
    try {
      next = await _loadState();
    } on Object catch (e) {
      if (ref.mounted) state = TripFormFailure(Storage(e));
      return;
    }
    if (ref.mounted) state = next;
  }

  /// Anonymous seats instead of members; the View names them ("Person 1").
  TripFormState _standaloneState() {
    final group = Group(
      id: groupId,
      name: '',
      currency: Currency.eur,
      createdBy: localOwnerId,
      createdAt: ref.read(clockProvider).now(),
    );
    final seats = [
      for (var i = 0; i < _standaloneSeats; i++)
        GroupMember(
          id: 'seat-${i + 1}',
          groupId: groupId,
          name: '',
          position: i,
        ),
    ];
    return _loaded(
      group,
      seats,
      TripInputs(driverId: seats[0].id, passengerIds: {seats[1].id}),
    );
  }

  Future<TripFormState> _loadState() async {
    if (isStandalone) return _standaloneState();
    final group = await ref.read(groupsRepositoryProvider).get(groupId);
    if (group is Err<Group, RepositoryError>) {
      return TripFormFailure(group.error);
    }
    final members = await ref.read(membersRepositoryProvider).list(groupId);
    if (members is Err<List<GroupMember>, RepositoryError>) {
      return TripFormFailure(members.error);
    }
    final entries = await _currentEntries();
    final last = entries
        .map((e) => TripMeta.tryParse(e.tripMeta))
        .nonNulls
        .firstOrNull;
    final g = (group as Ok<Group, RepositoryError>).value;
    final m = (members as Ok<List<GroupMember>, RepositoryError>).value;
    return _loaded(g, m, _initialInputs(m, last));
  }

  /// The expenses of the group as they are now (first emission).
  Future<List<ExpenseEntry>> _currentEntries() async {
    final first = Completer<List<ExpenseEntry>>();
    final sub = ref
        .read(expensesRepositoryProvider)
        .watchExpenses(groupId)
        .listen(
          (entries) {
            if (!first.isCompleted) first.complete(entries);
          },
          onError: (Object e) {
            if (!first.isCompleted) first.completeError(e);
          },
        );
    try {
      return await first.future;
    } finally {
      // Not awaited: only the first emission matters.
      unawaited(sub.cancel());
    }
  }

  TripFormLoaded _loaded(Group g, List<GroupMember> m, TripInputs inputs) =>
      TripFormLoaded(
        group: g,
        members: m,
        inputs: inputs,
        evaluation: evaluateTrip(inputs, g.currency, [
          for (final x in m) x.toDomain(),
        ]),
      );

  /// Driver and passengers of [last] that are still in the group, else the
  /// first member drives and everybody else rides along.
  static TripInputs _initialInputs(List<GroupMember> members, TripMeta? last) {
    final ids = {for (final m in members) m.id};
    final lastDriver = last != null && ids.contains(last.driverId)
        ? last.driverId
        : null;
    final driver = lastDriver ?? (members.isEmpty ? null : members.first.id);
    final passengers = last != null && lastDriver != null
        ? last.passengerIds.where(ids.contains).toSet()
        : ids.difference({?driver});
    final base = TripInputs(
      driverId: driver,
      passengerIds: passengers,
      driverCounts: last?.driverCounts ?? true,
      roundTrip: last?.roundTrip ?? false,
      energy: last?.energy ?? TripEnergy.fuel,
    );
    return switch (last?.mode) {
      Consumption(
        :final consumptionMilliPer100km,
        :final pricePerUnitMilli,
        :final wearMilliPerKm,
      ) =>
        base.copyWith(
          consumption: _milliText(consumptionMilliPer100km),
          price: _milliText(pricePerUnitMilli),
          wear: wearMilliPerKm == 0 ? '' : _milliText(wearMilliPerKm),
        ),
      KmRate(:final kmRateMilliPerKm) => base.copyWith(
        useKmRate: true,
        kmRate: _milliText(kmRateMilliPerKm),
      ),
      null => base,
    };
  }

  /// Thousandths as plain decimal text with `.` (`6500` is `6.5`).
  static String _milliText(int milli) {
    final fraction = (milli % 1000)
        .toString()
        .padLeft(3, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return '${milli ~/ 1000}${fraction.isEmpty ? '' : '.$fraction'}';
  }

  void retry() {
    state = const TripFormLoading();
    ref.invalidateSelf();
  }

  void _edit(TripInputs Function(TripInputs) change) {
    final s = state;
    if (s is! TripFormLoaded) return;
    final inputs = change(s.inputs);
    state = TripFormLoaded(
      group: s.group,
      members: s.members,
      inputs: inputs,
      evaluation: evaluateTrip(inputs, s.group.currency, [
        for (final m in s.members) m.toDomain(),
      ]),
      saving: s.saving,
    );
  }

  void setDistance(String text) => _edit((i) => i.copyWith(distance: text));
  void setRoundTrip({required bool value}) =>
      _edit((i) => i.copyWith(roundTrip: value));
  void setEnergy(TripEnergy energy) => _edit((i) => i.copyWith(energy: energy));
  void setUseKmRate({required bool value}) =>
      _edit((i) => i.copyWith(useKmRate: value));
  void setConsumption(String text) =>
      _edit((i) => i.copyWith(consumption: text));
  void setPrice(String text) => _edit((i) => i.copyWith(price: text));

  /// Takes a fuel price from the chips (thousandths per litre) into the
  /// price field. With [onlyIfEmpty] (the pre-selected grade's price) a
  /// typed or remembered price stays. Returns the new text (`.` as decimal
  /// separator), or null when nothing changed.
  String? applyFuelPrice(int milli, {required bool onlyIfEmpty}) {
    final s = state;
    if (s is! TripFormLoaded) return null;
    if (onlyIfEmpty && s.inputs.price.trim().isNotEmpty) return null;
    final text = _milliText(milli);
    setPrice(text);
    return text;
  }

  void setWear(String text) => _edit((i) => i.copyWith(wear: text));
  void setKmRate(String text) => _edit((i) => i.copyWith(kmRate: text));
  void setTolls(String text) => _edit((i) => i.copyWith(tolls: text));
  void setFerry(String text) => _edit((i) => i.copyWith(ferry: text));
  void setTitle(String text) => _edit((i) => i.copyWith(title: text));
  void setDriverCounts({required bool value}) =>
      _edit((i) => i.copyWith(driverCounts: value));

  /// Makes [id] the driver. The previous driver rides along; the new driver
  /// is no passenger.
  void setDriver(String id) => _edit((i) {
    final old = i.driverId;
    if (old == id) return i;
    return i.copyWith(
      driverId: id,
      passengerIds: {...i.passengerIds, ?old}..remove(id),
    );
  });

  /// Adds or removes a passenger; the driver cannot be one.
  void togglePassenger(String id) => _edit((i) {
    if (id == i.driverId) return i;
    final passengers = {...i.passengerIds};
    if (!passengers.remove(id)) passengers.add(id);
    return i.copyWith(passengerIds: passengers);
  });

  /// Saves the form as a trip expense. [fallbackTitle] names the trip when
  /// the user typed no title.
  Future<RepoResult<TripSaved>> save({required String fallbackTitle}) async {
    final s = state;
    if (s is! TripFormLoaded) return Err(NotFound('trip form', groupId));
    state = TripFormLoaded(
      group: s.group,
      members: s.members,
      inputs: s.inputs,
      evaluation: s.evaluation,
      saving: true,
    );
    final result = await add(s.inputs, fallbackTitle: fallbackTitle);
    if (ref.mounted) {
      state = TripFormLoaded(
        group: s.group,
        members: s.members,
        inputs: s.inputs,
        evaluation: s.evaluation,
      );
    }
    return result;
  }

  /// Computes [inputs] against the group's current members and stores the
  /// trip as an expense (type `trip`, inputs kept as `tripMeta`). The same
  /// command the form and DebugDrive call. `Err(InvalidData)` while the
  /// inputs give no result.
  Future<RepoResult<TripSaved>> add(
    TripInputs inputs, {
    required String fallbackTitle,
  }) async {
    if (isStandalone) {
      return const Err(InvalidData('a trip without a group is not stored'));
    }
    final groupResult = await ref.read(groupsRepositoryProvider).get(groupId);
    if (groupResult case Err(:final error)) return Err(error);
    final group = (groupResult as Ok<Group, RepositoryError>).value;
    final membersResult = await ref
        .read(membersRepositoryProvider)
        .list(groupId);
    if (membersResult case Err(:final error)) return Err(error);
    final members =
        (membersResult as Ok<List<GroupMember>, RepositoryError>).value;
    final domainMembers = [for (final m in members) m.toDomain()];

    final evaluation = evaluateTrip(inputs, group.currency, domainMembers);
    final input = evaluation.input;
    final cost = evaluation.cost;
    if (input == null || cost == null) {
      return Err(InvalidData('trip not computable: ${evaluation.blocker}'));
    }
    final title = inputs.title.trim().isEmpty
        ? fallbackTitle
        : inputs.title.trim();
    final date = ref.read(clockProvider).now();
    final expense = tripToExpense(
      id: 'trip-draft',
      title: title,
      date: date,
      input: input,
      cost: cost,
      members: domainMembers,
    );
    if (expense case Err(:final error)) return Err(InvalidData('$error'));
    final valid = (expense as Ok<Expense, ExpenseError>).value;

    final repo = ref.read(expensesRepositoryProvider);
    final created = await repo.create(
      groupId,
      ExpenseDraft(
        title: valid.title,
        amountCents: valid.amountCents,
        currency: valid.currency,
        date: valid.date,
        payers: valid.payers,
        split: ExactSplit(valid.shares),
        tripMeta: _meta(input, inputs.energy).toJson(),
      ),
    );
    return switch (created) {
      Ok<ExpenseEntry, RepositoryError>(:final value) => Ok(
        TripSaved(
          entry: value,
          undo: Undo(() async {
            final deleted = await repo.softDelete(value.expense.id);
            return switch (deleted) {
              Ok<Undo, RepositoryError>() => const Ok(null),
              Err<Undo, RepositoryError>(:final error) => Err(error),
            };
          }),
        ),
      ),
      Err<ExpenseEntry, RepositoryError>(:final error) => Err(error),
    };
  }

  /// Opens the share sheet with [text] for the per-person amount. Null
  /// without a result.
  Future<RepoResult<void>?> shareResult(
    String Function(int perPersonCents) text,
  ) async {
    final s = state;
    final cents = s is TripFormLoaded ? s.evaluation.perPersonCents : null;
    if (cents == null) return null;
    return ref.read(settleActionsRepositoryProvider).shareText(text(cents));
  }

  static TripMeta _meta(TripInput i, TripEnergy energy) => TripMeta(
    distanceMeters: i.distanceMeters,
    roundTrip: i.roundTrip,
    energy: energy,
    mode: i.mode,
    tollsCents: i.tollsCents,
    ferryCents: i.ferryCents,
    driverId: i.driverId,
    passengerIds: i.passengerIds,
    driverCounts: i.driverCounts,
  );

  JsonMap debugSnapshot() => switch (state) {
    TripFormLoading() => {'status': 'loading', 'groupId': groupId},
    TripFormFailure(:final error) => {
      'status': 'error',
      'groupId': groupId,
      'error': error.toString(),
    },
    TripFormLoaded(:final group, :final inputs, :final evaluation) => {
      'status': evaluation.cost == null ? 'incomplete' : 'result',
      'groupId': group.id,
      'currency': group.currency.code,
      'inputs': inputs.toJson(),
      'blocker': evaluation.blocker?.name,
      'invalid': [for (final f in evaluation.invalid) f.name],
      'result': evaluation.cost == null
          ? null
          : {
              'totalCents': evaluation.cost!.totalCents,
              'perPersonCents': evaluation.perPersonCents,
              'driverGetsCents': evaluation.driverGetsCents,
              'fuelCents': evaluation.cost!.fuelCents,
              'wearCents': evaluation.cost!.wearCents,
              'kmRateCents': evaluation.cost!.kmRateCents,
              'tollsCents': evaluation.cost!.tollsCents,
              'ferryCents': evaluation.cost!.ferryCents,
              'shares': evaluation.cost!.shares,
            },
    },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final tripFormViewModelProvider =
    NotifierProvider.family<TripFormViewModel, TripFormState, String>(
      TripFormViewModel.new,
    );
