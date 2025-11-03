import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/card_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final String baseUrl = ApiConfig.baseUrl;

  // Helper method for GET requests
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for POST requests
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: ApiConfig.headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PUT requests
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: ApiConfig.headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for DELETE requests
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Deck methods
  Future<List<Deck>> getDecks() async {
    final data = await get(ApiConfig.decks);
    return (data as List).map((json) => Deck.fromJson(json)).toList();
  }

  Future<Deck> createDeck(Deck deck) async {
    final data = await post(ApiConfig.decks, deck.toJson());
    return Deck.fromJson(data);
  }

  Future<Deck> updateDeck(Deck deck) async {
    final data = await put('${ApiConfig.decks}/${deck.id}', deck.toJson());
    return Deck.fromJson(data);
  }

  Future<bool> deleteDeck(String deckId) async {
    return await delete('${ApiConfig.decks}/$deckId');
  }

  // Card methods
  Future<List<FlashCard>> getCardsByDeck(String deckId) async {
    final data = await get('${ApiConfig.decks}/$deckId${ApiConfig.cards}');
    return (data as List).map((json) => FlashCard.fromJson(json)).toList();
  }

  Future<FlashCard> createCard(FlashCard card) async {
    final data = await post(ApiConfig.cards, card.toJson());
    return FlashCard.fromJson(data);
  }

  Future<FlashCard> updateCard(FlashCard card) async {
    final data = await put('${ApiConfig.cards}/${card.id}', card.toJson());
    return FlashCard.fromJson(data);
  }

  Future<bool> deleteCard(String cardId) async {
    return await delete('${ApiConfig.cards}/$cardId');
  }
}