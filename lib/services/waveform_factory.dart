// Picks the right waveform implementation per platform via conditional imports.
//
//   - Web   → WebAudioWaveformService  (real peaks from AudioContext)
//   - Native → NativeWaveformService    (real peaks from just_waveform)

import 'waveform_svc.dart';
import 'waveform_web.dart'
    if (dart.library.io) 'waveform_native.dart' as impl;

IWaveformService createWaveformService() => impl.createWaveformService();
