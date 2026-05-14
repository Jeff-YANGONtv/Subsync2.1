import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/file_io.dart';
import '../../services/waveform_factory.dart';
import '../../services/waveform_svc.dart';
import '../../web_video_glue.dart'
    if (dart.library.io) '../../web_video_glue_stub.dart' as wvg;
import '../editor_state.dart';
import '../responsive/breakpoints.dart';
import '../widgets/op_panels.dart';
import '../widgets/subtitle_table.dart';
import '../widgets/video_panel.dart' as vp;
import '../widgets/waveform_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _fileIo = FileIoService();
  final IWaveformService _waveSvc = createWaveformService();

  Future<void> _openSubtitle() async {
    final result = await _fileIo.openSubtitle();
    if (result == null || !mounted) return;
    context.read<EditorState>().loadFrom(
          subtitle: result.subtitle,
          formatName: result.formatName,
          fileName: result.fileName,
          detectedCharset: result.detectedCharset,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Loaded ${result.fileName} as ${result.formatName} (${result.detectedCharset})')));
  }

  Future<void> _openVideo() async {
    final picked = await _fileIo.openVideo();
    if (picked == null || !mounted) return;
    final state = context.read<EditorState>();

    String src = '';
    if (kIsWeb && picked.bytes != null) {
      // Create blob URL via JS interop and feed the <video> element.
      src = wvg.attachVideoBytes(picked.bytes!, picked.name);
    } else if (picked.path != null) {
      src = picked.path!;
    }
    state.setVideoSource(src);

    // Kick off waveform extraction (real impl per platform).
    state.setWaveformProgress(0);
    state.setWaveform(WaveformData.empty());
    try {
      final w = await _waveSvc.generate(
        filePath: picked.path,
        bytes: picked.bytes,
        targetSamples: 800,
        onProgress: (p) => state.setWaveformProgress(p),
      );
      state.setWaveform(w);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Waveform ready: ${w.peaks.length} peaks, ${w.durationSeconds.toStringAsFixed(1)}s, ${w.sampleRate} Hz')));
      }
    } catch (e) {
      state.setWaveform(WaveformData.empty());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Waveform decode failed: $e')));
      }
    }
  }

  Future<void> _exportSubtitle() async {
    final state = context.read<EditorState>();
    final text = state.exportText();
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    await _fileIo.saveSubtitle(
      subtitle: state.subtitle,
      formatName: state.formatName,
      suggestedName: state.fileName.isEmpty ? 'subtitle' : state.fileName,
    );
  }

  void _openOps() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          children: const [
            TimeShiftPanel(),
            Divider(),
            FpsPanel(),
            Divider(),
            ExportPanel(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final bp = Breakpoints.of(context);
    final fileLabel = state.fileName.isEmpty ? 'Subtitle Sync' : state.fileName;

    final appBar = AppBar(
      title: Text(fileLabel, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
            tooltip: 'Undo',
            onPressed: state.canUndo ? state.undo : null,
            icon: const Icon(Icons.undo)),
        IconButton(
            tooltip: 'Redo',
            onPressed: state.canRedo ? state.redo : null,
            icon: const Icon(Icons.redo)),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'open': _openSubtitle(); break;
              case 'video': _openVideo(); break;
              case 'export': _exportSubtitle(); break;
              case 'all': state.selectAll(); break;
              case 'clear': state.clearSelection(); break;
              case 'merge': state.mergeSelected(); break;
              case 'split': state.splitSelected(); break;
              case 'delete': state.deleteSelected(); break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'open', child: Text('📂  Open subtitle')),
            PopupMenuItem(value: 'video', child: Text('🎬  Open video')),
            PopupMenuItem(value: 'export', child: Text('💾  Export…')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'all', child: Text('Select all')),
            PopupMenuItem(value: 'clear', child: Text('Clear selection')),
            PopupMenuItem(value: 'merge', child: Text('Merge selected')),
            PopupMenuItem(value: 'split', child: Text('Split selected')),
            PopupMenuItem(value: 'delete', child: Text('Delete selected')),
          ],
        ),
      ],
    );

    Widget body;
    switch (bp) {
      case Breakpoint.mobile:
        body = Column(children: const [
          SizedBox(height: 200, child: vp.PlatformVideoPanel()),
          SizedBox(
              height: 100,
              child: Padding(
                  padding: EdgeInsets.all(8), child: WaveformPanel())),
          Expanded(child: SubtitleTable()),
        ]);
        break;
      case Breakpoint.tablet:
        body = Row(children: const [
          Expanded(
              flex: 5,
              child: Column(children: [
                Expanded(child: vp.PlatformVideoPanel()),
                SizedBox(
                    height: 100,
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: WaveformPanel())),
              ])),
          VerticalDivider(width: 1),
          Expanded(flex: 4, child: SubtitleTable()),
        ]);
        break;
      case Breakpoint.desktop:
        body = Row(children: const [
          Expanded(flex: 4, child: vp.PlatformVideoPanel()),
          VerticalDivider(width: 1),
          Expanded(
              flex: 4,
              child: Column(children: [
                Expanded(child: SubtitleTable()),
                SizedBox(
                    height: 130,
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: WaveformPanel())),
              ])),
          VerticalDivider(width: 1),
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(children: [
                TimeShiftPanel(),
                Divider(),
                FpsPanel(),
                Divider(),
                ExportPanel(),
              ]),
            ),
          ),
        ]);
        break;
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: bp == Breakpoint.desktop
          ? null
          : FloatingActionButton.extended(
              onPressed: _openOps,
              icon: const Icon(Icons.tune),
              label: const Text('Tools')),
      bottomNavigationBar: bp == Breakpoint.mobile
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                      onPressed: _openSubtitle,
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Open subtitle'),
                  IconButton(
                      onPressed: _openVideo,
                      icon: const Icon(Icons.movie),
                      tooltip: 'Open video'),
                  IconButton(
                      onPressed: () =>
                          context.read<EditorState>().mergeSelected(),
                      icon: const Icon(Icons.merge_type),
                      tooltip: 'Merge'),
                  IconButton(
                      onPressed: () =>
                          context.read<EditorState>().splitSelected(),
                      icon: const Icon(Icons.call_split),
                      tooltip: 'Split'),
                  IconButton(
                      onPressed: _exportSubtitle,
                      icon: const Icon(Icons.save),
                      tooltip: 'Export'),
                ],
              ),
            )
          : null,
    );
  }
}
