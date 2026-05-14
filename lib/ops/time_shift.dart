import '../core/subtitle.dart';
import '../core/time_code.dart';

class TimeShiftOp {
  static void shiftAll(Subtitle subtitle, double ms,
      {List<int>? selectedIndexes}) {
    if (selectedIndexes == null) {
      subtitle.addTimeToAllParagraphs(ms);
      return;
    }
    for (final i in selectedIndexes) {
      if (i < 0 || i >= subtitle.paragraphs.length) continue;
      final p = subtitle.paragraphs[i];
      p.startTime.totalMilliseconds += ms;
      p.endTime.totalMilliseconds += ms;
    }
  }

  static void linearSync(Subtitle subtitle,
      {required double firstNewMs, required double lastNewMs}) {
    if (subtitle.paragraphs.length < 2) return;
    final first = subtitle.paragraphs.first;
    final last = subtitle.paragraphs.last;
    final oldFirst = first.startTime.totalMilliseconds;
    final oldLast = last.startTime.totalMilliseconds;
    if ((oldLast - oldFirst).abs() < 0.001) return;
    final factor = (lastNewMs - firstNewMs) / (oldLast - oldFirst);
    final offset = firstNewMs - oldFirst * factor;
    for (final p in subtitle.paragraphs) {
      p.startTime.totalMilliseconds =
          p.startTime.totalMilliseconds * factor + offset;
      p.endTime.totalMilliseconds =
          p.endTime.totalMilliseconds * factor + offset;
    }
  }

  static void shiftSeconds(Subtitle s, double seconds,
          {List<int>? selectedIndexes}) =>
      shiftAll(s, seconds * TimeCode.baseUnit,
          selectedIndexes: selectedIndexes);
}
