import 'package:picquery_app/src/engine/models.dart';

/// Category searches skip the Chinese-to-English translator. A tiny Marian
/// model turns 「表情包」 into something like "expression pack", which MobileCLIP
/// cannot match. These queries go straight to several English picture prompts.
const int categoryMinimumLimit = 300;

const double _defaultNegativeWeight = 0.55;
const double _defaultMinScore = 0.12;
const double _extensionBonus = 0.05;

class CategoryQuery {
  final String id;
  final String labelZh;
  final String labelEn;
  final List<String> triggers;
  final List<String> positivePrompts;
  final List<String> negativePrompts;
  final double negativeWeight;
  final double minScore;
  final Set<String> bonusExtensions;

  const CategoryQuery({
    required this.id,
    required this.labelZh,
    required this.labelEn,
    required this.triggers,
    required this.positivePrompts,
    required this.negativePrompts,
    this.negativeWeight = _defaultNegativeWeight,
    this.minScore = _defaultMinScore,
    this.bonusExtensions = const {},
  });
}

const List<CategoryQuery> kCategories = [
  CategoryQuery(
    id: 'sticker',
    labelZh: '表情包',
    labelEn: 'stickers and memes',
    triggers: ['表情包', '梗图', '斗图', 'meme', 'sticker', 'reactionimage'],
    positivePrompts: [
      'an internet meme',
      'a reaction image meme',
      'a cartoon sticker with text',
      'an emoji sticker',
      'a funny image macro',
      'a chat sticker',
    ],
    negativePrompts: [
      'a landscape photograph',
      'a video game screenshot',
      'a photo of scenery',
    ],
    bonusExtensions: {'.gif', '.webp'},
    minScore: 0.10,
  ),
  CategoryQuery(
    id: 'portrait',
    labelZh: '三次元人物',
    labelEn: 'photographs of women',
    triggers: ['三次元美女', '三次元', '美女', '女生'],
    positivePrompts: [
      'a photograph of a woman',
      'a portrait photo of a woman',
      'a selfie of a woman',
    ],
    negativePrompts: [
      'an anime girl',
      'a cartoon character',
      'an internet meme',
      'a video game character',
    ],
  ),
  CategoryQuery(
    id: 'anime',
    labelZh: '动漫',
    labelEn: 'anime',
    triggers: ['动漫', '二次元', 'anime'],
    positivePrompts: [
      'an anime illustration',
      'a manga drawing',
      'an anime screenshot',
    ],
    negativePrompts: [
      'a photograph of a real person',
      'a video game screenshot',
    ],
  ),
  CategoryQuery(
    id: 'game',
    labelZh: '游戏截图',
    labelEn: 'game screenshots',
    triggers: ['游戏截图', '游戏画面', 'gamescreenshot'],
    positivePrompts: [
      'a video game screenshot',
      'a gameplay screenshot',
      'a video game user interface',
    ],
    negativePrompts: [
      'an internet meme',
      'a photograph of a person',
      'a cartoon sticker',
    ],
  ),
];

/// Returns a category when the query is that category, allowing filler words
/// such as 「所有」「图片」. A longer trigger wins, so 「三次元美女」 stays a
/// portrait search instead of the shorter 「美女」.
CategoryQuery? matchCategory(String raw) {
  final compact = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty) return null;
  final stripped = _stripFillers(compact);
  CategoryQuery? best;
  var bestLength = 0;
  for (final category in kCategories) {
    for (final trigger in category.triggers) {
      final hit = compact == trigger || stripped == trigger;
      if (hit && trigger.length > bestLength) {
        best = category;
        bestLength = trigger.length;
      }
    }
  }
  return best;
}

String _stripFillers(String compact) {
  var text = compact;
  const edges = ['请', '帮我', '把', '所有', '全部', '找', '搜', '一下', '出来', '的', '图片', '照片'];
  var changed = true;
  while (changed) {
    changed = false;
    for (final edge in edges) {
      if (text.startsWith(edge) && text.length > edge.length) {
        text = text.substring(edge.length);
        changed = true;
      }
      if (text.endsWith(edge) && text.length > edge.length) {
        text = text.substring(0, text.length - edge.length);
        changed = true;
      }
    }
  }
  return text;
}

/// Keeps the best positive score per file, subtracts the best negative score,
/// then adds a small bonus for animated sticker extensions.
List<SearchResult> mergeCategoryResults({
  required CategoryQuery category,
  required List<List<SearchResult>> positiveGroups,
  required List<List<SearchResult>> negativeGroups,
  required int limit,
}) {
  final positive = <String, _Score>{};
  for (final group in positiveGroups) {
    for (final hit in group) {
      final current = positive[hit.filePath];
      if (current == null || hit.similarity > current.score) {
        positive[hit.filePath] = _Score(hit.fileName, hit.similarity);
      }
    }
  }
  final negative = <String, double>{};
  for (final group in negativeGroups) {
    for (final hit in group) {
      final current = negative[hit.filePath];
      if (current == null || hit.similarity > current) {
        negative[hit.filePath] = hit.similarity;
      }
    }
  }

  final ranked = <SearchResult>[];
  for (final entry in positive.entries) {
    var score =
        entry.value.score - category.negativeWeight * (negative[entry.key] ?? 0);
    if (category.bonusExtensions.contains(_extension(entry.key))) {
      score += _extensionBonus;
    }
    if (score < category.minScore) continue;
    ranked.add(
      SearchResult(
        filePath: entry.key,
        fileName: entry.value.fileName,
        similarity: score,
      ),
    );
  }
  ranked.sort((a, b) {
    final byScore = b.similarity.compareTo(a.similarity);
    if (byScore != 0) return byScore;
    return a.filePath.compareTo(b.filePath);
  });
  if (ranked.length > limit) return ranked.sublist(0, limit);
  return ranked;
}

String _extension(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot == path.length - 1) return '';
  return path.substring(dot).toLowerCase();
}

class _Score {
  final String fileName;
  final double score;

  const _Score(this.fileName, this.score);
}
