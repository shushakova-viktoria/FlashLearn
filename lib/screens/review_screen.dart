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
  }

  void _flipCard() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    
    setState(() {
      _isShowingAnswer = !_isShowingAnswer;
    });
  }

  void _rateCard(int quality) {
    if (_reviewCards.isEmpty) return;

    final cardProvider = Provider.of<CardProvider>(context, listen: false);
    final currentCard = _reviewCards[_currentCardIndex];
    
    if (quality == 0) {
      currentCard.repetitionCount = 0;
      currentCard.interval = 1;
      currentCard.easeFactor = 2.5;
      currentCard.nextReviewDate = DateTime.now();
    } else {
      currentCard.updateAfterReview(quality);
    }
    
    cardProvider.reviewCard(currentCard.id, quality);
    _sessionCount++;

     setState(() {
    if (quality == 0) {
      _isShowingAnswer = false;
      _animationController.reset();
    } else {
      _currentCardIndex = (_currentCardIndex + 1) % _reviewCards.length;
      _isShowingAnswer = false;
      _animationController.reset();
      
      if (_currentCardIndex == 0) {
        _reviewCards.shuffle();
      }
    }
  });
}

  void _showCompletionDialog() {
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Отлично!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Вы завершили повторение всех карточек',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
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
                      ),
                      child: const Text('К карточкам'),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 56,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 32),
            Text(
              'ВОПРОС',
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
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Нажмите для показа ответа',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 56,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(height: 32),
            Text(
              'ОТВЕТ',
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
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Оцените, насколько хорошо вспомнили',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButtons() {
    if (!_isShowingAnswer || _reviewCards.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Text(
            'Насколько хорошо вы запомнили?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatingButton(
                text: 'Снова',
                color: const Color(0xFFEF4444),
                icon: Icons.replay_rounded,
                quality: 0,
              ),
              _buildRatingButton(
                text: 'Трудно',
                color: const Color(0xFFF59E0B),
                icon: Icons.warning_amber_rounded,
                quality: 1,
              ),
              _buildRatingButton(
                text: 'Хорошо',
                color: const Color(0xFF3B82F6),
                icon: Icons.thumb_up_rounded,
                quality: 3,
              ),
              _buildRatingButton(
                text: 'Легко',
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

  Widget _buildRatingButton({
    required String text,
    required Color color,
    required IconData icon,
    required int quality,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => _rateCard(quality),
            icon: Icon(icon, color: Colors.white),
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewCards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassCard(
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
                      'Нет карточек',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Добавьте карточки в колоду для начала повторения',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Добавить карточки',
                      onPressed: () => context.go('/decks/${widget.deckId}/cards'),
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentCard = _reviewCards[_currentCardIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Повторение'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded),
          ),
          onPressed: () {
            // Безопасная навигация назад
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/decks/${widget.deckId}/cards');
            }
          },
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentCardIndex + 1}/${_reviewCards.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
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
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.done_rounded, color: Colors.white, size: 20),
            ),
            onPressed: _showCompletionDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: (_currentCardIndex + 1) / _reviewCards.length,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          
            Expanded(
              child: GestureDetector(
                onTap: _flipCard,
                child: _buildCardContent(currentCard),
              ),
            ),
            
            // Кнопки оценки
            _buildRatingButtons(),
            const SizedBox(height: 16),
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