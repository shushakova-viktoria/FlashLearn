class ApiConfig {
  // Пробуем все возможные варианты
  static const List<String> possibleUrls = [
    'https://limnologically-guardable-dawson.ngrok-free.dev/api/v1',  
    'http://10.246.239.36:8000/api/v1', 
    'http://10.246.239.36:8080/api/v1',  
    'https://d39be018cab12207d61b5f80c8558065.serveo.net/api/v1', 
    'http://localhost:8000/api/v1', 
  ];
  
  static String get baseUrl => possibleUrls[0]; 
  
  static const String decks = '/decks';
  static const String cards = '/cards';
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
}