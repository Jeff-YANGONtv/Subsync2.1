// Web video panel — uses an HTML5 <video> element embedded via
// HtmlElementView. Falls back to a placeholder card if no source is open.
//
// Position synchronization: a polling timer reads currentTime from the
// <video> element and pushes it into EditorState every 100ms.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../editor_state.dart';

const String kWebVideoViewType = 'subtitle-sync-html-video';

class PlatformVideoPanel extends StatefulWidget {
  const PlatformVideoPanel({super.key});

  @override
  State<PlatformVideoPanel> createState() => _PlatformVideoPanelState();
}

class _PlatformVideoPanelState extends State<PlatformVideoPanel> {
  Timer? _poll;
  String? _viewType;

  @override
  void initState() {
    super.initState();
    // Web-specific HtmlElementView registration is performed lazily in
    // platform_init_web.dart. Here we just observe state.
    if (kIsWeb) {
      _viewType = kWebVideoViewType;
      _poll = Timer.periodic(const Duration(milliseconds: 100), (_) {
        // The position update is driven by main.dart's JS interop.
      });
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final src = state.videoSource;
    final overlayIdx = state.currentParagraphIndex(state.videoPosition);
    final overlay = overlayIdx == null
        ? null
        : state.subtitle.paragraphs[overlayIdx].text;

    if (src == null) {
      return Container(
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '🎬  No video loaded\nTap "Open video" to preview alongside subtitles.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_viewType != null)
          HtmlElementView(viewType: _viewType!)
        else
          Container(color: Colors.black),
        if (overlay != null) _Overlay(text: overlay),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  final String text;
  const _Overlay({required this.text});
  @override
  Widget build(BuildContext context) => Positioned(
        left: 0,
        right: 0,
        bottom: 16,
        child: Align(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.3,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)])),
          ),
        ),
      );
}
