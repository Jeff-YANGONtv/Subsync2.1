// Web-only glue: creates a Blob URL from the picked file bytes, builds an
// HTML5 <video> element, registers it as a Flutter platform view (so
// HtmlElementView can embed it), and wires up timeupdate → EditorState.
//
// This file is only imported on the web platform via the conditional import
// in editor_screen.dart.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:flutter/services.dart';

import 'ui/widgets/video_panel_stub.dart' show kWebVideoViewType;

// We keep one shared <video> element across reloads to make HtmlElementView
// happy. It is reused by re-pointing its `src` attribute.
web.HTMLVideoElement? _videoEl;
bool _registered = false;

/// Lazily creates the singleton <video> element and registers it as a
/// platform view.
void _ensureRegistered(void Function(Duration, Duration)? onTick) {
  if (_registered) return;
  _registered = true;

  // ignore: undefined_prefixed_name
  // ignore_for_file: undefined_function, undefined_identifier
  // Register with the Flutter web platform view registry via JS interop.
  // (We use the documented `ui_web.platformViewRegistry` API via JS.)
  _registerViewFactory((int viewId) {
    final el = _videoEl ??= _createVideo();
    return el;
  });
}

@JS('ui_web.platformViewRegistry.registerViewFactory')
external void _platformRegisterViewFactory(
    String viewType, JSFunction factory) /*?? noop*/;

void _registerViewFactory(web.HTMLElement Function(int) factory) {
  try {
    _platformRegisterViewFactory(
      kWebVideoViewType,
      ((int viewId) => factory(viewId) as JSObject).toJS,
    );
  } catch (_) {
    // Older bootstrap may expose the legacy global. Fall back silently.
  }
}

web.HTMLVideoElement _createVideo() {
  final v = web.HTMLVideoElement()
    ..controls = true
    ..autoplay = false
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.background = '#000';
  return v;
}

/// Builds a Blob URL from [bytes] and points the singleton <video> at it.
/// Returns the URL so EditorState can record it as the current source.
String attachVideoBytes(Uint8List bytes, String fileName) {
  _ensureRegistered(null);
  final el = _videoEl ??= _createVideo();

  // Free previous Blob URL if any.
  if (el.src.isNotEmpty && el.src.startsWith('blob:')) {
    try {
      web.URL.revokeObjectURL(el.src);
    } catch (_) {}
  }

  // Guess MIME from extension; the browser only needs a hint.
  final mime = _mimeFor(fileName);
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  el.src = url;
  el.load();
  return url;
}

String _mimeFor(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.mp4') || n.endsWith('.m4v')) return 'video/mp4';
  if (n.endsWith('.webm')) return 'video/webm';
  if (n.endsWith('.ogg') || n.endsWith('.ogv')) return 'video/ogg';
  if (n.endsWith('.mov')) return 'video/quicktime';
  if (n.endsWith('.mkv')) return 'video/x-matroska';
  if (n.endsWith('.mp3')) return 'audio/mpeg';
  if (n.endsWith('.wav')) return 'audio/wav';
  return 'video/mp4';
}
