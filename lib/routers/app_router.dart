import 'package:go_router/go_router.dart';
import '../screens/deck_list_screen.dart';
import '../screens/card_list_screen.dart';
import '../screens/card_edit_screen.dart';
import '../screens/deck_edit_screen.dart';
import '../screens/review_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'decks',
        builder: (context, state) => const DeckListScreen(),
      ),
      GoRoute(
        path: '/decks/:deckId/cards',
        name: 'cards',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return CardListScreen(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/decks/:deckId/cards/new',
        name: 'newCard',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return CardEditScreen(deckId: deckId);
        },
      ),
      GoRoute(
        path: '/decks/:deckId/cards/:cardId/edit',
        name: 'editCard',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          final cardId = state.pathParameters['cardId']!;
          return CardEditScreen(deckId: deckId, cardId: cardId);
        },
      ),
      GoRoute(
        path: '/decks/new',
        name: 'newDeck',
        builder: (context, state) => const DeckEditScreen(),
      ),
      GoRoute(
        path: '/decks/:deckId/edit',
        name: 'editDeck',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return DeckEditScreen(deckId: deckId);
        },
      ),
      GoRoute(
      path: '/decks/:deckId/review',
      name: 'review',
      builder: (context, state) {
      final deckId = state.pathParameters['deckId']!;
      return ReviewScreen(deckId: deckId);
        },
      ),
    ],
  );
}