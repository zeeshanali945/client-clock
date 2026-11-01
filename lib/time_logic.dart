import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// True when [t] falls inside working hours on a day that is not a weekend day.
bool isWorking(
  tz.TZDateTime t, {
  required int start,
  required int end,
  required Set<int> weekend,
}) {
  if (weekend.contains(t.weekday)) return false;
  final m = t.hour * 60 + t.minute;
  return m >= start && m < end;
}

class DeadlineResult {
  final tz.TZDateTime clientTime;
  final tz.TZDateTime ownTime;
  const DeadlineResult(this.clientTime, this.ownTime);

  Duration remaining(DateTime now) => ownTime.difference(now);
}

/// Converts a wall-clock deadline in the client's time zone into the
/// freelancer's time zone. Uses IANA names so daylight saving is handled.
DeadlineResult convertDeadline({
  required String clientTz,
  required String ownTz,
  required int year,
  required int month,
  required int day,
  required int hour,
  required int minute,
}) {
  final clientLoc = tz.getLocation(clientTz);
  final clientTime = tz.TZDateTime(clientLoc, year, month, day, hour, minute);
  final ownTime = tz.TZDateTime.from(clientTime, tz.getLocation(ownTz));
  return DeadlineResult(clientTime, ownTime);
}

class OverlapWindow {
  final tz.TZDateTime ownStart;
  final tz.TZDateTime ownEnd;
  final tz.TZDateTime clientStart;
  final tz.TZDateTime clientEnd;
  const OverlapWindow(this.ownStart, this.ownEnd, this.clientStart, this.clientEnd);
}

/// Finds the windows on one calendar day (in the freelancer's zone) when both
/// people are inside working hours and neither is on a weekend day.
List<OverlapWindow> findOverlap({
  required String ownTz,
  required int ownStart,
  required int ownEnd,
  required Set<int> ownWeekend,
  required String clientTz,
  required int clientStart,
  required int clientEnd,
  required Set<int> clientWeekend,
  required int year,
  required int month,
  required int day,
  int stepMinutes = 15,
}) {
  final ownLoc = tz.getLocation(ownTz);
  final clientLoc = tz.getLocation(clientTz);
  final windows = <OverlapWindow>[];

  tz.TZDateTime t = tz.TZDateTime(ownLoc, year, month, day);
  tz.TZDateTime? open;

  void close(tz.TZDateTime end) {
    final s = open!;
    windows.add(OverlapWindow(
      s,
      end,
      tz.TZDateTime.from(s, clientLoc),
      tz.TZDateTime.from(end, clientLoc),
    ));
    open = null;
  }

  while (t.year == year && t.month == month && t.day == day) {
    final c = tz.TZDateTime.from(t, clientLoc);
    final ok =
        isWorking(t, start: ownStart, end: ownEnd, weekend: ownWeekend) &&
            isWorking(c, start: clientStart, end: clientEnd, weekend: clientWeekend);
    if (ok) {
      open ??= t;
    } else if (open != null) {
      close(t);
    }
    t = t.add(Duration(minutes: stepMinutes));
  }
  if (open != null) close(t);
  return windows;
}

// ---------- formatting helpers ----------

String fmtTime(DateTime t) => DateFormat.jm().format(t);
String fmtDay(DateTime t) => DateFormat('EEE d MMM').format(t);
String fmtDayTime(DateTime t) => '${fmtDay(t)}, ${fmtTime(t)}';

String fmtMinutes(int m) =>
    DateFormat.jm().format(DateTime(2000, 1, 1, m ~/ 60, m % 60));

String fmtDuration(Duration d) {
  if (d.isNegative) return 'already passed';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final mins = d.inMinutes % 60;
  if (days > 0) return '$days d $hours h';
  if (hours > 0) return '$hours h $mins min';
  return '$mins min';
}

/// "Today", "Tomorrow" or "Yesterday" for a client time compared with the
/// freelancer's own current date. Falls back to the weekday and date.
String relativeDay(DateTime clientTime, DateTime ownNow) {
  final a = DateTime.utc(clientTime.year, clientTime.month, clientTime.day);
  final b = DateTime.utc(ownNow.year, ownNow.month, ownNow.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return fmtDay(clientTime);
}

/// Example: "5 h behind you", "2 h ahead of you", "same time as you".
String gapLabel(String ownTz, String clientTz, DateTime now) {
  final own = tz.TZDateTime.from(now, tz.getLocation(ownTz)).timeZoneOffset;
  final cl = tz.TZDateTime.from(now, tz.getLocation(clientTz)).timeZoneOffset;
  final mins = (cl - own).inMinutes;
  if (mins == 0) return 'same time as you';
  final abs = mins.abs();
  final h = abs ~/ 60;
  final m = abs % 60;
  final text = m == 0 ? '$h h' : '$h h $m min';
  return mins > 0 ? '$text ahead of you' : '$text behind you';
}
