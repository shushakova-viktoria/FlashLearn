import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/card_provider.dart';
import '../models/card_model.dart';
import '../widgets/glass_card.dart';

class DeckEditScreen extends StatefulWidget {
  final String? deckId;

  const DeckEditScreen({super.key, this.deckId});

  @override
  State<DeckEditScreen> createState() => _DeckEditScreenState();
}

class _DeckEditScreenState extends State<DeckEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isEditing = false;
  Deck? _editingDeck;

  @override
  void initState() {
    super.initState();
    _initializeDeck();
  }

  void _initializeDeck() {
    if (widget.deckId != null) {
      _isEditing = true;
      final cardProvider = Provider.of<CardProvider>(context, listen: false);
      _editingDeck = cardProvider.decks.firstWhere(
        (deck) => deck.id == widget.deckId,
      );
      _nameController.text = _editingDeck!.name;
      _descriptionController.text = _editingDeck!.description;
    }
  }

  void _saveDeck() {
    if (_formKey.currentState!.validate()) {
      final cardProvider = Provider.of<CardProvider>(context, listen: false);

      if (_isEditing && _editingDeck != null) {
        final updatedDeck = Deck(
          id: _editingDeck!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          createdAt: _editingDeck!.createdAt,
          updatedAt: DateTime.now(),
        );
        cardProvider.updateDeck(updatedDeck);
      } else {
        final newDeck = Deck(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          description: _descriptionController.text,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        cardProvider.addDeck(newDeck);
      }

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать колоду' : 'Новая колода',
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
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
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
            onPressed: _saveDeck,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
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
                        _isEditing ? Icons.edit_rounded : Icons.create_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isEditing ? 'Редактирование колоды' : 'Создание новой колоды',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing 
                          ? 'Внесите изменения в вашу колоду'
                          : 'Создайте новую колоду для карточек',
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
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Название колоды',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.title_rounded, color: Colors.grey[500]),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Описание (необязательно)',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(Icons.description_rounded, color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        text: _isEditing ? 'Сохранить изменения' : 'Создать колоду',
                        onPressed: _saveDeck,
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}