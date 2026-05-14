import 'package:flutter_test/flutter_test.dart';
import 'package:subtitle_sync/core/subtitle.dart';
import 'package:subtitle_sync/formats/micro_dvd.dart';
import 'package:subtitle_sync/formats/sami.dart';
import 'package:subtitle_sync/formats/ttml.dart';

void main() {
  group('MicroDVD', () {
    final parser = MicroDvd();
    test('detects .sub files', () {
      expect(parser.isMine(['{10}{20}Hello'], 'test.sub'), isTrue);
    });
    test('parses frames correctly', () {
      final sub = Subtitle();
      parser.loadSubtitle(sub, ['{0}{25}Hello|World'], 'test.sub');
      expect(sub.paragraphs.length, 1);
      expect(sub.paragraphs[0].text, 'Hello\nWorld');
      // Default 25fps: 0 frames = 0ms, 25 frames = 1000ms
      expect(sub.paragraphs[0].startTime.totalMilliseconds, 0);
      expect(sub.paragraphs[0].endTime.totalMilliseconds, 1000);
    });
  });

  group('SAMI', () {
    final parser = Sami();
    test('detects .smi files', () {
      expect(parser.isMine(['<SAMI>'], 'test.smi'), isTrue);
    });
    test('parses sync points', () {
      final sub = Subtitle();
      parser.loadSubtitle(sub, [
        '<SAMI>',
        '<SYNC Start=1000><P Class=ENUSCC>Hello',
        '<SYNC Start=2000><P Class=ENUSCC>&nbsp;',
        '</SAMI>'
      ], 'test.smi');
      expect(sub.paragraphs.length, 1);
      expect(sub.paragraphs[0].text, 'Hello');
      expect(sub.paragraphs[0].startTime.totalMilliseconds, 1000);
      expect(sub.paragraphs[0].endTime.totalMilliseconds, 2000);
    });
  });

  group('TTML', () {
    final parser = Ttml();
    test('detects ttml content', () {
      expect(parser.isMine(['<tt xmlns="http://www.w3.org/ns/ttml">'], 'test.xml'), isTrue);
    });
    test('parses begin/end times', () {
      final sub = Subtitle();
      parser.loadSubtitle(sub, [
        '<tt>',
        '<body><div>',
        '<p begin="00:00:01.000" end="00:00:02.500">Hello World</p>',
        '</div></body>',
        '</tt>'
      ], 'test.ttml');
      expect(sub.paragraphs.length, 1);
      expect(sub.paragraphs[0].text, 'Hello World');
      expect(sub.paragraphs[0].startTime.totalMilliseconds, 1000);
      expect(sub.paragraphs[0].endTime.totalMilliseconds, 2500);
    });
  });
}
