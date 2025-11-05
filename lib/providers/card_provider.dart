import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';

class CardProvider with ChangeNotifier {
  List<Deck> decks = [];
  List<FlashCard> cards = [];
  final ApiService _apiService = ApiService();

  CardProvider() {
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      decks = await _apiService.getDecks();
      notifyListeners();
    } catch (e) {
      print('Error loading decks from API: $e');
      _initializeSampleData();
    }
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
    ]);
  }

  Future<void> addDeck(Deck deck) async {
    try {
      final newDeck = await _apiService.createDeck(deck);
      decks.add(newDeck);
      notifyListeners();
    } catch (e) {
      print('Error creating deck: $e');
      decks.add(deck);
      notifyListeners();
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      final updatedDeck = await _apiService.updateDeck(deck);
      final index = decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        decks[index] = updatedDeck;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating deck: $e');
      final index = decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        decks[index] = deck;
        notifyListeners();
      }
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      await _apiService.deleteDeck(deckId);
      decks.removeWhere((deck) => deck.id == deckId);
      cards.removeWhere((card) => card.deckId == deckId);
      notifyListeners();
    } catch (e) {
      print('Error deleting deck: $e');
      decks.removeWhere((deck) => deck.id == deckId);
      cards.removeWhere((card) => card.deckId == deckId);
      notifyListeners();
    }
  }


  Future<void> addCard(FlashCard card) async {
    try {
      final newCard = await _apiService.createCard(card);
      cards.add(newCard);
      notifyListeners();
    } catch (e) {
      print('Error creating card: $e');
      cards.add(card);
      notifyListeners();
    }
  }

  Future<void> updateCard(FlashCard card) async {
    try {
      final updatedCard = await _apiService.updateCard(card);
      final index = cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        cards[index] = updatedCard;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating card: $e');
      final index = cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        cards[index] = card;
        notifyListeners();
      }
    }
  }

  Future<void> deleteCard(String cardId) async {
    try {
      await _apiService.deleteCard(cardId);
      cards.removeWhere((card) => card.id == cardId);
      notifyListeners();
    } catch (e) {
      print('Error deleting card: $e');
      cards.removeWhere((card) => card.id == cardId);
      notifyListeners();
    }
  }

  Future<void> reviewCard(String cardId, int quality) async {
    try {
      await _apiService.reviewCard(cardId, quality);
      final index = cards.indexWhere((c) => c.id == cardId);
      if (index != -1) {
        cards[index].updateAfterReview(quality);
        notifyListeners();
      }
    } catch (e) {
      print('Error reviewing card: $e');
      final index = cards.indexWhere((c) => c.id == cardId);
      if (index != -1) {
        cards[index].updateAfterReview(quality);
        notifyListeners();
      }
    }
  }

  List<FlashCard> getCardsByDeck(String deckId) {
    return cards.where((card) => card.deckId == deckId).toList();
  }
}