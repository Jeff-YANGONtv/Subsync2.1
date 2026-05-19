import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
import '../../core/ygn_models.dart';
import '../../services/ygn_service.dart';

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
  }

  Future<void> _openVideo() async {
    final picked = await _fileIo.openVideo();
    if (picked == null || !mounted) return;
    final state = context.read<EditorState>();

    String src = '';
    if (kIsWeb && picked.bytes != null) {
      src = wvg.attachVideoBytes(picked.bytes!, picked.name);
    } else if (picked.path != null) {
      src = picked.path!;
    }
    state.setVideoSource(src);

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
    } catch (e) {
      state.setWaveform(WaveformData.empty());
    }
  }

  void _saveLocally() async {
    final state = context.read<EditorState>();
    await _fileIo.saveSubtitle(
      subtitle: state.subtitle,
      formatName: state.formatName,
      suggestedName: state.fileName.isEmpty ? 'subtitle' : state.fileName,
    );
  }

  void _showTeamDriveForm() {
    final state = context.read<EditorState>();
    final editorController = TextEditingController();
    final titleController = TextEditingController();
    final seasonController = TextEditingController(text: '1');
    final episodeController = TextEditingController(text: '1');
    ContentType selectedType = ContentType.movie;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send to Team Drive'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: editorController, decoration: const InputDecoration(labelText: 'Editor Name')),
                DropdownButtonFormField<ContentType>(
                  value: selectedType,
                  onChanged: (v) => setState(() => selectedType = v!),
                  items: ContentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                if (selectedType == ContentType.series) ...[
                  TextField(controller: seasonController, decoration: const InputDecoration(labelText: 'Season'), keyboardType: TextInputType.number),
                  TextField(controller: episodeController, decoration: const InputDecoration(labelText: 'Episode'), keyboardType: TextInputType.number),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final metadata = YgnMetadata(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  editorName: editorController.text,
                  type: selectedType,
                  title: titleController.text,
                  season: selectedType == ContentType.series ? int.tryParse(seasonController.text) : null,
                  episode: selectedType == ContentType.series ? int.tryParse(episodeController.text) : null,
                  createdAt: DateTime.now(),
                );

                Navigator.pop(context);
                _processUpload(metadata);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processUpload(YgnMetadata metadata) async {
    final state = context.read<EditorState>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Uploading to Team Drive...')));

    try {
      final posterUrl = await YgnService.instance.fetchPoster(metadata.title);
      final content = state.exportText();
      final bytes = content.codeUnits;
      
      final tempMetadata = YgnMetadata(
        id: metadata.id,
        editorName: metadata.editorName,
        type: metadata.type,
        title: metadata.title,
        season: metadata.season,
        episode: metadata.episode,
        posterUrl: posterUrl,
        createdAt: metadata.createdAt,
      );

      final filename = '${tempMetadata.autoFilename}.srt';
      final fileId = await YgnService.instance.uploadToTelegram(bytes, filename);
      
      final finalMetadata = YgnMetadata(
        id: metadata.id,
        editorName: metadata.editorName,
        type: metadata.type,
        title: metadata.title,
        season: metadata.season,
        episode: metadata.episode,
        posterUrl: posterUrl,
        telegramFileId: fileId,
        createdAt: metadata.createdAt,
      );

      await YgnService.instance.saveMetadata(finalMetadata);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Successfully sent to Team Drive!')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
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
    final fileLabel = state.fileName.isEmpty ? 'YGN Subtitle Studio' : state.fileName;

    return Scaffold(
      appBar: AppBar(
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
              PopupMenuDivider(),
              PopupMenuItem(value: 'all', child: Text('Select all')),
              PopupMenuItem(value: 'clear', child: Text('Clear selection')),
              PopupMenuItem(value: 'merge', child: Text('Merge selected')),
              PopupMenuItem(value: 'split', child: Text('Split selected')),
              PopupMenuItem(value: 'delete', child: Text('Delete selected')),
            ],
          ),
        ],
      ),
      body: _buildBody(bp),
      floatingActionButton: SpeedDial(
        icon: Icons.save,
        activeIcon: Icons.close,
        children: [
          SpeedDialChild(child: const Icon(Icons.save_alt), label: 'Save Locally', onTap: _saveLocally),
          SpeedDialChild(child: const Icon(Icons.cloud_upload), label: 'Send To Team Drive', onTap: _showTeamDriveForm),
          SpeedDialChild(child: const Icon(Icons.history), label: 'Version History', onTap: () {}),
          SpeedDialChild(child: const Icon(Icons.tune), label: 'Tools', onTap: _openOps),
        ],
      ),
    );
  }

  Widget _buildBody(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return Column(children: const [
          SizedBox(height: 200, child: vp.PlatformVideoPanel()),
          SizedBox(height: 100, child: Padding(padding: EdgeInsets.all(8), child: WaveformPanel())),
          Expanded(child: SubtitleTable()),
        ]);
      default:
        return Row(children: const [
          Expanded(flex: 5, child: Column(children: [
            Expanded(child: vp.PlatformVideoPanel()),
            SizedBox(height: 100, child: Padding(padding: EdgeInsets.all(8), child: WaveformPanel())),
          ])),
          VerticalDivider(width: 1),
          Expanded(flex: 4, child: SubtitleTable()),
        ]);
    }
  }
}
