import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/subtitle_format.dart';
import '../core/time_code.dart';

class Sami extends SubtitleFormat {
  @override
  String get name => 'SAMI';
  @override
  String get extension => 'smi';
  @override
  List<String> get alternateExtensions => ['sami'];

  @override
  bool isMine(List<String> lines, String fileName) {
    final content = lines.join('\n').toLowerCase();
    return content.contains('<sami>') || fileName.toLowerCase().endsWith('.smi') || fileName.toLowerCase().endsWith('.sami');
  }

  @override
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName) {
    final content = lines.join('\n');
    final syncRe = RegExp(r'<sync\s+start=(\d+)>', caseSensitive: false);
    final pRe = RegExp(r'<p\s+class=[^>]+>(.*?)(?=<sync|<p|</body>|</sami>|$)', caseSensitive: false, dotAll: true);
    
    final matches = syncRe.allMatches(content).toList();
    for (var i = 0; i < matches.length; i++) {
      final startMs = double.parse(matches[i].group(1)!);
      final nextStartMs = (i + 1 < matches.length) ? double.parse(matches[i+1].group(1)!) : startMs + 2000;
      
      final pMatch = pRe.firstMatch(content.substring(matches[i].end));
      if (pMatch != null) {
        var text = pMatch.group(1)!.trim();
        if (text.toLowerCase() == '&nbsp;') continue;
        
        // Basic HTML tag stripping
        text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
                   .replaceAll(RegExp(r'<[^>]+>'), '')
                   .replaceAll('&nbsp;', ' ');

        subtitle.paragraphs.add(Paragraph(
          startTime: TimeCode(startMs),
          endTime: TimeCode(nextStartMs),
          text: text.trim(),
        ));
      }
    }
    subtitle.renumber();
  }

  @override
  String toText(Subtitle subtitle, String title) {
    final sb = StringBuffer();
    sb.writeln('<SAMI>\n<HEAD>\n<TITLE>$title</TITLE>\n<STYLE TYPE="text/css">\n<!--\nP { font-family: Arial; font-weight: normal; color: white; background-color: black; text-align: center; }\n.ENUSCC { Name: English; lang: en-US; SAMIType: CC; }\n-->\n</STYLE>\n</HEAD>\n<BODY>');
    
    for (final p in subtitle.paragraphs) {
      final start = p.startTime.totalMilliseconds.round();
      final text = p.text.replaceAll('\n', '<br>');
      sb.writeln('  <SYNC Start=$start><P Class=ENUSCC>$text');
      // SAMI often uses an empty sync to "clear" the screen
      final end = p.endTime.totalMilliseconds.round();
      sb.writeln('  <SYNC Start=$end><P Class=ENUSCC>&nbsp;');
    }
    
    sb.writeln('</BODY>\n</SAMI>');
    return sb.toString();
  }
}
