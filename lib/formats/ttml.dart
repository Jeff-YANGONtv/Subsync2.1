import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/subtitle_format.dart';
import '../core/time_code.dart';

class Ttml extends SubtitleFormat {
  @override
  String get name => 'TTML';
  @override
  String get extension => 'ttml';
  @override
  List<String> get alternateExtensions => ['xml', 'dfxp'];

  @override
  bool isMine(List<String> lines, String fileName) {
    final content = lines.join('\n').toLowerCase();
    return content.contains('ttml') || content.contains('http://www.w3.org/ns/ttml');
  }

  @override
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName) {
    final content = lines.join('\n');
    // Simple regex-based parsing for <p begin="..." end="...">...</p>
    final pRe = RegExp(r'<p\s+[^>]*begin="([^"]+)"\s+[^>]*end="([^"]+)"[^>]*>(.*?)</p>', caseSensitive: false, dotAll: true);
    
    for (final match in pRe.allMatches(content)) {
      final begin = match.group(1)!;
      final end = match.group(2)!;
      var text = match.group(3)!.trim();
      
      text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                 .replaceAll(RegExp(r'<[^>]+>'), '');

      subtitle.paragraphs.add(Paragraph(
        startTime: _parseTtmlTime(begin),
        endTime: _parseTtmlTime(end),
        text: text,
      ));
    }
    subtitle.renumber();
  }

  TimeCode _parseTtmlTime(String time) {
    // Supports "00:00:00.000" or "123.45s" or "123ms"
    if (time.endsWith('ms')) {
      return TimeCode(double.parse(time.substring(0, time.length - 2)));
    } else if (time.endsWith('s')) {
      return TimeCode(double.parse(time.substring(0, time.length - 1)) * 1000);
    } else {
      // Assume HH:MM:SS.mmm
      final parts = time.split(':');
      if (parts.length == 3) {
        final h = double.parse(parts[0]);
        final m = double.parse(parts[1]);
        final s = double.parse(parts[2]);
        return TimeCode((h * 3600 + m * 60 + s) * 1000);
      }
    }
    return TimeCode(0);
  }

  @override
  String toText(Subtitle subtitle, String title) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="utf-8"?>');
    sb.writeln('<tt xmlns="http://www.w3.org/ns/ttml" xmlns:ttp="http://www.w3.org/ns/ttml#parameter" ttp:timeBase="media" xmlns:tts="http://www.w3.org/ns/ttml#styling" xml:lang="en">');
    sb.writeln('  <head>\n    <styling>\n      <style xml:id="s1" tts:textAlign="center" tts:color="white" tts:fontSize="16"/>\n    </styling>\n  </head>');
    sb.writeln('  <body>\n    <div>');
    
    for (final p in subtitle.paragraphs) {
      final begin = _formatTtmlTime(p.startTime);
      final end = _formatTtmlTime(p.endTime);
      final text = p.text.replaceAll('\n', '<br/>');
      sb.writeln('      <p begin="$begin" end="$end" style="s1">$text</p>');
    }
    
    sb.writeln('    </div>\n  </body>\n</tt>');
    return sb.toString();
  }

  String _formatTtmlTime(TimeCode tc) {
    final totalSec = tc.totalMilliseconds / 1000.0;
    final h = (totalSec / 3600).floor();
    final m = ((totalSec % 3600) / 60).floor();
    final s = totalSec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toStringAsFixed(3).padLeft(6, '0')}';
  }
}
