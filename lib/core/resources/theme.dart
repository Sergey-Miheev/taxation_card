import 'package:flutter/material.dart';
import 'package:taxation_card/core/resources/colors.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppColors.text,
  ),
  scaffoldBackgroundColor: AppColors.surface,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 0,
    margin: EdgeInsets.zero,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.text,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
  ),
);
