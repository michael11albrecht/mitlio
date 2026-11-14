import 'package:mitlio_domain/mitlio_domain.dart';

/// Pure helpers behind the rides screens: number parsing, the fuel price
/// default and the "who drives today" suggestion. No state, no I/O.

/// Parses a decimal such as `6,5`, `0.08` or `20` into thousandths
/// (`6500`, `80`, `20000`). Used for litres per 100 km, prices per unit,
/// rates per km and kilometres (km x 1000 = metres). Accepts `,` and `.`;
/// at most three fraction digits; no signs, no grouping. Null if blank or
/// malformed.
int? parseMilli(String input) {
  final text = input.trim();
  if (!RegExp(r'^(\d+([.,]\d{0,3})?|[.,]\d{1,3})$').hasMatch(text)) {
    return null;
  }
  final parts = text.split(RegExp('[.,]'));
  final whole = parts.first.isEmpty ? '0' : parts.first;
  if (whole.length > 12) return null;
  final fraction = parts.length > 1 ? parts[1].padRight(3, '0') : '000';
  return int.parse(whole) * 1000 + int.parse(fraction);
}

/// Inverse of [parseMilli] for editing: no trailing zeros, [separator] as
/// the decimal mark (`6500` -> `6,5`, `20000` -> `20`).
String formatMilli(int milli, {String separator = ','}) {
  final whole = milli ~/ 1000;
  final fraction = (milli % 1000).toString().padLeft(3, '0');
  final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? '$whole' : '$whole$separator$trimmed';
}

/// A price per unit for display: at least two decimals, a third only if
/// it is not zero (`1750` -> `1,75`, `1759` -> `1,759`).
String formatPriceMilli(int milli, {String separator = ','}) {
  final whole = milli ~/ 1000;
  final fraction = (milli % 1000).toString().padLeft(3, '0');
  final shown = fraction.endsWith('0') ? fraction.substring(0, 2) : fraction;
  return '$whole$separator$shown';
}

/// Fallback fuel price (per litre or kWh, in thousandths) for a vehicle
/// that has no ride yet. Live prices arrive with P6c; until then the last
/// price used for the vehicle wins and this only seeds the very first ride.
int defaultPriceMilli(FuelType fuel) => switch (fuel) {
  FuelType.petrol => 1750,
  FuelType.diesel => 1650,
  FuelType.electric => 350,
  FuelType.other => 1750,
};

/// The price a new ride with [vehicle] starts with: frozen from the newest
/// ride with that vehicle (by date, then id), else [defaultPriceMilli].
int suggestedPriceMilli(Vehicle vehicle, Iterable<Ride> rides) {
  Ride? last;
  for (final r in rides) {
    if (r.vehicleId != vehicle.id) continue;
    if (last == null ||
        r.date.isAfter(last.date) ||
        (r.date == last.date && r.id.compareTo(last.id) > 0)) {
      last = r;
    }
  }
  return last?.pricePerUnitMilli ?? defaultPriceMilli(vehicle.fuelType);
}

/// Metres a ride covers (both ways for a round trip).
int rideMeters(Ride r) => r.distanceMeters * (r.roundTrip ? 2 : 1);

/// Metres driven minus metres ridden per member over [rides]. Members
/// without a ride are 0; ids outside [memberIds] are ignored.
Map<String, int> meterBalances(
  Iterable<Ride> rides,
  Iterable<String> memberIds,
) {
  final balance = {for (final id in memberIds) id: 0};
  for (final r in rides) {
    final meters = rideMeters(r);
    if (balance.containsKey(r.driverId)) {
      balance[r.driverId] = balance[r.driverId]! + meters;
    }
    for (final p in r.passengerIds) {
      if (balance.containsKey(p)) balance[p] = balance[p]! - meters;
    }
  }
  return balance;
}

/// Who should drive next ("alternate fairly").
///
/// Candidates are the members who can drive this vehicle: the template's
/// default driver plus everyone who has driven that vehicle before. If there
/// are none (a template without a default driver on a fresh vehicle), the
/// carpool is the candidate set: the template's passengers, else everyone.
///
/// Among the candidates the one with the lowest [meterBalances] (metres
/// driven minus ridden over [unsettled] rides) is suggested. Ties go to the
/// one who drove longest ago (never = longest), then to the earlier member
/// in [members]. Returns null only for an empty group.
String? suggestDriver({
  required List<String> members,
  required RideTemplate template,
  required Iterable<Ride> history,
  required Iterable<Ride> unsettled,
}) {
  if (members.isEmpty) return null;
  final live = members.toSet();
  var candidates = <String>{
    if (template.defaultDriverId != null) template.defaultDriverId!,
    for (final r in history)
      if (r.vehicleId == template.vehicleId) r.driverId,
  }..retainAll(live);
  if (candidates.isEmpty) {
    candidates = {...template.defaultPassengerIds}..retainAll(live);
  }
  if (candidates.isEmpty) candidates = live;

  final balance = meterBalances(unsettled, members);
  final lastDrove = <String, DateTime>{};
  for (final r in history) {
    final prev = lastDrove[r.driverId];
    if (prev == null || r.date.isAfter(prev)) lastDrove[r.driverId] = r.date;
  }
  final ordered = members.where(candidates.contains).toList()
    ..sort((a, b) {
      final byBalance = balance[a]!.compareTo(balance[b]!);
      if (byBalance != 0) return byBalance;
      final da = lastDrove[a];
      final db = lastDrove[b];
      if (da == null && db != null) return -1;
      if (da != null && db == null) return 1;
      if (da != null && db != null) {
        final byDate = da.compareTo(db);
        if (byDate != 0) return byDate;
      }
      return members.indexOf(a).compareTo(members.indexOf(b));
    });
  return ordered.first;
}

/// Who rides along by default when [driverId] drives [template]: the
/// template's carpool (default driver and passengers) without the driver.
Set<String> defaultPassengers(RideTemplate template, String driverId) => {
  if (template.defaultDriverId != null) template.defaultDriverId!,
  ...template.defaultPassengerIds,
}..remove(driverId);

/// What one passenger owes the driver for a ride.
final class RideShare {
  const RideShare({required this.memberId, required this.cents});

  final String memberId;
  final int cents;
}

/// Cost of a ride and what each passenger owes.
final class RideSummary {
  const RideSummary({required this.totalCents, required this.owes});

  final int totalCents;

  /// Passengers in member order.
  final List<RideShare> owes;
}

/// Total and per-passenger amounts of [ride] through the domain, or null if
/// the domain rejects it (e.g. no km rate on the vehicle).
RideSummary? summarizeRide(
  Ride ride,
  Vehicle vehicle,
  Currency currency,
  List<Member> members,
) {
  final cost = rideCost(ride, vehicle, currency, members);
  if (cost is! Ok<TripCost, TripError>) return null;
  final shares = cost.value.shares;
  return RideSummary(
    totalCents: cost.value.totalCents,
    owes: [
      for (final m in tieOrder(members))
        if (ride.passengerIds.contains(m.id))
          RideShare(memberId: m.id, cents: shares[m.id] ?? 0),
    ],
  );
}
