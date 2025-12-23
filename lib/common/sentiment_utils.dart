import 'package:assist/models/review.dart';
import 'package:assist/services/ai_backend_service.dart';

class SentimentStats {
  final double avgScore; // -1.0 (very negative) .. +1.0 (very positive)
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;

  const SentimentStats({
    required this.avgScore,
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
  });
}

// English + Roman Urdu lexicon tuned for typical service reviews.
// These are intentionally simple substring matches.
const List<String> sentimentPositiveWords = <String>[
  'good',
  'great',
  'excellent',
  'amazing',
  'perfect',
  'nice',
  'fast',
  'quick',
  'friendly',
  'polite',
  'professional',
  'clean',
  'neat',
  'tidy',
  'satisfied',
  'recommend',
  'helpful',
  'on time',
  'ontime',
  'punctual',
  // Roman Urdu / Urdu transliteration
  'acha',
  'achha',
  'bohot acha',
  'bohat acha',
  'bohot achha',
  'bohat achha',
  'bahot acha',
  'best',
  'zabardast',
  'mast',
  'sahi',
  'shukriya',
];

const List<String> sentimentNegativeWords = <String>[
  'bad',
  'poor',
  'terrible',
  'awful',
  'late',
  'delay',
  'rude',
  'dirty',
  'mess',
  'slow',
  'unprofessional',
  'disappointed',
  'refund',
  'complaint',
  'cancel',
  'no show',
  'no-show',
  'expensive',
  'overcharge',
  'scam',
  'fraud',
  // Roman Urdu / Urdu transliteration
  'bura',
  'bohot bura',
  'bohat bura',
  'ganda',
  'mahenga',
  'mehnga',
  'mehenga',
  'bahut bura',
];

class SentimentUtils {
  const SentimentUtils._();

  static SentimentStats compute(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const SentimentStats(
        avgScore: 0.0,
        positiveCount: 0,
        neutralCount: 0,
        negativeCount: 0,
      );
    }

    double total = 0.0;
    int pos = 0;
    int neu = 0;
    int neg = 0;

    for (final ReviewModel r in reviews) {
      final int rating = r.rating.clamp(1, 5);
      double score = ((rating - 3) / 2).clamp(-1.0, 1.0).toDouble();

      final List<int> qVals = <int?>[
        r.qPunctuality,
        r.qQuality,
        r.qCommunication,
        r.qProfessionalism,
      ].where((int? v) => v != null).cast<int>().toList();

      if (qVals.isNotEmpty) {
        final double avgQ =
            qVals.reduce((int a, int b) => a + b) / qVals.length.toDouble();
        final double qScore = ((avgQ - 3.0) / 2.0).clamp(-1.0, 1.0);
        score = (score * 0.7) + (qScore * 0.3);
      }

      final String comment = r.comment?.toLowerCase() ?? '';
      if (comment.isNotEmpty) {
        int posHits = 0;
        int negHits = 0;

        for (final String w in sentimentPositiveWords) {
          if (comment.contains(w)) posHits++;
        }
        for (final String w in sentimentNegativeWords) {
          if (comment.contains(w)) negHits++;
        }

        if (posHits > 0 || negHits > 0) {
          final double textScore = ((posHits - negHits) / (posHits + negHits))
              .clamp(-1.0, 1.0);
          score = (score * 0.6) + (textScore * 0.4);
        }
      }

      if (r.wouldRecommend == true) {
        score += 0.1;
      } else if (r.wouldRecommend == false) {
        score -= 0.1;
      }

      if (r.hadDispute == true) {
        score -= 0.2;
      }

      score = score.clamp(-1.0, 1.0);
      total += score;

      if (score > 0.2) {
        pos++;
      } else if (score < -0.2) {
        neg++;
      } else {
        neu++;
      }
    }

    final double avg = (total / reviews.length).clamp(-1.0, 1.0);
    return SentimentStats(
      avgScore: avg,
      positiveCount: pos,
      neutralCount: neu,
      negativeCount: neg,
    );
  }

  /// Compute sentiment statistics, enhanced with the backend Sentiment AI
  /// when possible. Falls back to the local rule-based logic if the AI
  /// call fails or if there is no usable text.
  static Future<SentimentStats> computeWithAi(List<ReviewModel> reviews) async {
    final SentimentStats baseline = compute(reviews);
    if (reviews.isEmpty) {
      return baseline;
    }

    // Concatenate all non-empty comments into a single text blob for
    // overall sentiment. This keeps the number of backend calls small
    // while still capturing the general tone.
    final List<String> comments = reviews
        .map((ReviewModel r) => r.comment?.trim())
        .where((String? c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toList();

    if (comments.isEmpty) {
      return baseline;
    }

    const int maxChars = 8000;
    final buffer = StringBuffer();
    for (final c in comments) {
      if (buffer.length >= maxChars) break;
      final remaining = maxChars - buffer.length;
      if (remaining <= 0) break;
      if (c.length <= remaining) {
        buffer.write(c);
      } else {
        buffer.write(c.substring(0, remaining));
      }
      buffer.write('\n');
    }

    final String text = buffer.toString().trim();
    if (text.isEmpty) {
      return baseline;
    }

    try {
      final Map<String, dynamic> resp = await AiBackendService.instance
          .analyzeSentiment(text);

      final dynamic labelRaw = resp['sentiment'];
      final dynamic confRaw = resp['confidence'];

      if (labelRaw is! String) {
        return baseline;
      }

      final String label = labelRaw.toLowerCase().trim();
      double confidence = 1.0;
      if (confRaw is num) {
        confidence = confRaw.toDouble().clamp(0.0, 1.0);
      }

      double aiScore;
      if (label == 'positive') {
        aiScore = confidence;
      } else if (label == 'negative') {
        aiScore = -confidence;
      } else if (label == 'neutral') {
        aiScore = 0.0;
      } else {
        return baseline;
      }

      // Blend AI score with baseline average to keep behavior stable while
      // still benefitting from the dedicated model.
      final double blended = (baseline.avgScore * 0.6) + (aiScore * 0.4);

      return SentimentStats(
        avgScore: blended.clamp(-1.0, 1.0),
        positiveCount: baseline.positiveCount,
        neutralCount: baseline.neutralCount,
        negativeCount: baseline.negativeCount,
      );
    } catch (_) {
      // On any network or parsing error, fall back to the local model.
      return baseline;
    }
  }
}
