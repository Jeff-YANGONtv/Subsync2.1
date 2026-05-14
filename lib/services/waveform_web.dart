// Real Web Audio API waveform extraction (web-only).
//
// Pipeline:
//   1. Get the in-memory bytes of the audio/video file from FilePicker.
//   2. Wrap bytes in a Blob, then await Blob.arrayBuffer() to get an
//      ArrayBuffer suitable for decodeAudioData().
//   3. Create an OfflineAudioContext (or AudioContext fallback).
//   4. ctx.decodeAudioData(arrayBuffer) → AudioBuffer with PCM float32.
//   5. Down-sample channel 0 to `targetSamples` peaks (max-abs per bucket).

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'waveform_svc.dart';

// ---- JS interop bindings ----------------------------------------------------

@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external JSPromise<_AudioBuffer> decodeAudioData(JSArrayBuffer data);
  external JSPromise<JSAny?> close();
}

@JS('OfflineAudioContext')
extension type _OfflineAudioContext._(JSObject _) implements JSObject {
  external factory _OfflineAudioContext(
      int numberOfChannels, int length, int sampleRate);
  external JSPromise<_AudioBuffer> decodeAudioData(JSArrayBuffer data);
}

extension type _AudioBuffer._(JSObject _) implements JSObject {
  external int get sampleRate;
  external int get length;
  external double get duration;
  external int get numberOfChannels;
  external JSFloat32Array getChannelData(int channel);
}

/// Convert Dart bytes → JS ArrayBuffer via the Blob round-trip.
/// This avoids the absent JSUint8Array.buffer getter on older Dart SDKs.
Future<JSArrayBuffer> _bytesToArrayBuffer(Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  return await blob.arrayBuffer().toDart;
}

class WebAudioWaveformService implements IWaveformService {
  @override
  Future<WaveformData> generate({
    String? filePath,
    Uint8List? bytes,
    int targetSamples = 800,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes == null || bytes.isEmpty) return WaveformData.empty();
    onProgress?.call(0.05);

    final ab1 = await _bytesToArrayBuffer(bytes);

    _AudioBuffer? buf;
    try {
      final oac = _OfflineAudioContext(1, 1, 22050);
      buf = await oac.decodeAudioData(ab1).toDart;
    } catch (_) {
      try {
        // decodeAudioData detaches the buffer on failure — fetch a fresh one.
        final ab2 = await _bytesToArrayBuffer(bytes);
        final ac = _AudioContext();
        buf = await ac.decodeAudioData(ab2).toDart;
        try {
          await ac.close().toDart;
        } catch (_) {}
      } catch (_) {
        return WaveformData.empty();
      }
    }

    onProgress?.call(0.6);

    final channels = buf!.numberOfChannels;
    final sampleRate = buf.sampleRate;
    final totalSamples = buf.length;
    final duration = buf.duration;

    final ch0 = buf.getChannelData(0).toDart;

    final bucketSize = math.max(1, (totalSamples / targetSamples).ceil());
    final peaks = List<double>.filled(targetSamples, 0.0);
    for (var i = 0; i < targetSamples; i++) {
      final start = i * bucketSize;
      final end = math.min(start + bucketSize, totalSamples);
      var peak = 0.0;
      for (var k = start; k < end; k++) {
        final v = ch0[k].abs();
        if (v > peak) peak = v;
      }
      peaks[i] = peak;
      if (onProgress != null && i % 50 == 0) {
        onProgress(0.6 + 0.4 * (i / targetSamples));
      }
    }
    onProgress?.call(1.0);

    return WaveformData(
      peaks: peaks,
      durationSeconds: duration,
      sampleRate: sampleRate,
      channels: channels,
    );
  }
}

IWaveformService createWaveformService() => WebAudioWaveformService();
