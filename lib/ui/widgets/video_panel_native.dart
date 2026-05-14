// Native (Android/iOS/desktop) video panel — uses media_kit Video widget.
// Subscribes to position/duration streams and pushes them into EditorState.

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:provider/provider.dart';
import '../editor_state.dart';

class PlatformVideoPanel extends StatefulWidget {
  const PlatformVideoPanel({super.key});

  @override
  State<PlatformVideoPanel> createState() => _PlatformVideoPanelState();
}

class _PlatformVideoPanelState extends State<PlatformVideoPanel> {
  late final mk.Player _player;
  late final mkv.VideoController _controller;
  String? _opened;

  @override
  void initState() {
    super.initState();
    _player = mk.Player();
    _controller = mkv.VideoController(_player);
    _player.stream.position.listen((pos) {
      if (mounted) context.read<EditorState>().setVideoPosition(pos);
    });
    _player.stream.duration.listen((dur) {
      if (mounted) context.read<EditorState>().setVideoDuration(dur);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final seekReq = state.consumeSeekRequest();
    if (seekReq != null) {
      _player.seek(seekReq);
    }
    final src = state.videoSource;
    if (src == null) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('🎬  No video loaded',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    if (_opened != src) {
      _opened = src;
      _player.open(mk.Media(src), play: false);
    }
    final currentIdx = state.currentParagraphIndex(state.videoPosition);
    final overlay =
        currentIdx == null ? null : state.subtitle.paragraphs[currentIdx].text;
    return Stack(
      fit: StackFit.expand,
      children: [
        mkv.Video(controller: _controller),
        if (overlay != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Align(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(overlay,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.3)),
              ),
            ),
          ),
      ],
    );
  }
}
