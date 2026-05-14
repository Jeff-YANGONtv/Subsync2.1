import '../core/subtitle.dart';
import '../core/subtitle_format.dart';

class FpsConvertOp {
  static const List<double> commonFps = [
    23.976, 24.0, 25.0, 29.97, 30.0, 50.0, 59.94, 60.0,
  ];

  static void convert(Subtitle subtitle, double oldFps, double newFps) {
    subtitle.changeFrameRate(oldFps, newFps);
  }

  static String label(double fps) {
    if ((fps - 23.976).abs() < 0.001) return '23.976 (NTSC film)';
    if ((fps - 29.97).abs() < 0.001) return '29.97 (NTSC)';
    if ((fps - 59.94).abs() < 0.001) return '59.94 (NTSC)';
    return '${fps.toStringAsFixed(fps == fps.roundToDouble() ? 0 : 3)} fps';
  }

  static double factor(double oldFps, double newFps) =>
      SubtitleFormat.getFrameForCalculation(oldFps) /
      SubtitleFormat.getFrameForCalculation(newFps);
}
