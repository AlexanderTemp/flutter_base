// Cliente de noticias forex por RSS. Fuentes verificadas que responden desde
// Dart (no están tras Cloudflare): FXStreet e Investing.com.
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'news_models.dart';

class NewsSource {
  const NewsSource(this.name, this.url);
  final String name;
  final String url;
}

class NewsClient {
  NewsClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const sources = [
    NewsSource('FXStreet', 'https://www.fxstreet.com/rss/news'),
    NewsSource('Investing', 'https://www.investing.com/rss/news.rss'),
  ];

  static const _ua =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0 Safari/537.36';

  /// Descarga todas las fuentes, mezcla y ordena por fecha (lo más nuevo arriba).
  Future<List<NewsItem>> fetchAll() async {
    final results = await Future.wait(
      sources.map(_fetchOne),
      eagerError: false,
    );
    final all = results.expand((e) => e).toList();
    all.sort((a, b) {
      final da = a.published, db = b.published;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return all;
  }

  Future<List<NewsItem>> _fetchOne(NewsSource src) async {
    try {
      final r = await _http
          .get(Uri.parse(src.url), headers: {'User-Agent': _ua})
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return [];
      return _parseRss(r.body, src.name);
    } catch (_) {
      return []; // una fuente caída no tumba las demás
    }
  }

  List<NewsItem> _parseRss(String body, String source) {
    final out = <NewsItem>[];
    try {
      final doc = XmlDocument.parse(body);
      for (final item in doc.findAllElements('item')) {
        final title = _text(item, 'title');
        if (title.isEmpty) continue;
        out.add(
          NewsItem(
            title: title,
            link: _text(item, 'link'),
            source: source,
            description: _strip(_text(item, 'description')),
            published: _parseDate(_text(item, 'pubDate')),
          ),
        );
      }
    } catch (_) {
      // XML malformado: devolvemos lo que haya.
    }
    return out;
  }

  static String _text(XmlElement parent, String tag) {
    final el = parent.findElements(tag);
    if (el.isEmpty) return '';
    return el.first.innerText.trim();
  }

  static String _strip(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    // RFC 822 típico de RSS: "Thu, 15 Oct 2026 14:30:00 GMT"
    try {
      return _rfc822(s);
    } catch (_) {
      return DateTime.tryParse(s);
    }
  }

  static DateTime _rfc822(String s) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final m = RegExp(
      r'(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?',
    ).firstMatch(s);
    if (m == null) throw const FormatException('fecha RSS no reconocida');
    final zone = s.substring(m.end).trim().toUpperCase();
    final offset = RegExp(r'^([+-])(\d{2})(\d{2})$').firstMatch(zone);
    var minutes = 0;
    if (offset != null) {
      final hours = int.parse(offset.group(2)!);
      final remainder = int.parse(offset.group(3)!);
      if (hours > 23 || remainder > 59)
        throw const FormatException('Zona horaria no válida');
      minutes = (hours * 60 + remainder) * (offset.group(1) == '-' ? -1 : 1);
    } else if (!const {'GMT', 'UTC', 'UT', 'Z'}.contains(zone)) {
      throw const FormatException('Zona horaria RSS no reconocida');
    }
    return DateTime.utc(
      int.parse(m.group(3)!),
      months[m.group(2)] ??
          (throw const FormatException('Mes RSS no reconocido')),
      int.parse(m.group(1)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6) ?? '0'),
    ).subtract(Duration(minutes: minutes)).toLocal();
  }

  void close() => _http.close();
}
