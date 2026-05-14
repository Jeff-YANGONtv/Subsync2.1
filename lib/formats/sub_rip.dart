// Ported from SubtitleEdit: src/libse/SubtitleFormats/SubRip.cs
import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/subtitle_format.dart';
import '../core/time_code.dart';

class SubRip extends SubtitleFormat {
  @override
  String get name => 'SubRip';
  @override
  String get extension => '.srt';
  @override
  List<String> get alternateExtensions => const ['.wsrt'];

  static final RegExp _timeRe = RegExp(
      r'^(-?\d{1,2}):(-?\d{1,2}):(-?\d{1,2})[,.](-?\d{1,3})\s*-->\s*'
      r'(-?\d{1,2}):(-?\d{1,2}):(-?\d{1,2})[,.](-?\d{1,3})');

  @override
  bool isMine(List<String> lines, String fileName) {
    if (lines.isNotEmpty &&
        lines[0].trim().toUpperCase().startsWith('WEBVTT')) {
      return false;
    }
    final s = Subtitle();
    loadSubtitle(s, lines, fileName);
    return s.paragraphs.isNotEmpty;
  }

  @override
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName) {
    subtitle.paragraphs.clear();
    _State expecting = _State.number;
    Paragraph? current;

    for (var raw in lines) {
      final line = raw
          .replaceAll('\uFEFF', '')
          .replaceAll('\u200B', '')
          .trimRight();

      switch (expecting) {
        case _State.number:
          if (_timeRe.hasMatch(line.trim())) {
            current = Paragraph();
            _parseTimeLine(line.trim(), current);
            expecting = _State.text;
          } else if (int.tryParse(line.trim()) != null) {
            current = Paragraph(number: int.parse(line.trim()));
            expecting = _State.timeCodes;
          }
          break;
        case _State.timeCodes:
          if (_timeRe.hasMatch(line.trim()) && current != null) {
            _parseTimeLine(line.trim(), current);
            expecting = _State.text;
          }
          break;
        case _State.text:
          if (line.trim().isEmpty) {
            if (current != null && current.endTime.totalMilliseconds > 0) {
              subtitle.paragraphs.add(current);
            }
            current = null;
            expecting = _State.number;
          } else if (current != null) {
            current.text =
                current.text.isEmpty ? line : '${current.text}\n$line';
          }
          break;
      }
    }
    if (current != null && current.endTime.totalMilliseconds > 0) {
      subtitle.paragraphs.add(current);
    }
    subtitle.renumber();
  }

  void _parseTimeLine(String line, Paragraph p) {
    final m = _timeRe.firstMatch(line);
    if (m == null) return;
    p.startTime = TimeCode.fromHms(int.parse(m.group(1)!),
        int.parse(m.group(2)!), int.parse(m.group(3)!), int.parse(m.group(4)!));
    p.endTime = TimeCode.fromHms(int.parse(m.group(5)!),
        int.parse(m.group(6)!), int.parse(m.group(7)!), int.parse(m.group(8)!));
  }

  @override
  String toText(Subtitle subtitle, String title) {
    final sb = StringBuffer();
    for (var i = 0; i < subtitle.paragraphs.length; i++) {
      final p = subtitle.paragraphs[i];
      sb
        ..writeln(i + 1)
        ..writeln('${p.startTime.toSrt()} --> ${p.endTime.toSrt()}')
        ..writeln(p.text)
        ..writeln();
    }
    return sb.toString();
  }
}

enum _State { number, timeCodes, text }
