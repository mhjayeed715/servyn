import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.neutralDark,
    height: 1.2857,  // 36/28
  );
  // Add H2, Body, etc. from Figma
  static const bodyRegular = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: AppColors.neutralGray,
  );
  // Bangla: Use 'NotoSansBengali' where needed
}