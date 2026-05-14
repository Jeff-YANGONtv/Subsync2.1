// Conditional re-export — web uses HTML5 <video>, native uses media_kit.
export 'video_panel_stub.dart'
    if (dart.library.io) 'video_panel_native.dart';
