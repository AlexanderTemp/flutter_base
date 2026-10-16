class NotificationOptions {
  const NotificationOptions({
    this.sections = const {'prices', 'change', 'bob', 'events'},
    this.featuredCoin = '',
    this.alerts = false,
    this.leadMinutes = 5,
  });

  final Set<String> sections;
  final String featuredCoin;
  final bool alerts;
  final int leadMinutes;

  bool get hasContent =>
      sections.any(const {'prices', 'bob', 'events'}.contains);

  NotificationOptions copyWith({
    Set<String>? sections,
    String? featuredCoin,
    bool? alerts,
    int? leadMinutes,
  }) => NotificationOptions(
    sections: sections ?? this.sections,
    featuredCoin: featuredCoin ?? this.featuredCoin,
    alerts: alerts ?? this.alerts,
    leadMinutes: leadMinutes ?? this.leadMinutes,
  );
}
