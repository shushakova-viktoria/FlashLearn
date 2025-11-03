import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routers/app_router.dart';
import 'providers/card_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CardProvider(),
      child: MaterialApp.router(
        title: 'FlashLearn',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.all(16),
          ),
          // Добавляем индикатор загрузки
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF6366F1),
          ),
        ),
        routerConfig: AppRouter.router,
        // Обработка ошибок навигации
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              // Скрываем клавиатуру при тапе вне поля ввода
              FocusScope.of(context).unfocus();
            },
            child: child,
          );
        },
      ),
    );
  }
}