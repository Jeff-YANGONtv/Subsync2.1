// Ported from SubtitleEdit: src/libse/Common/Paragraph.cs
import 'time_code.dart';

class Paragraph {
  int number;
  TimeCode startTime;
  TimeCode endTime;
  String text;
  String style;
  String actor;
  String effect;
  int layer;
  int marginL;
  int marginR;
  int marginV;
  bool isComment;

  Paragraph({
    this.number = 0,
    TimeCode? startTime,
    TimeCode? endTime,
    this.text = '',
    this.style = 'Default',
    this.actor = '',
    this.effect = '',
    this.layer = 0,
    this.marginL = 0,
    this.marginR = 0,
    this.marginV = 0,
    this.isComment = false,
  })  : startTime = startTime ?? TimeCode(),
        endTime = endTime ?? TimeCode();

  Paragraph.copy(Paragraph p)
      : number = p.number,
        startTime = p.startTime.clone(),
        endTime = p.endTime.clone(),
        text = p.text,
        style = p.style,
        actor = p.actor,
        effect = p.effect,
        layer = p.layer,
        marginL = p.marginL,
        marginR = p.marginR,
        marginV = p.marginV,
        isComment = p.isComment;

  double get durationMs =>
      endTime.totalMilliseconds - startTime.totalMilliseconds;
  double get durationSeconds => durationMs / TimeCode.baseUnit;

  void adjust(double factor, double adjustmentSeconds) {
    if (startTime.isMaxTime) return;
    startTime.totalMilliseconds =
        startTime.totalMilliseconds * factor +
            adjustmentSeconds * TimeCode.baseUnit;
    endTime.totalMilliseconds =
        endTime.totalMilliseconds * factor +
            adjustmentSeconds * TimeCode.baseUnit;
  }
}
