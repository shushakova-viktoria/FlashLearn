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
      'id': id,
      'question': question,
      'answer': answer,
      'deckId': deckId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'repetitionCount': repetitionCount,
      'easeFactor': easeFactor,
      'interval': interval,
      'nextReviewDate': nextReviewDate.toIso8601String(),
    };
  }

  // Создание объекта из JSON с бекенда
  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      deckId: json['deckId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      repetitionCount: json['repetitionCount'] ?? 0,
      easeFactor: (json['easeFactor'] ?? 2.5).toDouble(),
      interval: json['interval'] ?? 0,
      nextReviewDate: DateTime.parse(json['nextReviewDate'] ?? json['createdAt']),
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
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}