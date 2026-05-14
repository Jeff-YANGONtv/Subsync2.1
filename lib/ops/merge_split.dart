import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/time_code.dart';

class MergeSplitOp {
  static void merge(Subtitle subtitle, List<int> indexes) {
    if (indexes.length < 2) return;
    indexes = [...indexes]..sort();
    final first = subtitle.paragraphs[indexes.first];
    final last = subtitle.paragraphs[indexes.last];
    final mergedText = indexes
        .map((i) => subtitle.paragraphs[i].text.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    first.endTime = last.endTime.clone();
    first.text = mergedText;
    for (var k = indexes.length - 1; k >= 1; k--) {
      subtitle.paragraphs.removeAt(indexes[k]);
    }
    subtitle.renumber();
  }

  static void splitAt(Subtitle subtitle, int index, {double ratio = 0.5}) {
    if (index < 0 || index >= subtitle.paragraphs.length) return;
    ratio = ratio.clamp(0.01, 0.99);
    final p = subtitle.paragraphs[index];
    final dur = p.durationMs;
    if (dur <= 0) return;
    final splitMs = p.startTime.totalMilliseconds + dur * ratio;
    final text = p.text;
    final cut = _findTextSplit(text, ratio);
    final left = text.substring(0, cut).trimRight();
    final right = text.substring(cut).trimLeft();
    final newRight = Paragraph.copy(p)
      ..startTime = TimeCode(splitMs)
      ..endTime = p.endTime.clone()
      ..text = right;
    p.endTime = TimeCode(splitMs);
    p.text = left;
    subtitle.paragraphs.insert(index + 1, newRight);
    subtitle.renumber();
  }

  static int _findTextSplit(String text, double ratio) {
    if (text.isEmpty) return 0;
    final target = (text.length * ratio).round();
    final nl = text.indexOf('\n');
    if (nl > 0 && (nl - target).abs() < target * 0.5) return nl + 1;
    for (final mark in ['. ', '! ', '? ']) {
      final idx =
          text.indexOf(mark, (target - 10).clamp(0, text.length).toInt());
      if (idx > 0 &&
          idx < text.length - 1 &&
          (idx - target).abs() < target * 0.5) {
        return idx + mark.length;
      }
    }
    final sp = text.lastIndexOf(' ', target);
    return sp > 0 ? sp + 1 : target;
  }
}
