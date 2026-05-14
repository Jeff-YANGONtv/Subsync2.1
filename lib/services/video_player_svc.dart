// Conditional re-export — picks the right video controller per platform.
//   - Web → video_player_stub.dart (no native deps)
//   - Native → video_player_native.dart (media_kit)
export 'video_player_stub.dart' show IVideoController;

import 'video_player_stub.dart'
    if (dart.library.io) 'video_player_native.dart' as impl;
import 'video_player_stub.dart' show IVideoController;

IVideoController createVideoController() => impl.createVideoController();
