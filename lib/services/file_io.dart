import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../core/subtitle.dart';
import '../formats/format_registry.dart';
import '../ops/encoding_detect.dart';

class OpenedFile {
  final String fileName;
  final String content;
  final String detectedCharset;
  final Subtitle subtitle;
  final String formatName;
  OpenedFile({
    required this.fileName,
    required this.content,
    required this.detectedCharset,
    required this.subtitle,
    required this.formatName,
  });
}

class FileIoService {
  Future<OpenedFile?> openSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'webvtt', 'ass', 'ssa'],
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes ?? Uint8List(0);
    if (bytes.isEmpty) return null;
    final detected = EncodingDetector.detect(bytes);
    final fmt = FormatRegistry.detect(detected.text, file.name);
    final sub = Subtitle()..fileName = file.name;
    fmt.loadSubtitle(sub, detected.text.split(RegExp(r'\r\n|\r|\n')), file.name);
    return OpenedFile(
      fileName: file.name,
      content: detected.text,
      detectedCharset: detected.charsetName,
      subtitle: sub,
      formatName: fmt.name,
    );
  }

  Future<PlatformFile?> openVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: kIsWeb,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  Future<String?> saveSubtitle({
    required Subtitle subtitle,
    required String formatName,
    required String suggestedName,
  }) async {
    final fmt = FormatRegistry.byName(formatName);
    final text = fmt.toText(subtitle, suggestedName);
    final bytes = Uint8List.fromList(utf8.encode(text));
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save subtitle',
      fileName: suggestedName.endsWith(fmt.extension)
          ? suggestedName
          : '$suggestedName${fmt.extension}',
      bytes: bytes,
    );
  }
}
