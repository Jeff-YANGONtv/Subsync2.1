// Native (Android/iOS/desktop) video controller — backed by media_kit.
//
// media_kit is a cross-platform multimedia library that wraps libmpv on
// desktop and ExoPlayer / AVPlayer on mobile. It exposes a unified Dart API.

import 'dart:async';
import 'package:media_kit/media_kit.dart' as mk;
import 'video_player_stub.dart' show IVideoController;

class MediaKitVideoController implements IVideoController {
  final mk.Player _player = mk.Player();

  /// Native player exposed for the Video widget on the UI layer.
  mk.Player get nativePlayer => _player;

  @override
  Stream<Duration> get positionStream => _player.stream.position;
  @override
  Duration get position => _player.state.position;
  @override
  Duration get duration => _player.state.duration;
  @override
  bool get isPlaying => _player.state.playing;

  @override
  Future<void> open(String uriOrPath) => _player.open(mk.Media(uriOrPath));
  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration to) => _player.seek(to);
  @override
  Future<void> dispose() async => _player.dispose();
}

IVideoController createVideoController() => MediaKitVideoController();
