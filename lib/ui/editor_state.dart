import 'package:flutter/foundation.dart';
import '../core/paragraph.dart';
import '../core/subtitle.dart';
import '../core/time_code.dart';
import '../formats/format_registry.dart';
import '../ops/fps_convert.dart';
import '../ops/merge_split.dart';
import '../ops/time_shift.dart';
import '../services/waveform_svc.dart';

class EditorState extends ChangeNotifier {
  Subtitle _subtitle = Subtitle();
  String _formatName = 'SubRip';
  String _detectedCharset = '';
  String _fileName = '';
  final List<int> _selected = [];
  final List<Subtitle> _undoStack = [];
  final List<Subtitle> _redoStack = [];
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  String? _videoSource;
  WaveformData _waveform = WaveformData.empty();
  double _waveformProgress = 0;
  bool _waveformLoading = false;

  Subtitle get subtitle => _subtitle;
  String get formatName => _formatName;
  String get detectedCharset => _detectedCharset;
  String get fileName => _fileName;
  List<int> get selected => List.unmodifiable(_selected);
  Duration get videoPosition => _videoPosition;
  Duration get videoDuration => _videoDuration;
  String? get videoSource => _videoSource;
  WaveformData get waveform => _waveform;
  double get waveformProgress => _waveformProgress;
  bool get waveformLoading => _waveformLoading;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _snapshot() {
    _undoStack.add(Subtitle.copy(_subtitle));
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(Subtitle.copy(_subtitle));
    _subtitle = _undoStack.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(Subtitle.copy(_subtitle));
    _subtitle = _redoStack.removeLast();
    notifyListeners();
  }

  void loadFrom({
    required Subtitle subtitle,
    required String formatName,
    required String fileName,
    required String detectedCharset,
  }) {
    _subtitle = subtitle;
    _formatName = formatName;
    _fileName = fileName;
    _detectedCharset = detectedCharset;
    _selected.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  void setFormat(String name) {
    _formatName = name;
    notifyListeners();
  }

  void toggleSelect(int index) {
    if (_selected.contains(index)) {
      _selected.remove(index);
    } else {
      _selected.add(index);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void selectAll() {
    _selected
      ..clear()
      ..addAll(List.generate(_subtitle.paragraphs.length, (i) => i));
    notifyListeners();
  }

  void updateParagraph(int index,
      {String? text, double? startMs, double? endMs}) {
    _snapshot();
    final p = _subtitle.paragraphs[index];
    if (text != null) p.text = text;
    if (startMs != null) p.startTime = TimeCode(startMs);
    if (endMs != null) p.endTime = TimeCode(endMs);
    notifyListeners();
  }

  void insertParagraphAfter(int index) {
    _snapshot();
    final prev = _subtitle.paragraphs[index];
    final p = Paragraph(
      startTime: TimeCode(prev.endTime.totalMilliseconds + 100),
      endTime: TimeCode(prev.endTime.totalMilliseconds + 2100),
    );
    _subtitle.paragraphs.insert(index + 1, p);
    _subtitle.renumber();
    notifyListeners();
  }

  void deleteSelected() {
    if (_selected.isEmpty) return;
    _snapshot();
    final sorted = [..._selected]..sort((a, b) => b.compareTo(a));
    for (final i in sorted) {
      _subtitle.paragraphs.removeAt(i);
    }
    _selected.clear();
    _subtitle.renumber();
    notifyListeners();
  }

  void shiftMs(double ms, {bool onlySelected = false}) {
    _snapshot();
    TimeShiftOp.shiftAll(_subtitle, ms,
        selectedIndexes: onlySelected ? _selected : null);
    notifyListeners();
  }

  void linearSync(double firstNewMs, double lastNewMs) {
    _snapshot();
    TimeShiftOp.linearSync(_subtitle,
        firstNewMs: firstNewMs, lastNewMs: lastNewMs);
    notifyListeners();
  }

  void changeFps(double oldFps, double newFps) {
    _snapshot();
    FpsConvertOp.convert(_subtitle, oldFps, newFps);
    notifyListeners();
  }

  void mergeSelected() {
    if (_selected.length < 2) return;
    _snapshot();
    MergeSplitOp.merge(_subtitle, [..._selected]);
    _selected.clear();
    notifyListeners();
  }

  void splitSelected({double ratio = 0.5}) {
    if (_selected.length != 1) return;
    _snapshot();
    MergeSplitOp.splitAt(_subtitle, _selected.first, ratio: ratio);
    notifyListeners();
  }

  void setVideoPosition(Duration d, {bool seekPlayer = false}) {
    _videoPosition = d;
    if (seekPlayer) {
      // This will be listened to by the video panel
      _seekRequest = d;
    }
    notifyListeners();
  }

  Duration? _seekRequest;
  Duration? consumeSeekRequest() {
    final r = _seekRequest;
    _seekRequest = null;
    return r;
  }

  void setVideoDuration(Duration d) {
    _videoDuration = d;
    notifyListeners();
  }

  void setVideoSource(String? src) {
    _videoSource = src;
    notifyListeners();
  }

  void setWaveform(WaveformData w) {
    _waveform = w;
    _waveformLoading = false;
    _waveformProgress = 1.0;
    notifyListeners();
  }

  void setWaveformProgress(double p) {
    _waveformProgress = p;
    _waveformLoading = p < 1.0;
    notifyListeners();
  }

  int? currentParagraphIndex(Duration position) {
    final ms = position.inMilliseconds.toDouble();
    for (var i = 0; i < _subtitle.paragraphs.length; i++) {
      final p = _subtitle.paragraphs[i];
      if (ms >= p.startTime.totalMilliseconds &&
          ms <= p.endTime.totalMilliseconds) {
        return i;
      }
    }
    return null;
  }

  String exportText() =>
      FormatRegistry.byName(_formatName).toText(_subtitle, _fileName);
}
