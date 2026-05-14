// Custom-painted waveform with playhead, cue blocks, and pinch-zoom.
// Uses real peaks from the platform waveform service.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../editor_state.dart';

class WaveformPanel extends StatefulWidget {
  const WaveformPanel({super.key});

  @override
  State<WaveformPanel> createState() => _WaveformPanelState();
}

class _WaveformPanelState extends State<WaveformPanel> {
  double _zoom = 1;
  int? _draggingIndex;
  bool _draggingStart = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final w = state.waveform;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: (d) =>
                setState(() => _zoom = (_zoom * d.scale).clamp(0.5, 5)),
            onPanStart: (d) {
              final state = context.read<EditorState>();
              final w = state.waveform;
              if (w.durationSeconds <= 0) return;
              final RenderBox box = context.findRenderObject() as RenderBox;
              final width = box.size.width;
              final pxPerSec = width / w.durationSeconds;
              final tapSec = d.localPosition.dx / pxPerSec;

              for (var i = 0; i < state.subtitle.paragraphs.length; i++) {
                final p = state.subtitle.paragraphs[i];
                final s = p.startTime.totalMilliseconds / 1000.0;
                final e = p.endTime.totalMilliseconds / 1000.0;
                const threshold = 0.2; // 200ms hit area
                if ((tapSec - s).abs() < threshold) {
                  _draggingIndex = i;
                  _draggingStart = true;
                  return;
                }
                if ((tapSec - e).abs() < threshold) {
                  _draggingIndex = i;
                  _draggingStart = false;
                  return;
                }
              }
            },
            onPanUpdate: (d) {
              if (_draggingIndex == null) return;
              final state = context.read<EditorState>();
              final w = state.waveform;
              final RenderBox box = context.findRenderObject() as RenderBox;
              final width = box.size.width;
              final pxPerSec = width / w.durationSeconds;
              final newSec = d.localPosition.dx / pxPerSec;
              final newMs = newSec * 1000.0;

              if (_draggingStart) {
                state.updateParagraph(_draggingIndex!, startMs: newMs);
              } else {
                state.updateParagraph(_draggingIndex!, endMs: newMs);
              }
            },
            onPanEnd: (_) => _draggingIndex = null,
            onTapDown: (d) {
              // Tap to seek (best-effort: works only when duration known).
              if (w.durationSeconds <= 0) return;
              final RenderBox box = context.findRenderObject() as RenderBox;
              final width = box.size.width;
              final ratio = d.localPosition.dx / width;
              final newMs = (ratio * w.durationSeconds * 1000).round();
              state.setVideoPosition(Duration(milliseconds: newMs),
                  seekPlayer: true);
            },
            child: LayoutBuilder(
              builder: (ctx, c) => CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _WaveformPainter(
                  peaks: w.peaks,
                  duration: w.durationSeconds,
                  paragraphs: state.subtitle.paragraphs,
                  playheadSeconds:
                      state.videoPosition.inMilliseconds / 1000.0,
                  zoom: _zoom,
                  currentIndex:
                      state.currentParagraphIndex(state.videoPosition),
                ),
              ),
            ),
          ),
          if (state.waveformLoading)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Decoding audio… ${(state.waveformProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: state.waveformProgress),
                ],
              ),
            ),
          if (!state.waveformLoading && w.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Open a video/audio file to render waveform',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double duration;
  final List paragraphs;
  final double playheadSeconds;
  final double zoom;
  final int? currentIndex;

  _WaveformPainter({
    required this.peaks,
    required this.duration,
    required this.paragraphs,
    required this.playheadSeconds,
    required this.zoom,
    required this.currentIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    // Grid (every 1s).
    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    if (duration > 0) {
      final pxPerSec = size.width * zoom / duration;
      for (var s = 0; s <= duration.ceil(); s++) {
        final x = s * pxPerSec;
        if (x > size.width) break;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    // Waveform peaks.
    if (peaks.isNotEmpty) {
      final p = Paint()
        ..color = const Color(0xFF60A5FA)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final step = peaks.length / size.width;
      for (var x = 0; x < size.width; x++) {
        final idx = (x * step).floor().clamp(0, peaks.length - 1);
        final v = peaks[idx].abs().clamp(0.0, 1.0) * mid * 0.9;
        canvas.drawLine(
            Offset(x.toDouble(), mid - v), Offset(x.toDouble(), mid + v), p);
      }
    }

    // Cue overlays.
    if (duration > 0 && paragraphs.isNotEmpty) {
      final pxPerSec = size.width / duration;
      for (var i = 0; i < paragraphs.length; i++) {
        final pg = paragraphs[i];
        final x1 = (pg.startTime.totalMilliseconds / 1000.0) * pxPerSec;
        final x2 = (pg.endTime.totalMilliseconds / 1000.0) * pxPerSec;
        final rect = Rect.fromLTRB(x1, mid - 18, x2, mid + 18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..color = (i == currentIndex
                    ? Colors.amber
                    : const Color(0xFF22D3EE))
                .withOpacity(0.30),
        );
      }
    }

    // Playhead.
    if (duration > 0) {
      final pxPerSec = size.width / duration;
      final x = playheadSeconds * pxPerSec;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.peaks != peaks ||
      old.playheadSeconds != playheadSeconds ||
      old.zoom != zoom ||
      old.currentIndex != currentIndex;
}
