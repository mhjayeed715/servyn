import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_styles.dart';

ThemeData appTheme() {
  return ThemeData(
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.neutralLight,
    textTheme: TextTheme(
      displayLarge: AppTextStyles.h1,
      bodyMedium: AppTextStyles.bodyRegular,
      // Map all
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Add elevations, inputs, etc.
    fontFamily: 'Inter',  // Default, override for Bangla
  );
}