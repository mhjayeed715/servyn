import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Headings
  static const h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.neutralDark,
    height: 1.2857,
  );
  
  static const h2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.neutralDark,
    height: 1.3333,
  );
  
  static const h3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralDark,
    height: 1.4,
  );
  
  static const h4 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralDark,
    height: 1.4444,
  );
  
  static const h5 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralDark,
    height: 1.5,
  );
  
  // Body Text
  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.neutralDark,
    height: 1.5,
  );
  
  static const bodyRegular = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.neutralGray,
    height: 1.5714,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.neutralGray,
    height: 1.6667,
  );
  
  // Button Text
  static const buttonLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static const buttonMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5714,
  );
  
  static const buttonSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.6667,
  );
  
  // Caption
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.neutralGray,
    height: 1.6667,
  );
  
  static const captionBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralGray,
    height: 1.6667,
  );
  
  // Bangla Text Styles
  static const banglah1 = TextStyle(
    fontFamily: 'NotoSansBengali',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.neutralDark,
    height: 1.4,
  );
  
  static const banglaBodyRegular = TextStyle(
    fontFamily: 'NotoSansBengali',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.neutralGray,
    height: 1.6,
  );
  
  static const banglaButtonMedium = TextStyle(
    fontFamily: 'NotoSansBengali',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );
}