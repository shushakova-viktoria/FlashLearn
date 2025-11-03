class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
  
  static const String decks = '/decks';
  static const String cards = '/cards';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
}