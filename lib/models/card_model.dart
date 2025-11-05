class FlashCard {
  final String id;
  String question;
  String answer;
  String deckId;
  DateTime createdAt;
  DateTime updatedAt;

  int repetitionCount;
  double easeFactor;
  int interval;
  DateTime nextReviewDate;

  FlashCard({
    required this.id,
    required this.question,
    required this.answer,
    required this.deckId,
    required this.createdAt,
    required this.updatedAt,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.interval = 0,
    required this.nextReviewDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'deck_id': deckId,
    };
  }

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id']?.toString() ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      deckId: json['deck_id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      repetitionCount: json['repetitions'] ?? 0,
      easeFactor: (json['ease_factor'] ?? 2.5).toDouble(),
      interval: json['interval'] ?? 0,
      nextReviewDate: DateTime.parse(json['next_review'] ?? json['created_at']),
    );
  }

  void updateAfterReview(int quality) {
    if (quality >= 3) {
      if (repetitionCount == 0) {
        interval = 1;
      } else if (repetitionCount == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitionCount++;
    } else {
      repetitionCount = 0;
      interval = 1;
    }

    easeFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (easeFactor < 1.3) {
      easeFactor = 1.3;
    }

    nextReviewDate = DateTime.now().add(Duration(days: interval));
    updatedAt = DateTime.now();
  }
}

class Deck {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  DateTime updatedAt;

  Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': name,
      'description': description,
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id']?.toString() ?? '',
      name: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}