import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    scaffoldBackgroundColor: AppColors.background,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),

    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),

    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
    }),

    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
      ),
    ),
  );
}