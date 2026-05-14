import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/time_code.dart';
import '../editor_state.dart';

class SubtitleTable extends StatelessWidget {
  const SubtitleTable({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final paragraphs = state.subtitle.paragraphs;
    if (paragraphs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No subtitle loaded.\nTap "Open" to load an SRT / VTT / ASS file.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }
    final current = state.currentParagraphIndex(state.videoPosition);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
      itemCount: paragraphs.length,
      itemBuilder: (ctx, i) {
        final p = paragraphs[i];
        final selected = state.selected.contains(i);
        final active = current == i;
        return Card(
          elevation: selected ? 4 : 1,
          color: selected
              ? Colors.indigo.withOpacity(0.10)
              : active
                  ? Colors.amber.withOpacity(0.12)
                  : null,
          child: InkWell(
            onTap: () => state.toggleSelect(i),
            onLongPress: () => _editDialog(context, state, i),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        active ? Colors.amber : Colors.indigo.shade300,
                    child: Text('${p.number}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(p.startTime.toSrt()),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: const TextStyle(fontSize: 11),
                            ),
                            const Icon(Icons.arrow_forward, size: 14),
                            Chip(
                              label: Text(p.endTime.toSrt()),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelStyle: const TextStyle(fontSize: 11),
                            ),
                            const Spacer(),
                            Text(
                              '${(p.durationMs / 1000).toStringAsFixed(2)} s',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(p.text,
                            style: const TextStyle(fontSize: 15, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editDialog(BuildContext context, EditorState state, int i) {
    final p = state.subtitle.paragraphs[i];
    final textCtrl = TextEditingController(text: p.text);
    final startCtrl = TextEditingController(text: p.startTime.toSrt());
    final endCtrl = TextEditingController(text: p.endTime.toSrt());
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cue #${p.number}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Start (HH:MM:SS,mmm)')),
              TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                      labelText: 'End (HH:MM:SS,mmm)')),
              const SizedBox(height: 8),
              TextField(
                  controller: textCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Text')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              state.updateParagraph(i,
                  text: textCtrl.text,
                  startMs: _parseTime(startCtrl.text),
                  endMs: _parseTime(endCtrl.text));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  double? _parseTime(String s) {
    final m = RegExp(r'(\d+):(\d+):(\d+)[,.](\d+)').firstMatch(s.trim());
    if (m == null) return null;
    return TimeCode.fromHms(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
    ).totalMilliseconds;
  }
}
