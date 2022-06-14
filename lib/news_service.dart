import 'package:flutter_lorem/flutter_lorem.dart';

class Article {
  final String title;
  final String content;

  Article({required this.title, required this.content});

  Article copyWith({String? title, String? content}) {
    return Article(title: title ?? this.title, content: content ?? this.content);
  }

  @override
  String toString() => 'Article(title: $title, content: $content)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Article && title == other.title && content == other.content;
  }

  @override
  int get hashCode => hashCode ^ content.hashCode;
}

class NewsService {
  final _articles = List.generate(
      20,
      (index) => Article(
            title: "Article $index",
            content: lorem(paragraphs: 5, words: 200),
          ));

  Future<List<Article>> getArticles() async {
    await Future.delayed(const Duration(seconds: 1));

    return _articles;
  }
}
