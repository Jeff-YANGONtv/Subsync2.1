// Waveform service public API.
//
// Implementations:
//   - Web    → waveform_web.dart       (Web Audio API + AudioContext.decodeAudioData)
//   - Native → waveform_native.dart    (just_waveform extracts peaks from file path)
//
// Both return the same WaveformData shape so the UI layer is platform-agnostic.

import 'dart:typed_data';

class WaveformData {
  /// Per-sample peak in [-1, 1]. The painter uses .abs() to draw symmetric bars.
  final List<double> peaks;
  /// Source audio duration in seconds (0 if unknown).
  final double durationSeconds;
  /// Source sample rate (Hz). Useful for accurate time-to-pixel mapping.
  final int sampleRate;
  /// Number of audio channels in the original source.
  final int channels;

  WaveformData({
    required this.peaks,
    required this.durationSeconds,
    this.sampleRate = 0,
    this.channels = 0,
  });

  factory WaveformData.empty() =>
      WaveformData(peaks: const [], durationSeconds: 0);

  bool get isEmpty => peaks.isEmpty;
}

abstract class IWaveformService {
  /// Generate [targetSamples] peaks for the given audio/video source.
  ///   - On web pass [bytes] (the in-memory file bytes from FilePicker).
  ///   - On native pass [filePath] (the OS file path).
  Future<WaveformData> generate({
    String? filePath,
    Uint8List? bytes,
    int targetSamples = 800,
    void Function(double progress)? onProgress,
  });
}
