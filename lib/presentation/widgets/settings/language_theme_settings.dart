import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../theme/colors.dart';

class LanguageThemeSettings extends StatelessWidget {
  const LanguageThemeSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language Selection
          Text(
            AppLocalizations.of(context)?.language ?? 'Language',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _LanguageSelector(),
          const SizedBox(height: 24),
          
          // Theme Selection
          Text(
            AppLocalizations.of(context)?.theme ?? 'Theme',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _ThemeSelector(),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode;

    return Column(
      children: [
        _LanguageTile(
          title: 'English',
          subtitle: 'English',
          isSelected: currentLanguage == 'en',
          onTap: () {
            localeProvider.setLocale(const Locale('en'));
          },
        ),
        const SizedBox(height: 8),
        _LanguageTile(
          title: 'বাংলা',
          subtitle: 'Bangla',
          isSelected: currentLanguage == 'bn',
          onTap: () {
            localeProvider.setLocale(const Locale('bn'));
          },
        ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? AppColors.primaryBlue.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: title == 'বাংলা' ? 'NotoSansBengali' : 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        _ThemeTile(
          title: localizations?.translate('light_mode') ?? 'Light Mode',
          icon: Icons.light_mode,
          isSelected: !isDark,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.light);
          },
        ),
        const SizedBox(height: 8),
        _ThemeTile(
          title: localizations?.translate('dark_mode') ?? 'Dark Mode',
          icon: Icons.dark_mode,
          isSelected: isDark,
          onTap: () {
            themeProvider.setThemeMode(ThemeMode.dark);
          },
        ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? AppColors.primaryBlue.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryBlue,
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show language/theme settings dialog
void showLanguageThemeDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const LanguageThemeSettings(),
  );
}
