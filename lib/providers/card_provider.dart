import 'package:flutter/foundation.dart';
import '../models/card_model.dart';

class CardProvider with ChangeNotifier {
  List<Deck> decks = [];
  List<FlashCard> cards = [];

  CardProvider() {
    // Временные данные для тестирования
    _initializeSampleData();
  }

  void _initializeSampleData() {
  final sampleDeck = Deck(
    id: '1',
    name: 'Программирование',
    description: 'Основные понятия программирования',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    
  );
  decks.add(sampleDeck);

    cards.addAll([
      FlashCard(
        id: '1',
        question: 'Что такое Flutter?',
        answer: 'Flutter - это фреймворк для создания кроссплатформенных приложений',
        deckId: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextReviewDate: DateTime.now(),
      ),
      FlashCard(
        id: '2',
        question: 'Что такое Widget?',
        answer: 'Widget - это базовый строительный блок Flutter приложения',
        deckId: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextReviewDate: DateTime.now(),
      ),
      FlashCard(
        id: '3',
        question: 'Что такое State?',
        answer: 'State - это данные, которые могут изменяться в течение жизненного цикла виджета',
        deckId: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nextReviewDate: DateTime.now(),
      ),
    ]);
  }

  // Временные методы - потом заменим на API calls
  void addDeck(Deck deck) {
    decks.add(deck);
    notifyListeners();
  }

  void updateDeck(Deck deck) {
    final index = decks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      decks[index] = deck;
      notifyListeners();
    }
  }

  void deleteDeck(String deckId) {
    decks.removeWhere((deck) => deck.id == deckId);
    cards.removeWhere((card) => card.deckId == deckId);
    notifyListeners();
  }

  void addCard(FlashCard card) {
    cards.add(card);
    notifyListeners();
  }

  void updateCard(FlashCard card) {
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      notifyListeners();
    }
  }

  void deleteCard(String cardId) {
    cards.removeWhere((card) => card.id == cardId);
    notifyListeners();
  }

  List<FlashCard> getCardsByDeck(String deckId) {
    return cards.where((card) => card.deckId == deckId).toList();
  }
}