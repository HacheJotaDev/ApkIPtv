import '../models/channel.dart';
import '../models/movie.dart';
import '../models/category.dart';
import '../utils/text_utils.dart';

class M3uParser {
  static Map<String, dynamic> parseM3u(String content) {
    // Remove BOM if present
    String cleanContent = content;
    if (cleanContent.startsWith('\uFEFF')) {
      cleanContent = cleanContent.substring(1);
    }

    // Normalize line endings
    cleanContent = cleanContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final lines = cleanContent.split('\n');
    final List<Channel> channels = [];
    final List<Movie> movies = [];
    final List<Category> categories = [];
    final Set<String> seenCategories = {};

    String? currentName;
    String? currentLogo;
    String? currentGroup;
    String? currentId;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXTINF:')) {
        currentName = TextUtils.cleanText(_extractAttribute(line, ',') ?? 'Sin nombre');
        currentLogo = _extractAttribute(line, 'tvg-logo="');
        currentGroup = TextUtils.cleanText(_extractAttribute(line, 'group-title="'));
        currentId = _extractAttribute(line, 'tvg-id="');

        if (currentGroup != null && currentGroup.isNotEmpty && !seenCategories.contains(currentGroup)) {
          seenCategories.add(currentGroup);
          final isVod = _isVodGroup(currentGroup);
          categories.add(Category(
            id: currentGroup,
            name: currentGroup,
            type: isVod ? 'vod' : 'live',
          ));
        }
      } else if (line.isNotEmpty && !line.startsWith('#') && currentName != null) {
        final url = line;
        final group = currentGroup ?? 'Sin categoria';
        final isVod = _isVodUrl(url) || _isVodGroup(group);

        if (isVod) {
          movies.add(Movie.fromM3u({
            'id': currentId ?? '${DateTime.now().millisecondsSinceEpoch}_${movies.length}',
            'name': currentName,
            'group': group,
            'url': url,
            'logo': currentLogo ?? '',
          }));
        } else {
          channels.add(Channel.fromM3u({
            'id': currentId ?? '${DateTime.now().millisecondsSinceEpoch}_${channels.length}',
            'name': currentName,
            'group': group,
            'url': url,
            'logo': currentLogo ?? '',
          }));
        }

        currentName = null;
        currentLogo = null;
        currentGroup = null;
        currentId = null;
      }
    }

    return {
      'channels': channels,
      'movies': movies,
      'categories': categories,
    };
  }

  static String? _extractAttribute(String line, String pattern) {
    if (pattern == ',') {
      final idx = line.indexOf(',');
      if (idx != -1) {
        return line.substring(idx + 1).trim();
      }
      return null;
    }

    final startIdx = line.indexOf(pattern);
    if (startIdx == -1) return null;
    final valueStart = startIdx + pattern.length;
    final endIdx = line.indexOf('"', valueStart);
    if (endIdx == -1) return null;
    return line.substring(valueStart, endIdx);
  }

  static bool _isVodUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/movie/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.mov') ||
        (lower.endsWith('.ts') && lower.contains('/movie/'));
  }

  static bool _isVodGroup(String group) {
    final lower = group.toLowerCase();
    return lower.contains('vod') ||
        lower.contains('pelicula') ||
        lower.contains('peli') ||
        lower.contains('movie') ||
        lower.contains('film') ||
        lower.contains('cinema') ||
        lower.contains('serie') ||
        lower.contains('series') ||
        lower.contains('episode');
  }
}
