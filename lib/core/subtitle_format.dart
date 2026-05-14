// Ported from SubtitleEdit: src/libse/SubtitleFormats/SubtitleFormat.cs
import 'subtitle.dart';
import 'time_code.dart';

abstract class SubtitleFormat {
  String get name;
  String get extension;
  List<String> get alternateExtensions => const [];

  bool isMine(List<String> lines, String fileName);
  void loadSubtitle(Subtitle subtitle, List<String> lines, String fileName);
  String toText(Subtitle subtitle, String title);

  static double getFrameForCalculation(double frameRate) {
    if ((frameRate - 23.976).abs() < 0.001) return 24000.0 / 1001.0;
    if ((frameRate - 29.97).abs() < 0.001) return 30000.0 / 1001.0;
    if ((frameRate - 59.94).abs() < 0.001) return 60000.0 / 1001.0;
    return frameRate;
  }

  static int millisecondsToFrames(double ms, double frameRate) =>
      (ms / (TimeCode.baseUnit / getFrameForCalculation(frameRate))).round();

  static int framesToMilliseconds(double frames, double frameRate) =>
      (frames * (TimeCode.baseUnit / getFrameForCalculation(frameRate))).round();
}
