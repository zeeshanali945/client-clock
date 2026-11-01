/// Weekdays follow Dart's DateTime: Monday = 1 ... Sunday = 7.
/// Working hours are stored as minutes since midnight.

const int freeClientLimit = 3;

class Profile {
  final String tz;
  final int workStart;
  final int workEnd;
  final Set<int> weekend;

  const Profile({
    required this.tz,
    this.workStart = 9 * 60,
    this.workEnd = 17 * 60,
    this.weekend = const {6, 7},
  });

  Profile copyWith({String? tz, int? workStart, int? workEnd, Set<int>? weekend}) =>
      Profile(
        tz: tz ?? this.tz,
        workStart: workStart ?? this.workStart,
        workEnd: workEnd ?? this.workEnd,
        weekend: weekend ?? this.weekend,
      );

  Map<String, dynamic> toJson() => {
        'tz': tz,
        'workStart': workStart,
        'workEnd': workEnd,
        'weekend': weekend.toList(),
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        tz: j['tz'] as String,
        workStart: j['workStart'] as int,
        workEnd: j['workEnd'] as int,
        weekend: (j['weekend'] as List).map((e) => e as int).toSet(),
      );
}

class Client {
  final String id;
  final String name;
  final String tz;
  final int workStart;
  final int workEnd;
  final Set<int> weekend;

  const Client({
    required this.id,
    required this.name,
    required this.tz,
    this.workStart = 9 * 60,
    this.workEnd = 17 * 60,
    this.weekend = const {6, 7},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tz': tz,
        'workStart': workStart,
        'workEnd': workEnd,
        'weekend': weekend.toList(),
      };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'] as String,
        name: j['name'] as String,
        tz: j['tz'] as String,
        workStart: j['workStart'] as int,
        workEnd: j['workEnd'] as int,
        weekend: (j['weekend'] as List).map((e) => e as int).toSet(),
      );
}
