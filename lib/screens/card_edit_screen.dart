import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../models/card_model.dart';
import '../widgets/glass_card.dart';

class CardEditScreen extends StatefulWidget {
  final String deckId;
  final String? cardId;

  const CardEditScreen({
    super.key,
    required this.deckId,
    this.cardId,
  });

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();

  bool _isEditing = false;
  FlashCard? _editingCard;

  @override
  void initState() {
    super.initState();
    _initializeCard();
  }

  void _initializeCard() {
    if (widget.cardId != null) {
      _isEditing = true;
      final cardProvider = Provider.of<CardProvider>(context, listen: false);
      _editingCard = cardProvider.cards.firstWhere(
        (card) => card.id == widget.cardId,
      );
      _questionController.text = _editingCard!.question;
      _answerController.text = _editingCard!.answer;
    }
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final cardProvider = Provider.of<CardProvider>(context, listen: false);

      if (_isEditing && _editingCard != null) {
        // Редактирование существующей карточки
        final updatedCard = FlashCard(
          id: _editingCard!.id,
          question: _questionController.text,
          answer: _answerController.text,
          deckId: widget.deckId,
          createdAt: _editingCard!.createdAt,
          updatedAt: DateTime.now(),
          nextReviewDate: DateTime.now(),
        );
        cardProvider.updateCard(updatedCard);
      } else {
        // Создание новой карточки
        final newCard = FlashCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: _questionController.text,
          answer: _answerController.text,
          deckId: widget.deckId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          nextReviewDate: DateTime.now(),
        );
        cardProvider.addCard(newCard);
      }

      // Возвращаемся к списку карточек колоды
      context.go('/decks/${widget.deckId}/cards');
    }
  }

  void _goBack() {
    // Безопасная навигация назад к списку карточек
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/decks/${widget.deckId}/cards');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать карточку' : 'Новая карточка',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          ),
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.save_rounded, color: Colors.white),
            ),
            onPressed: _saveCard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Заголовок с иконкой
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: _isEditing 
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.note_add_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isEditing ? 'Редактирование карточки' : 'Создание новой карточки',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing 
                          ? 'Внесите изменения в вашу карточку'
                          : 'Создайте новую карточку для обучения',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Форма редактирования
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Содержание карточки',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Поле вопроса
                      TextFormField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: 'Вопрос',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.question_mark_rounded, color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите вопрос';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Поле ответа
                      TextFormField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          labelText: 'Ответ',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.lightbulb_rounded, color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите ответ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Панель форматирования
                      Text(
                        'Форматирование текста:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFormattingToolbar(),
                      const SizedBox(height: 24),

                      // Кнопка сохранения
                      GradientButton(
                        text: _isEditing ? 'Сохранить изменения' : 'Создать карточку',
                        onPressed: _saveCard,
                        fullWidth: true,
                        gradient: _isEditing
                            ? const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFormatButton(
            icon: Icons.format_bold_rounded,
            tooltip: 'Жирный текст',
            onPressed: () => _insertText('**', '**'),
          ),
          _buildFormatButton(
            icon: Icons.format_italic_rounded,
            tooltip: 'Курсив',
            onPressed: () => _insertText('*', '*'),
          ),
          _buildFormatButton(
            icon: Icons.code_rounded,
            tooltip: 'Моноширинный текст',
            onPressed: () => _insertText('`', '`'),
          ),
          _buildFormatButton(
            icon: Icons.format_quote_rounded,
            tooltip: 'Цитата',
            onPressed: () => _insertText('> ', ''),
          ),
          _buildFormatButton(
            icon: Icons.format_list_bulleted_rounded,
            tooltip: 'Список',
            onPressed: () => _insertText('- ', ''),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _insertText(String prefix, String suffix) {
    final controller = _answerController;
    final text = controller.text;
    final selection = controller.selection;
    
    if (selection.isValid) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix${selection.textInside(text)}$suffix',
      );
      controller.text = newText;
      controller.selection = selection.copyWith(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    } else {
      // Если нет выделения, вставляем в конец
      final newText = '$text$prefix$suffix';
      controller.text = newText;
      controller.selection = TextSelection.collapsed(
        offset: newText.length - suffix.length,
      );
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}