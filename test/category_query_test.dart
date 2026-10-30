import 'package:flutter_test/flutter_test.dart';
import 'package:picquery_app/src/engine/models.dart';
import 'package:picquery_app/src/search/category_query.dart';

void main() {
  test('known phrases map to categories and ignore filler words', () {
    expect(matchCategory('表情包')?.id, 'sticker');
    expect(matchCategory('所有表情包')?.id, 'sticker');
    expect(matchCategory('找一下表情包图片')?.id, 'sticker');
    expect(matchCategory('meme')?.id, 'sticker');
    expect(matchCategory('美女图片')?.id, 'portrait');
    expect(matchCategory('三次元美女')?.id, 'portrait');
    expect(matchCategory('动漫')?.id, 'anime');
    expect(matchCategory('游戏截图')?.id, 'game');
    expect(matchCategory('海边日落'), isNull);
    expect(matchCategory('a cat on the sofa'), isNull);
  });

  test('merge keeps the stronger positive score and drops negative lookalikes', () {
    const category = CategoryQuery(
      id: 'sticker',
      labelZh: '表情包',
      labelEn: 'stickers',
      triggers: ['表情包'],
      positivePrompts: ['meme'],
      negativePrompts: ['screenshot'],
      bonusExtensions: {'.gif'},
    );
    final merged = mergeCategoryResults(
      category: category,
      positiveGroups: [
        [
          const SearchResult(
            filePath: '/a/meme.jpg',
            fileName: 'meme.jpg',
            similarity: 0.40,
          ),
          const SearchResult(
            filePath: '/a/scene.jpg',
            fileName: 'scene.jpg',
            similarity: 0.22,
          ),
        ],
        [
          const SearchResult(
            filePath: '/a/meme.jpg',
            fileName: 'meme.jpg',
            similarity: 0.30,
          ),
          const SearchResult(
            filePath: '/a/pack.gif',
            fileName: 'pack.gif',
            similarity: 0.20,
          ),
        ],
      ],
      negativeGroups: [
        [
          const SearchResult(
            filePath: '/a/scene.jpg',
            fileName: 'scene.jpg',
            similarity: 0.36,
          ),
        ],
      ],
      limit: 10,
    );

    expect(merged.map((item) => item.fileName).toList(), ['meme.jpg', 'pack.gif']);
    expect(merged.first.similarity, 0.40);
    expect(merged.last.similarity, closeTo(0.25, 0.0001));
  });
}
