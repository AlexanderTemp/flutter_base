// Modelo de una noticia (titular de RSS).
class NewsItem {
  NewsItem({
    required this.title,
    required this.link,
    required this.source,
    this.description = '',
    this.published,
  });

  final String title;
  final String link;
  final String source;
  final String description;
  final DateTime? published;
}
