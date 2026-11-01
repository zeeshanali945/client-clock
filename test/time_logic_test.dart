import 'package:client_clock/time_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  test('Friday 5 pm New York is 2 am Saturday in Karachi before US clocks go back', () {
    final r = convertDeadline(
      clientTz: 'America/New_York',
      ownTz: 'Asia/Karachi',
      year: 2026, month: 10, day: 30, hour: 17, minute: 0,
    );
    expect(r.ownTime.weekday, DateTime.saturday);
    expect(r.ownTime.hour, 2);
    expect(r.ownTime.minute, 0);
  });

  test('Same deadline is 3 am Saturday after US clocks go back (6 Nov 2026)', () {
    final r = convertDeadline(
      clientTz: 'America/New_York',
      ownTz: 'Asia/Karachi',
      year: 2026, month: 11, day: 6, hour: 17, minute: 0,
    );
    expect(r.ownTime.weekday, DateTime.saturday);
    expect(r.ownTime.hour, 3);
  });

  test('Karachi 9-17 and London 9-17 overlap 2 pm to 5 pm Karachi time in November', () {
    final w = findOverlap(
      ownTz: 'Asia/Karachi', ownStart: 9 * 60, ownEnd: 17 * 60, ownWeekend: {6, 7},
      clientTz: 'Europe/London', clientStart: 9 * 60, clientEnd: 17 * 60, clientWeekend: {6, 7},
      year: 2026, month: 11, day: 2, // Monday
    );
    expect(w.length, 1);
    expect(w.first.ownStart.hour, 14);
    expect(w.first.ownEnd.hour, 17);
    expect(w.first.clientStart.hour, 9);
    expect(w.first.clientEnd.hour, 12);
  });

  test('No overlap on the freelancer\'s own day off', () {
    final w = findOverlap(
      ownTz: 'Asia/Karachi', ownStart: 9 * 60, ownEnd: 17 * 60, ownWeekend: {6, 7},
      clientTz: 'Europe/London', clientStart: 9 * 60, clientEnd: 17 * 60, clientWeekend: {6, 7},
      year: 2026, month: 10, day: 31, // Saturday
    );
    expect(w, isEmpty);
  });
}
