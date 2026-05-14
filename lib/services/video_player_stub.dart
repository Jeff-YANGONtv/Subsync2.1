import 'dart:async';

abstract class IVideoController {
  Stream<Duration> get positionStream;
  Duration get position;
  Duration get duration;
  bool get isPlaying;
  Future<void> open(String uriOrPath);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration to);
  Future<void> dispose();
}

class StubVideoController implements IVideoController {
  final _ctrl = StreamController<Duration>.broadcast();
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _playing = false;
  @override
  Stream<Duration> get positionStream => _ctrl.stream;
  @override
  Duration get position => _pos;
  @override
  Duration get duration => _dur;
  @override
  bool get isPlaying => _playing;
  @override
  Future<void> open(String uriOrPath) async {}
  @override
  Future<void> play() async => _playing = true;
  @override
  Future<void> pause() async => _playing = false;
  @override
  Future<void> seek(Duration to) async {
    _pos = to;
    _ctrl.add(to);
  }
  @override
  Future<void> dispose() async => _ctrl.close();
}

IVideoController createVideoController() => StubVideoController();
