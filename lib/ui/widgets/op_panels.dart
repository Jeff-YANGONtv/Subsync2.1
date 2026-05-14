import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../formats/format_registry.dart';
import '../../ops/fps_convert.dart';
import '../editor_state.dart';

class TimeShiftPanel extends StatefulWidget {
  const TimeShiftPanel({super.key});
  @override
  State<TimeShiftPanel> createState() => _TimeShiftPanelState();
}

class _TimeShiftPanelState extends State<TimeShiftPanel> {
  final _ms = TextEditingController(text: '0');
  bool _onlySelected = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shift time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ms,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                    labelText: 'Milliseconds',
                    helperText: 'Negative = earlier, Positive = later'),
              ),
            ),
            const SizedBox(width: 8),
            ..._chip('-500', -500),
            ..._chip('+500', 500),
          ]),
          CheckboxListTile(
            value: _onlySelected,
            onChanged: state.selected.isEmpty
                ? null
                : (v) => setState(() => _onlySelected = v ?? false),
            title: Text('Only selected (${state.selected.length})'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.timer),
              onPressed: () {
                final ms = double.tryParse(_ms.text);
                if (ms != null) {
                  state.shiftMs(ms, onlySelected: _onlySelected);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Shifted by ${ms.toStringAsFixed(0)} ms')));
                }
              },
              label: const Text('Apply shift'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _chip(String label, double ms) => [
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: () => _ms.text =
              ((double.tryParse(_ms.text) ?? 0) + ms).toStringAsFixed(0),
          child: Text(label),
        ),
      ];
}

class FpsPanel extends StatefulWidget {
  const FpsPanel({super.key});
  @override
  State<FpsPanel> createState() => _FpsPanelState();
}

class _FpsPanelState extends State<FpsPanel> {
  double _old = 23.976;
  double _new = 25.0;
  @override
  Widget build(BuildContext context) {
    final state = context.read<EditorState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Convert frame rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _fpsDropdown(
                    'From', _old, (v) => setState(() => _old = v))),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 12),
            Expanded(
                child: _fpsDropdown(
                    'To', _new, (v) => setState(() => _new = v))),
          ]),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.swap_horiz),
              onPressed: () {
                state.changeFps(_old, _new);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Converted ${FpsConvertOp.label(_old)} → ${FpsConvertOp.label(_new)}')));
              },
              label: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fpsDropdown(String label, double value, ValueChanged<double> on) =>
      InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: value,
            isExpanded: true,
            items: FpsConvertOp.commonFps
                .map((f) => DropdownMenuItem(
                    value: f, child: Text(FpsConvertOp.label(f))))
                .toList(),
            onChanged: (v) => v == null ? null : on(v),
          ),
        ),
      );
}

class ExportPanel extends StatelessWidget {
  const ExportPanel({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export / Convert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Output format'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.formatName,
                isExpanded: true,
                items: FormatRegistry.all
                    .map((f) =>
                        DropdownMenuItem(value: f.name, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => v == null ? null : state.setFormat(v),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Detected charset: ${state.detectedCharset.isEmpty ? "—" : state.detectedCharset}',
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
