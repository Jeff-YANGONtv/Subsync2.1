// Ported from SubtitleEdit: src/libse/SubtitleFormats/WebVTT.cs
import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/subtitle_format.dart';
import '../core/time_code.dart';

class WebVtt extends SubtitleFormat {
  @override
  String get name => 'WebVTT';
  @override
  String get extension => '.vtt';
  @override
  List<String> get alternateExtensions => const ['.webvtt'];

  static final RegExp _full = RegExp(
      r'^(-?\d+):(-?\d+):(-?\d+)\.(-?\d+)\s*-->\s*(-?\d+):(-?\d+):(-?\d+)\.(-?\d+)');
  static final RegExp _middle = RegExp(
      r'^(-?\d+):(-?\d+)\.(-?\d+)\s*-->\s*(-?\d+):(-?\d+):(-?\d+)\.(-?\d+)');
  static final RegExp _short = RegExp(
      r'^(-?\d+):(-?\d+)\.(-?\d+)\s*-->\s*(-?\d+):(-?\d+)\.(-?\d+)');
  static final RegExp _cTag = RegExp(r'</?c[a-zA-Z._\-\d%#]*>');

  @override
  bool isMine(List<String> lines, String fileName) {
    if (lines.isEmpty) return false;
    return lines.first.trim().toUpperCase().startsWith('WEBVTT');
  }

  @override
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName) {
    subtitle.paragraphs.clear();
    Paragraph? current;
    var inHeader = true;
    for (var raw in lines) {
      final line = raw.replaceAll('\uFEFF', '').trimRight();
      if (inHeader) {
        if (line.toUpperCase().startsWith('WEBVTT')) continue;
        if (line.trim().isEmpty) {
          inHeader = false;
          continue;
        }
        inHeader = false;
      }
      if (_full.hasMatch(line.trim()) ||
          _middle.hasMatch(line.trim()) ||
          _short.hasMatch(line.trim())) {
        current = Paragraph();
        _parseTimeLine(line.trim(), current);
        subtitle.paragraphs.add(current);
      } else if (line.trim().isEmpty) {
        current = null;
      } else if (current != null) {
        final stripped = line.replaceAll(_cTag, '');
        current.text =
            current.text.isEmpty ? stripped : '${current.text}\n$stripped';
      }
    }
    subtitle.renumber();
  }

  void _parseTimeLine(String line, Paragraph p) {
    var m = _full.firstMatch(line);
    if (m != null) {
      p.startTime = TimeCode.fromHms(int.parse(m.group(1)!),
          int.parse(m.group(2)!), int.parse(m.group(3)!), int.parse(m.group(4)!));
      p.endTime = TimeCode.fromHms(int.parse(m.group(5)!),
          int.parse(m.group(6)!), int.parse(m.group(7)!), int.parse(m.group(8)!));
      return;
    }
    m = _middle.firstMatch(line);
    if (m != null) {
      p.startTime = TimeCode.fromHms(0, int.parse(m.group(1)!),
          int.parse(m.group(2)!), int.parse(m.group(3)!));
      p.endTime = TimeCode.fromHms(int.parse(m.group(4)!),
          int.parse(m.group(5)!), int.parse(m.group(6)!), int.parse(m.group(7)!));
      return;
    }
    m = _short.firstMatch(line);
    if (m != null) {
      p.startTime = TimeCode.fromHms(0, int.parse(m.group(1)!),
          int.parse(m.group(2)!), int.parse(m.group(3)!));
      p.endTime = TimeCode.fromHms(0, int.parse(m.group(4)!),
          int.parse(m.group(5)!), int.parse(m.group(6)!));
    }
  }

  @override
  String toText(Subtitle subtitle, String title) {
    final sb = StringBuffer()
      ..writeln('WEBVTT')
      ..writeln();
    for (var i = 0; i < subtitle.paragraphs.length; i++) {
      final p = subtitle.paragraphs[i];
      sb
        ..writeln(i + 1)
        ..writeln('${p.startTime.toVtt()} --> ${p.endTime.toVtt()}')
        ..writeln(p.text)
        ..writeln();
    }
    return sb.toString();
  }
}
