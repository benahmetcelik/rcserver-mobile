class DbBookmark {
  DbBookmark({required this.id, required this.title, required this.url});

  final String id;
  final String title;
  final String url;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'url': url};

  factory DbBookmark.fromJson(Map<String, dynamic> j) => DbBookmark(
        id: j['id'] as String,
        title: j['title'] as String,
        url: j['url'] as String,
      );
}
