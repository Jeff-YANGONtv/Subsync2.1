enum ContentType { movie, series }

class YgnMetadata {
  final String id;
  final String editorName;
  final ContentType type;
  final String title;
  final int? season;
  final int? episode;
  final String? telegramFileId;
  final String? posterUrl;
  final DateTime createdAt;

  YgnMetadata({
    required this.id,
    required this.editorName,
    required this.type,
    required this.title,
    this.season,
    this.episode,
    this.telegramFileId,
    this.posterUrl,
    required this.createdAt,
  });

  String get autoFilename {
    final prefix = '[ygntv]';
    if (type == ContentType.movie) {
      return '$prefix$title';
    } else {
      final s = season?.toString().padLeft(2, '0') ?? '01';
      final e = episode?.toString().padLeft(2, '0') ?? '01';
      return '$prefix$title-S${s}E$e';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'editor_name': editorName,
      'type': type.name,
      'title': title,
      'season': season,
      'episode': episode,
      'telegram_file_id': telegramFileId,
      'poster_url': posterUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
