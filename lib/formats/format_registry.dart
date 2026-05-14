import '../core/subtitle_format.dart';
import 'sub_rip.dart';
import 'web_vtt.dart';
import 'sub_station_alpha.dart';
import 'micro_dvd.dart';
import 'sami.dart';
import 'ttml.dart';

class FormatRegistry {
  static final List<SubtitleFormat> all = [
    SubRip(),
    WebVtt(),
    AdvancedSubStationAlpha(),
    SubStationAlpha(),
    MicroDvd(),
    Sami(),
    Ttml(),
  ];

  static SubtitleFormat detect(String content, String fileName) {
    final lines = content.split(RegExp(r'\r\n|\r|\n'));
    final lower = fileName.toLowerCase();
    for (final fmt in all) {
      if (lower.endsWith(fmt.extension) ||
          fmt.alternateExtensions.any(lower.endsWith)) {
        if (fmt.isMine(lines, fileName)) return fmt;
      }
    }
    for (final fmt in all) {
      if (fmt.isMine(lines, fileName)) return fmt;
    }
    return SubRip();
  }

  static SubtitleFormat byName(String name) =>
      all.firstWhere((f) => f.name == name, orElse: () => SubRip());
}
