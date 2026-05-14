import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/editor_state.dart';
import 'ui/screens/editor_screen.dart';
import 'platform_init_stub.dart'
    if (dart.library.io) 'platform_init_native.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  platformInit();
  runApp(const SubtitleSyncApp());
}

class SubtitleSyncApp extends StatelessWidget {
  const SubtitleSyncApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorState(),
      child: MaterialApp(
        title: 'Subtitle Sync',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF4F46E5),
          useMaterial3: true,
          fontFamily: kIsWeb ? null : 'Roboto',
        ),
        home: const EditorScreen(),
      ),
    );
  }
}
