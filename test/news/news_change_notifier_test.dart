import 'package:bluetooth_test/news_service.dart';
import 'package:bluetooth_test/providers/news_change_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// One Method to get mock data. Long and convoluted
class CustomMockNewsService implements NewsService {
  bool getArticlesCalled = false;
  @override
  Future<List<Article>> getArticles() async {
    getArticlesCalled = true;

    return [
      Article(title: "Test 1", content: 'Test 1 content'),
      Article(title: "Test 2", content: 'Test 1 content'),
      Article(title: "Test 3", content: 'Test 1 content'),
    ];
  }
}

// Using mocktail classes

class MockNewsService extends Mock implements NewsService {}

void main() {
  late NewsChangeNotifier sut;
  late MockNewsService mockNewsService;

  setUp(() {
    mockNewsService = MockNewsService();
    sut = NewsChangeNotifier(mockNewsService);
  });

  // Before writing test for the service check the initial values of the variables if they are correct or not.

  test("Initial values are correct", () {
    expect(sut.articles, []);
    expect(sut.isLoading, false);
  });

  group('getArticles', () {
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

    test('gets getArticles using the NewsService', () async {
      // Arrange
      arangeNewsServiceReturns3Articles();
      await sut.getArticles();
      verify(() => mockNewsService.getArticles()).called(1);
    });

    test("""indicates loading of data, 
    sets articles to the ones from the service,
    indicates that data is not being loaded anymore""", () async {
      // Arrange
      arangeNewsServiceReturns3Articles();
      // Act
      final future = sut.getArticles();

      //Assert
      expect(sut.isLoading, true);
      await future;

      expect(sut.articles, articlesFromService);
      expect(sut.isLoading, false);
    });
  });
}
