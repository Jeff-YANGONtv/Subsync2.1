import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/subtitle_format.dart';
import '../core/time_code.dart';

class MicroDvd extends SubtitleFormat {
  @override
  String get name => 'MicroDVD';
  @override
  String get extension => 'sub';

  @override
  bool isMine(List<String> lines, String fileName) {
    if (fileName.toLowerCase().endsWith('.sub')) {
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        if (RegExp(r'^\{\d+\}\{\d+\}').hasMatch(line)) return true;
        break;
      }
    }
    return false;
  }

  @override
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName) {
    final re = RegExp(r'^\{(\d+)\}\{(\d+)\}(.*)');
    final fps = SubtitleFormat.getFrameForCalculation();

    for (final line in lines) {
      final match = re.firstMatch(line.trim());
      if (match != null) {
        final startFrame = int.parse(match.group(1)!);
        final endFrame = int.parse(match.group(2)!);
        final text = match.group(3)!.replaceAll('|', '\n');

        subtitle.paragraphs.add(Paragraph(
          startTime: TimeCode(SubtitleFormat.framesToMilliseconds(startFrame, fps)),
          endTime: TimeCode(SubtitleFormat.framesToMilliseconds(endFrame, fps)),
          text: text,
        ));
      }
    }
    subtitle.renumber();
  }

  @override
  String toText(Subtitle subtitle, String title) {
    final sb = StringBuffer();
    final fps = SubtitleFormat.getFrameForCalculation();

    for (final p in subtitle.paragraphs) {
      final startFrame = SubtitleFormat.millisecondsToFrames(p.startTime.totalMilliseconds, fps);
      final endFrame = SubtitleFormat.millisecondsToFrames(p.endTime.totalMilliseconds, fps);
      final text = p.text.replaceAll('\n', '|');
      sb.writeln('{$startFrame}{$endFrame}$text');
    }
    return sb.toString();
  }
}
