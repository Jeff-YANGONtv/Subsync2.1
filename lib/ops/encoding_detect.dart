import 'dart:convert';
import 'dart:typed_data';

enum DetectedEncoding {
  utf8, utf8Bom, utf16Le, utf16Be,
  windows1252, iso88591, gbk, shiftJis, big5, unknown,
}

class EncodingResult {
  final DetectedEncoding encoding;
  final String charsetName;
  final String text;
  EncodingResult(this.encoding, this.charsetName, this.text);
}

class EncodingDetector {
  static EncodingResult detect(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return EncodingResult(DetectedEncoding.utf8Bom, 'UTF-8 (BOM)',
          utf8.decode(bytes.sublist(3), allowMalformed: true));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return EncodingResult(DetectedEncoding.utf16Le, 'UTF-16 LE',
          _decodeUtf16Le(bytes.sublist(2)));
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return EncodingResult(DetectedEncoding.utf16Be, 'UTF-16 BE',
          _decodeUtf16Be(bytes.sublist(2)));
    }
    try {
      return EncodingResult(DetectedEncoding.utf8, 'UTF-8',
          const Utf8Decoder(allowMalformed: false).convert(bytes));
    } catch (_) {}
    final hint = _scoreByteFrequency(bytes);
    return EncodingResult(hint, _charsetName(hint),
        const Utf8Decoder(allowMalformed: true).convert(bytes));
  }

  static DetectedEncoding _scoreByteFrequency(Uint8List bytes) {
    var doubleByte = 0;
    var highAscii = 0;
    for (var i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      if (b >= 0x80) highAscii++;
      if (b >= 0x81 && b <= 0xFE && i + 1 < bytes.length) {
        final n = bytes[i + 1];
        if (n >= 0x40 && n <= 0xFE) doubleByte++;
      }
    }
    if (highAscii == 0) return DetectedEncoding.windows1252;
    final ratio = doubleByte / bytes.length;
    if (ratio > 0.30) return DetectedEncoding.gbk;
    if (ratio > 0.15) return DetectedEncoding.shiftJis;
    return DetectedEncoding.windows1252;
  }

  static String _charsetName(DetectedEncoding e) {
    switch (e) {
      case DetectedEncoding.utf8: return 'UTF-8';
      case DetectedEncoding.utf8Bom: return 'UTF-8 (BOM)';
      case DetectedEncoding.utf16Le: return 'UTF-16 LE';
      case DetectedEncoding.utf16Be: return 'UTF-16 BE';
      case DetectedEncoding.windows1252: return 'Windows-1252';
      case DetectedEncoding.iso88591: return 'ISO-8859-1';
      case DetectedEncoding.gbk: return 'GBK';
      case DetectedEncoding.shiftJis: return 'Shift_JIS';
      case DetectedEncoding.big5: return 'Big5';
      case DetectedEncoding.unknown: return 'Unknown';
    }
  }

  static String _decodeUtf16Le(Uint8List bytes) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add(bytes[i] | (bytes[i + 1] << 8));
    }
    return String.fromCharCodes(units);
  }

  static String _decodeUtf16Be(Uint8List bytes) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      units.add((bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }
}
