// Ported from SubtitleEdit: src/libse/Common/TimeCode.cs
class TimeCode {
  static const double baseUnit = 1000.0;
  static const double maxTimeTotalMilliseconds = 359999999.0;
  double totalMilliseconds;

  TimeCode([this.totalMilliseconds = 0]);

  TimeCode.fromHms(int hours, int minutes, int seconds, int milliseconds)
      : totalMilliseconds = hours * 3600 * baseUnit +
            minutes * 60 * baseUnit +
            seconds * baseUnit +
            milliseconds.toDouble();

  TimeCode.fromDuration(Duration d)
      : totalMilliseconds = d.inMicroseconds / 1000.0;

  TimeCode clone() => TimeCode(totalMilliseconds);

  bool get isMaxTime =>
      (totalMilliseconds - maxTimeTotalMilliseconds).abs() < 0.01;
  double get totalSeconds => totalMilliseconds / baseUnit;

  Duration _ts() => Duration(microseconds: (totalMilliseconds * 1000).round());

  int get hours => _ts().inHours;
  int get minutes => _ts().inMinutes.remainder(60).abs();
  int get seconds => _ts().inSeconds.remainder(60).abs();
  int get milliseconds => _ts().inMilliseconds.remainder(1000).abs();

  String toSrt() =>
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')},${milliseconds.toString().padLeft(3, '0')}';

  String toVtt() =>
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(3, '0')}';

  String toAss() {
    final cs = (milliseconds / 10).floor();
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => toSrt();
}
