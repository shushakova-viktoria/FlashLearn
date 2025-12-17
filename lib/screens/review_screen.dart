import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../models/card_model.dart';
import '../widgets/glass_card.dart';

class ReviewScreen extends StatefulWidget {
  final String deckId;

  const ReviewScreen({super.key, required this.deckId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingAnswer = false;
  int _currentCardIndex = 0;
  List<FlashCard> _reviewCards = [];
  int _sessionCount = 0;
  Map<int, int> _ratingsCount = {0: 0, 2: 0, 3: 0, 4: 0};
  bool _isProcessingRating = false;
  bool _allCardsReviewed = false;
  List<int> _processedCardIndices = [];
  List<int> _difficultCards = [];
  bool _isInDifficultReview = false;
  int _difficultReviewIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutBack),
    );

    _loadReviewCards();
  }

  void _loadReviewCards() {
    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final allCards = cardProvider.getCardsByDeck(widget.deckId);
    
    _reviewCards = List.from(allCards);
    _reviewCards.shuffle();
    _processedCardIndices = List.generate(_reviewCards.length, (index) => index);
  }

  void _flipCard() {
    if (_isProcessingRating) return;
    
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    
    setState(() {
      _isShowingAnswer = !_isShowingAnswer;
    });
  }

  void _rateCard(int quality) async {
    if (_reviewCards.isEmpty || _isProcessingRating) return;

    setState(() {
      _isProcessingRating = true;
    });

    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final currentCard = _reviewCards[_currentCardIndex];
    
    // Увеличиваем счетчик для статистики
    _ratingsCount[quality] = (_ratingsCount[quality] ?? 0) + 1;
    _sessionCount++;

    // Применяем алгоритм интервального повторения
    _applySpacedRepetition(currentCard, quality);
    
    // Сохраняем изменения
    cardProvider.reviewCard(currentCard.id, quality);

    // Если карточка оценена как "Снова" (0) - добавляем ее для повторения
    if (quality == 0) {
      // Карточка останется на текущей позиции
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isProcessingRating = false;
          _isShowingAnswer = false;
          _animationController.reset();
        });
      }
      return;
    }
    
    // Если карточка оценена как "Трудно" (2) - добавляем в список трудных
    if (quality == 2 && !_isInDifficultReview) {
      _difficultCards.add(_currentCardIndex);
    }

    // Помечаем карточку как обработанную
    if (!_isInDifficultReview) {
      _processedCardIndices.remove(_currentCardIndex);
    }

    // Ждем анимацию
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _processNextCard();
    }
  }

  void _processNextCard() {
    if (_isInDifficultReview) {
      // Обработка трудных карточек
      _difficultReviewIndex++;
      
      if (_difficultReviewIndex >= _difficultCards.length) {
        // Все трудные карточки оценены
        _finishSession();
      } else {
        // Переход к следующей трудной карточке
        setState(() {
          _currentCardIndex = _difficultCards[_difficultReviewIndex];
          _isShowingAnswer = false;
          _isProcessingRating = false;
          _animationController.reset();
        });
      }
    } else {
      // Обработка обычных карточек
      if (_processedCardIndices.isNotEmpty) {
        // Получаем индекс следующей необработанной карточки
        int nextIndex = _processedCardIndices[0];
        
        // Если следующая карточка есть после текущей, берем ее
        bool found = false;
        for (int idx in _processedCardIndices) {
          if (idx > _currentCardIndex) {
            nextIndex = idx;
            found = true;
            break;
          }
        }
        
        if (!found) {
          // Если не нашли карточку после текущей, берем первую необработанную
          nextIndex = _processedCardIndices[0];
        }
        
        setState(() {
          _currentCardIndex = nextIndex;
          _isShowingAnswer = false;
          _isProcessingRating = false;
          _animationController.reset();
        });
      } else {
        // Все обычные карточки оценены
        if (_difficultCards.isNotEmpty) {
          // Запускаем повторение трудных карточек
          _startDifficultReview();
        } else {
          // Нет трудных карточек - завершаем сессию
          _finishSession();
        }
      }
    }
  }

  void _startDifficultReview() {
    if (_difficultCards.isEmpty) {
      _finishSession();
      return;
    }

    // Начинаем повторение трудных карточек
    setState(() {
      _isInDifficultReview = true;
      _difficultReviewIndex = 0;
      _currentCardIndex = _difficultCards[_difficultReviewIndex];
      _isShowingAnswer = false;
      _isProcessingRating = false;
      _animationController.reset();
    });
  }

  void _finishSession() {
    setState(() {
      _allCardsReviewed = true;
      _isProcessingRating = false;
    });
    _showCompletionDialog();
  }

  void _applySpacedRepetition(FlashCard card, int quality) {
    // SM-2 алгоритм (упрощенная версия)
    switch (quality) {
      case 0: // Снова (не помню)
        card.repetitionCount = 0;
        card.interval = 1;
        card.easeFactor = card.easeFactor > 1.3 ? card.easeFactor - 0.2 : 1.3;
        break;
        
      case 2: // Трудно (вспомнил с трудом)
        if (card.repetitionCount == 0) {
          card.interval = 1;
        } else if (card.repetitionCount == 1) {
          card.interval = 6;
        } else {
          card.interval = (card.interval * card.easeFactor * 0.8).round();
        }
        card.easeFactor = card.easeFactor > 1.3 ? card.easeFactor - 0.15 : 1.3;
        card.repetitionCount++;
        break;
        
      case 3: // Хорошо (вспомнил нормально)
        if (card.repetitionCount == 0) {
          card.interval = 1;
        } else if (card.repetitionCount == 1) {
          card.interval = 6;
        } else {
          card.interval = (card.interval * card.easeFactor).round();
        }
        card.repetitionCount++;
        break;
        
      case 4: // Легко (вспомнил мгновенно)
        if (card.repetitionCount == 0) {
          card.interval = 4;
        } else if (card.repetitionCount == 1) {
          card.interval = 10;
        } else {
          card.interval = (card.interval * card.easeFactor * 1.3).round();
        }
        card.easeFactor = card.easeFactor + 0.1;
        card.repetitionCount++;
        break;
    }
    
    // Устанавливаем дату следующего повторения
    card.nextReviewDate = DateTime.now().add(Duration(days: card.interval));
  }

  void _showCompletionDialog() {
    // Рассчитываем процент успешных ответов
    final totalRatings = _ratingsCount.values.fold(0, (sum, count) => sum + count);
    final successfulRatings = (_ratingsCount[3] ?? 0) + (_ratingsCount[4] ?? 0);
    final successPercentage = totalRatings > 0 
        ? ((successfulRatings / totalRatings) * 100).round() 
        : 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: successPercentage >= 70
                        ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                        : successPercentage >= 50
                            ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                            : [const Color(0xFFEF4444), const Color(0xFFFCA5A5)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  successPercentage >= 70
                      ? Icons.celebration
                      : successPercentage >= 50
                          ? Icons.thumb_up
                          : Icons.refresh,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                successPercentage >= 70
                    ? 'Отличная работа!'
                    : successPercentage >= 50
                        ? 'Хорошо поработали!'
                        : 'Продолжаем учиться!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              
              // Статистика
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Повторено карточек:',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        Text(
                          '$_sessionCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Успешных ответов:',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                        Text(
                          '$successPercentage%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: successPercentage >= 70
                                ? const Color(0xFF10B981)
                                : successPercentage >= 50
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    if (_difficultCards.isNotEmpty)
                      const SizedBox(height: 12),
                    if (_difficultCards.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Повторено трудных:',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          Text(
                            '${_difficultCards.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRatingStat(0, 'Снова', const Color(0xFFEF4444)),
                        _buildRatingStat(2, 'Трудно', const Color(0xFFF59E0B)),
                        _buildRatingStat(3, 'Хорошо', const Color(0xFF3B82F6)),
                        _buildRatingStat(4, 'Легко', const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/decks/${widget.deckId}/cards');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'К карточкам',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'На главную',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStat(int quality, String label, Color color) {
    final count = _ratingsCount[quality] ?? 0;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(FlashCard card) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.14159;
        
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);
        
        if (angle > 1.57) {
          return Transform(
            transform: transform..rotateY(3.14159),
            alignment: Alignment.center,
            child: _buildAnswerSide(card),
          );
        } else {
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _buildQuestionSide(card),
          );
        }
      },
    );
  }

  Widget _buildQuestionSide(FlashCard card) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isInDifficultReview
              ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isInDifficultReview ? const Color(0xFFF59E0B) : const Color(0xFF6366F1)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _isInDifficultReview ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 24),
            Text(
              _isInDifficultReview ? 'ТРУДНАЯ КАРТОЧКА' : 'ВОПРОС',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    card.question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нажмите для показа ответа',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSide(FlashCard card) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isInDifficultReview
              ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
              : [const Color(0xFF10B981), const Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isInDifficultReview ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _isInDifficultReview ? Icons.lightbulb_outline_rounded : Icons.lightbulb_rounded,
              size: 48,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 24),
            Text(
              _isInDifficultReview ? 'ТРУДНЫЙ ОТВЕТ' : 'ОТВЕТ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    card.answer,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Оцените, насколько хорошо вспомнили',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    if (!_isShowingAnswer || _reviewCards.isEmpty || _isProcessingRating || _allCardsReviewed) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Text(
            _isInDifficultReview 
                ? 'Повторение трудных карточек' 
                : 'Насколько хорошо вы запомнили?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSquareRatingButton(
                text: 'Снова',
                subtitle: 'Не помню совсем',
                color: const Color(0xFFEF4444),
                icon: Icons.replay_rounded,
                quality: 0,
              ),
              _buildSquareRatingButton(
                text: 'Трудно',
                subtitle: _isInDifficultReview ? 'Еще раз повторить' : 'Вспомнил с трудом',
                color: const Color(0xFFF59E0B),
                icon: Icons.warning_amber_rounded,
                quality: 2,
              ),
              _buildSquareRatingButton(
                text: 'Хорошо',
                subtitle: 'Вспомнил нормально',
                color: const Color(0xFF3B82F6),
                icon: Icons.thumb_up_rounded,
                quality: 3,
              ),
              _buildSquareRatingButton(
                text: 'Легко',
                subtitle: 'Вспомнил мгновенно',
                color: const Color(0xFF10B981),
                icon: Icons.star_rounded,
                quality: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareRatingButton({
    required String text,
    required String subtitle,
    required Color color,
    required IconData icon,
    required int quality,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Квадратная кнопка
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _rateCard(quality),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Подпись под кнопкой
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewCards.isEmpty || _allCardsReviewed) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Повторение завершено!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _difficultCards.isEmpty
                          ? 'Вы успешно повторили все карточки в колоде'
                          : 'Вы повторили все карточки, включая трудные',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          // Сбрасываем состояние и начинаем заново
                          setState(() {
                            _allCardsReviewed = false;
                            _isInDifficultReview = false;
                            _currentCardIndex = 0;
                            _sessionCount = 0;
                            _ratingsCount = {0: 0, 2: 0, 3: 0, 4: 0};
                            _difficultCards = [];
                            _difficultReviewIndex = 0;
                            _processedCardIndices = List.generate(_reviewCards.length, (index) => index);
                            _isShowingAnswer = false;
                            _animationController.reset();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Повторить еще раз',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/decks/${widget.deckId}/cards'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Вернуться к колоде',
                        style: TextStyle(
                          color: Color(0xFF374151),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final currentCard = _reviewCards[_currentCardIndex];
    final totalCards = _reviewCards.length;
    final reviewedCards = totalCards - _processedCardIndices.length;
    final progress = reviewedCards / totalCards;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isInDifficultReview ? 'Повторение трудных' : 'Повторение',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF374151),
            ),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/decks/${widget.deckId}/cards');
            }
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isInDifficultReview 
                      ? '${_difficultReviewIndex + 1}/${_difficultCards.length}'
                      : '${reviewedCards + 1}/$totalCards',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isInDifficultReview ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _isInDifficultReview ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_sessionCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Прогресс-бар
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _isInDifficultReview 
                    ? (_difficultReviewIndex + 1) / _difficultCards.length
                    : progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isInDifficultReview
                          ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Карточка
            Expanded(
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isProcessingRating
                      ? Container(
                          key: const ValueKey('loading'),
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('card'),
                          child: _buildCardContent(currentCard),
                        ),
                ),
              ),
            ),
            
            // Кнопки оценки
            _buildRatingButtons(),
            const SizedBox(height: 8),
            
            // Подсказка
            if (_isShowingAnswer && !_allCardsReviewed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _isInDifficultReview
                      ? 'Повторение трудных карточек - оцените еще раз'
                      : 'Выберите оценку для продолжения',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}