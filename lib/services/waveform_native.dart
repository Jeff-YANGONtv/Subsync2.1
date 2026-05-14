// Native (Android/iOS/desktop) waveform extraction using just_waveform.
//
// just_waveform extracts peak data from an audio or video file using
// ExoPlayer / AVAudioFile internally. It emits incremental WaveformProgress
// updates and produces a Waveform with .data (Int16) representing min/max
// peaks per pixel.
//
// We convert the Int16 peaks to [-1, 1] doubles and (optionally) re-sample
// them down to the UI's target bucket count.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_waveform/just_waveform.dart' as jw;
import 'package:path_provider/path_provider.dart';

import 'waveform_svc.dart';

class NativeWaveformService implements IWaveformService {
  @override
  Future<WaveformData> generate({
    String? filePath,
    Uint8List? bytes,
    int targetSamples = 800,
    void Function(double progress)? onProgress,
  }) async {
    if (filePath == null) return WaveformData.empty();
    final source = File(filePath);
    if (!source.existsSync()) return WaveformData.empty();

    // just_waveform needs an output file. Write to the OS cache dir.
    final tmpDir = await getTemporaryDirectory();
    final out = File('${tmpDir.path}/wf_${DateTime.now().millisecondsSinceEpoch}.wave');

    final completer = Completer<jw.Waveform>();
    late StreamSubscription<jw.WaveformProgress> sub;
    sub = jw.JustWaveform.extract(
      audioInFile: source,
      waveOutFile: out,
      zoom: jw.WaveformZoom.pixelsPerSecond(targetSamples ~/ 10),
    ).listen((p) {
      onProgress?.call(p.progress);
      if (p.waveform != null && !completer.isCompleted) {
        completer.complete(p.waveform);
      }
    }, onError: (e, _) {
      if (!completer.isCompleted) completer.completeError(e);
    });

    jw.Waveform wf;
    try {
      wf = await completer.future;
    } catch (_) {
      return WaveformData.empty();
    } finally {
      await sub.cancel();
    }

    // wf.data contains pairs of [min, max] Int16 samples — convert to doubles.
    final raw = wf.data;
    final n = raw.length ~/ 2;
    final maxAbs = _maxAbs(raw);
    final scale = maxAbs == 0 ? 1.0 : 1.0 / maxAbs;
    final fullPeaks = List<double>.generate(n, (i) {
      final mn = raw[i * 2].toDouble();
      final mx = raw[i * 2 + 1].toDouble();
      return (mx.abs() > mn.abs() ? mx : mn) * scale;
    });

    // Re-sample to exact targetSamples for stable UI.
    final peaks = _resample(fullPeaks, targetSamples);

    final durationMs = wf.duration.inMilliseconds.toDouble();

    return WaveformData(
      peaks: peaks,
      durationSeconds: durationMs / 1000.0,
      sampleRate: wf.sampleRate,
      channels: 1,
    );
  }

  static int _maxAbs(List<int> data) {
    var m = 0;
    for (final v in data) {
      final a = v.abs();
      if (a > m) m = a;
    }
    return m;
  }

  static List<double> _resample(List<double> src, int target) {
    if (src.length == target) return src;
    if (src.isEmpty) return List<double>.filled(target, 0);
    final out = List<double>.filled(target, 0);
    final step = src.length / target;
    for (var i = 0; i < target; i++) {
      final start = (i * step).floor();
      final end = math.min(((i + 1) * step).ceil(), src.length);
      var peak = 0.0;
      for (var k = start; k < end; k++) {
        final v = src[k].abs();
        if (v > peak) peak = v;
      }
      out[i] = peak;
    }
    return out;
  }
}

IWaveformService createWaveformService() => NativeWaveformService();
