import 'package:logging/logging.dart';
import 'package:picquery_app/src/engine/api.dart';
import 'package:picquery_app/src/search/category_query.dart';

final _log = Logger('run_text_search');

class TextSearchOutcome {
  final List<SearchResult> results;
  final String engineQuery;
  final CategoryQuery? category;
  final int limitUsed;

  const TextSearchOutcome({
    required this.results,
    required this.engineQuery,
    required this.category,
    required this.limitUsed,
  });
}

bool containsChinese(String text) => RegExp(r'[一-鿿]').hasMatch(text);

/// Category phrases such as 「表情包」 are expanded locally. Everything else
/// still goes through the on-device Chinese-to-English translator.
Future<TextSearchOutcome> runTextSearch({
  required String query,
  required int limit,
  required List<int> albumIds,
  int? modifiedAfter,
}) async {
  final category = matchCategory(query);
  if (category != null) {
    final limitUsed = limit < categoryMinimumLimit
        ? categoryMinimumLimit
        : limit;
    _log.info(
      'Category search: id=${category.id}, prompts=${category.positivePrompts.length}, '
      'limit=$limitUsed.',
    );
    final results = await searchByCategory(
      category: category,
      limit: limitUsed,
      albumIds: albumIds,
      modifiedAfter: modifiedAfter,
    );
    return TextSearchOutcome(
      results: results,
      engineQuery: category.positivePrompts.join(' | '),
      category: category,
      limitUsed: limitUsed,
    );
  }

  var searchQuery = query;
  if (containsChinese(query)) {
    try {
      searchQuery = await translateZhToEn(sentence: query);
    } catch (error, stackTrace) {
      _log.severe(
        'Translation failed; using the original query.',
        error,
        stackTrace,
      );
    }
  }
  final results = await searchByTextWithFilters(
    query: searchQuery,
    limit: limit,
    albumIds: albumIds,
    modifiedAfter: modifiedAfter,
  );
  return TextSearchOutcome(
    results: results,
    engineQuery: searchQuery,
    category: null,
    limitUsed: limit,
  );
}
