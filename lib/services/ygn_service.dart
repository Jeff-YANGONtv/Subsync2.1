import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../core/ygn_models.dart';

class YgnService {
  static final YgnService instance = YgnService._();
  YgnService._();

  final _dio = Dio();
  
  // These should be configured via environment variables or a config file
  final String _tmdbApiKey = 'YOUR_TMDB_API_KEY';
  final String _telegramBotToken = 'YOUR_TELEGRAM_BOT_TOKEN';
  final String _telegramChatId = 'YOUR_TELEGRAM_CHAT_ID';

  Future<String?> fetchPoster(String title) async {
    try {
      final response = await _dio.get(
        'https://api.themoviedb.org/3/search/multi',
        queryParameters: {
          'api_key': _tmdbApiKey,
          'query': title,
        },
      );
      final results = response.data['results'] as List;
      if (results.isNotEmpty) {
        final path = results[0]['poster_path'] ?? results[0]['backdrop_path'];
        if (path != null) {
          return 'https://image.tmdb.org/t/p/w500$path';
        }
      }
    } catch (e) {
      print('TMDB Error: $e');
    }
    return null;
  }

  Future<String?> uploadToTelegram(List<int> bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'chat_id': _telegramChatId,
        'document': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post(
        'https://api.telegram.org/bot$_telegramBotToken/sendDocument',
        data: formData,
      );
      return response.data['result']['document']['file_id'];
    } catch (e) {
      print('Telegram Error: $e');
      return null;
    }
  }

  Future<void> saveMetadata(YgnMetadata metadata) async {
    await Supabase.instance.client
        .from('subtitles')
        .upsert(metadata.toMap());
  }

  Future<List<YgnMetadata>> fetchAllMetadata() async {
    final response = await Supabase.instance.client
        .from('subtitles')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List).map((data) {
      return YgnMetadata(
        id: data['id'],
        editorName: data['editor_name'],
        type: data['type'] == 'movie' ? ContentType.movie : ContentType.series,
        title: data['title'],
        season: data['season'],
        episode: data['episode'],
        telegramFileId: data['telegram_file_id'],
        posterUrl: data['poster_url'],
        createdAt: DateTime.parse(data['created_at']),
      );
    }).toList();
  }
}
