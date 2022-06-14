import 'package:bluetooth_test/home_screen.dart';
import 'package:bluetooth_test/news_service.dart';
import 'package:bluetooth_test/providers/news_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockNewsService extends Mock implements NewsService {}

void main() {
  late MockNewsService mockNewsService;

  setUp(() {
    mockNewsService = MockNewsService();
  });

  final articlesFromService = [
    Article(title: "Test 1", content: 'Test 1 content'),
    Article(title: "Test 2", content: 'Test 2 content'),
    Article(title: "Test 3", content: 'Test 3 content')
  ];

  void arangeNewsServiceReturns3Articles() {
    when(() => mockNewsService.getArticles()).thenAnswer(
      (_) async => articlesFromService,
    );
  }

  void arangeNewsServiceReturns3ArticlesAfter2SecondWait() {
    when(() => mockNewsService.getArticles()).thenAnswer(
      (_) async {
        await Future.delayed(const Duration(seconds: 2));
        return articlesFromService;
      },
    );
  }

  Widget createWidgetUnderTest() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChangeNotifierProvider(
        create: (_) => NewsChangeNotifier(mockNewsService),
        child: const HomeScreen(),
      ),
    );
  }

  testWidgets(
    "title is displayed",
    (WidgetTester tester) async {
      arangeNewsServiceReturns3Articles();
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text("News"), findsOneWidget);
    },
  );

  testWidgets("loading indicator is displayed while waiting for articles", (WidgetTester tester) async {
    arangeNewsServiceReturns3ArticlesAfter2SecondWait();
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key("progress-indicator")), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets("articles are displayed", (WidgetTester tester) async {
    arangeNewsServiceReturns3Articles();
    await tester.pumpWidget(createWidgetUnderTest());

    // if static data is used, add pump without delay to trigger widget rebuild. If API data is tested, use a slight delay
    await tester.pump();

    for (final article in articlesFromService) {
      expect(find.text(article.title), findsOneWidget);
      expect(find.text(article.content), findsOneWidget);
    }
  });
}
