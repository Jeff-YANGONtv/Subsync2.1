// Ported from SubtitleEdit: src/libse/Common/Subtitle.cs
import 'paragraph.dart';
import 'subtitle_format.dart';

class Subtitle {
  final List<Paragraph> paragraphs = [];
  String header = '';
  String fileName = '';

  int get count => paragraphs.length;

  Subtitle();
  Subtitle.copy(Subtitle other) {
    header = other.header;
    fileName = other.fileName;
    for (final p in other.paragraphs) {
      paragraphs.add(Paragraph.copy(p));
    }
  }

  void addTimeToAllParagraphs(double ms) {
    for (final p in paragraphs) {
      p.startTime.totalMilliseconds += ms;
      p.endTime.totalMilliseconds += ms;
    }
  }

  void changeFrameRate(double oldFps, double newFps) {
    final factor = SubtitleFormat.getFrameForCalculation(oldFps) /
        SubtitleFormat.getFrameForCalculation(newFps);
    for (final p in paragraphs) {
      p.startTime.totalMilliseconds *= factor;
      p.endTime.totalMilliseconds *= factor;
    }
  }

  void renumber([int startNumber = 1]) {
    var n = startNumber;
    for (final p in paragraphs) {
      p.number = n++;
    }
  }

  void sortByStartTime() {
    paragraphs.sort((a, b) =>
        a.startTime.totalMilliseconds.compareTo(b.startTime.totalMilliseconds));
    renumber();
  }
}
