# Subtitle Sync — Flutter PWA + Native Mobile Subtitle Editor

A mobile-responsive subtitle editor with **core logic ported from
[SubtitleEdit](https://github.com/SubtitleEdit/subtitleedit)** (`src/libse/`)
into pure Dart. **v0.2** adds real native mobile playback via
[`media_kit`](https://pub.dev/packages/media_kit), native waveform extraction
via [`just_waveform`](https://pub.dev/packages/just_waveform), and a real
**Web Audio API** waveform pipeline for the PWA.

## ✨ Features

- **Subtitle formats**: SRT, WebVTT, SSA, ASS (full parse + round-trip)
- **Sync**: time-shift (file / selection), two-point linear sync
- **FPS conversion**: NTSC-aware (23.976 / 29.97 / 59.94 normalisation)
- **Editing**: merge, split, insert, delete, edit, 50-level undo/redo
- **Encoding detect**: UTF-8 / UTF-8 BOM / UTF-16 LE/BE / Windows-1252 / GBK / Shift_JIS
- **Video preview**:
  - Web → HTML5 `<video>` (Blob URL + `HtmlElementView`)
  - Native (Android/iOS/Linux/macOS/Windows) → `media_kit`
- **Real waveform**:
  - Web → `AudioContext.decodeAudioData` (Web Audio API) + per-pixel peak down-sampling
  - Native → `just_waveform` (ExoPlayer / AVAudioFile) → resampled to UI buckets
- **Responsive UI**: mobile (<600) / tablet (<1024) / desktop (≥1024)
- **PWA**: offline-capable, installable, mobile-first

## 🏗️ Architecture (port mapping)

| C# (SubtitleEdit `src/libse/`) | Dart (`lib/`) |
|---|---|
| `Common/TimeCode.cs` | `core/time_code.dart` |
| `Common/Paragraph.cs` | `core/paragraph.dart` |
| `Common/Subtitle.cs` | `core/subtitle.dart` |
| `SubtitleFormats/SubtitleFormat.cs` | `core/subtitle_format.dart` |
| `SubtitleFormats/SubRip.cs` | `formats/sub_rip.dart` |
| `SubtitleFormats/WebVTT.cs` | `formats/web_vtt.dart` |
| `SubtitleFormats/SubStationAlpha.cs` + `AdvancedSubStationAlpha.cs` | `formats/sub_station_alpha.dart` |
| `Subtitle.AddTimeToAllParagraphs` | `ops/time_shift.dart` |
| `Subtitle.ChangeFrameRate` + `GetFrameForCalculation` | `ops/fps_convert.dart` |
| `DialogSplitMerge.cs` | `ops/merge_split.dart` |
| `DetectEncoding/EncodingTools.cs` + `LanguageAutoDetect.DetectAnsiEncoding` | `ops/encoding_detect.dart` |

## 🎯 Platform plug-in matrix

| Capability | Web | Android/iOS | Desktop |
|---|---|---|---|
| Video playback | HTML5 `<video>` (`web_video_glue.dart`) | media_kit (ExoPlayer / AVPlayer) | media_kit (libmpv) |
| Waveform | `AudioContext.decodeAudioData` (`waveform_web.dart`) | just_waveform → resample (`waveform_native.dart`) | just_waveform / ffmpeg (`waveform_native.dart`) |
| File picker | `<input type=file>` via file_picker_web | file_picker (SAF / UIDocumentPicker) | file_picker (native dialogs) |
| Save | Browser download | file_picker `saveFile()` | OS save dialog |

All platform-specific code is gated by **conditional imports**:

```dart
import 'waveform_web.dart' if (dart.library.io) 'waveform_native.dart' as impl;
```

→ Web build does NOT pull native code; native build does NOT pull `package:web`.

## 🔬 Real Web Audio waveform pipeline

```
File bytes (Uint8List)
   ↓
Blob → blob.arrayBuffer()  ←─── solves Dart 3.5's missing JSUint8Array.buffer
   ↓
OfflineAudioContext.decodeAudioData(arrayBuffer)   (fallback: AudioContext)
   ↓
AudioBuffer (Float32, channel 0)
   ↓
Down-sample to `targetSamples` peaks (max-abs per bucket)
   ↓
WaveformData(peaks, durationSeconds, sampleRate, channels)
```

Browser-native codec support means MP3 / AAC / WAV / OGG / Opus / FLAC all
decode in-process — no FFmpeg, no native binary, fully PWA-friendly.

## 🤖 Real Native waveform pipeline

```
File path (String)
   ↓
just_waveform.extract(audioInFile, waveOutFile, zoom)
   ↓ (stream of progress + final Waveform)
Waveform.data (Int16 min/max pairs)
   ↓
Normalise → resample to `targetSamples` buckets
   ↓
WaveformData(peaks, durationSeconds, sampleRate)
```

`just_waveform` uses `ExoPlayer` on Android and `AVAudioFile` on iOS — both
hardware-accelerated.

## ▶️ Run

```bash
flutter pub get

# Web (PWA) ----------------------------------------------------
flutter run -d chrome
flutter build web --release --pwa-strategy=offline-first

# Native -------------------------------------------------------
flutter run -d android
flutter run -d ios
flutter run -d linux         # or windows, macos
flutter build apk --release
flutter build ios --release
```

## ✅ Tests

19 / 19 pure-Dart core tests pass (no Flutter SDK required):

```bash
dart test_core.dart
```

## 📂 Project structure

```
lib/
├── core/                         # ported data model
├── formats/                      # ported parsers (SRT/VTT/SSA/ASS)
├── ops/                          # ported sync / FPS / merge-split / encoding
├── services/
│   ├── file_io.dart
│   ├── video_player_svc.dart     # conditional re-export
│   ├── video_player_stub.dart    # web
│   ├── video_player_native.dart  # media_kit
│   ├── waveform_svc.dart         # shared types
│   ├── waveform_factory.dart     # conditional re-export
│   ├── waveform_web.dart         # Web Audio API
│   └── waveform_native.dart      # just_waveform
├── ui/
│   ├── responsive/breakpoints.dart
│   ├── editor_state.dart
│   ├── widgets/
│   │   ├── subtitle_table.dart
│   │   ├── video_panel*.dart     # 3 files: re-export + web + native
│   │   ├── waveform_panel.dart   # CustomPainter, pinch-zoom, tap-to-seek
│   │   └── op_panels.dart
│   └── screens/editor_screen.dart
├── web_video_glue.dart           # JS Blob URL + HtmlElementView (web)
├── web_video_glue_stub.dart      # no-op stub (native)
├── platform_init_stub.dart       # web
├── platform_init_native.dart     # MediaKit.ensureInitialized()
└── main.dart
```

## 🪪 License

Core port follows SubtitleEdit's GPL-3.0 license.
