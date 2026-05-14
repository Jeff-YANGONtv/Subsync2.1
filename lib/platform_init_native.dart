// Native init — bootstraps media_kit so the Video widget works.
import 'package:media_kit/media_kit.dart' as mk;

void platformInit() {
  mk.MediaKit.ensureInitialized();
}
