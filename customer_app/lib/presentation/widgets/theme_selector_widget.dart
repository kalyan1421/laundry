// lib/presentation/widgets/theme_selector_widget.dart
import 'package:customer_app/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Widget for selecting app theme mode
/// Provides options for Light, Dark, and System themes
class ThemeSelectorWidget extends StatelessWidget {
  const ThemeSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          color: context.backgroundColor,
          margin: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 16.0, bottom: 8.0, right: 16.0),
                child: Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              // Theme Options
              _buildThemeOption(
                context,
                themeProvider,
                'Light',
                'Always use light theme',
                Icons.light_mode,
                ThemeMode.light,
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),

              _buildThemeOption(
                context,
                themeProvider,
                'Dark',
                'Always use dark theme',
                Icons.dark_mode,
                ThemeMode.dark,
              ),
              const Divider(height: 1, indent: 56, endIndent: 16),

              _buildThemeOption(
                context,
                themeProvider,
                'System',
                'Follow system settings',
                Icons.settings_brightness,
                ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return Material(
      color: context.backgroundColor,
      child: InkWell(
        onTap: () async {
          await themeProvider.setThemeMode(mode);

          // Show feedback with proper context check
          if (context.mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Theme changed to $title'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              // Silently handle if context is not available
              print('Theme changed to $title');
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.onBackgroundColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple theme toggle switch widget for quick access
class ThemeToggleWidget extends StatelessWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Material(
          color: Colors.white,
          child: InkWell(
            onTap: () async {
              await themeProvider.toggleTheme();
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                children: [
                  Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dark Mode',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          themeProvider.getThemeModeDescription(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.toggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bottom sheet for theme selection
class ThemeSelectionBottomSheet extends StatelessWidget {
  const ThemeSelectionBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const ThemeSelectionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Choose Theme',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Theme options
              _buildBottomSheetOption(
                context,
                themeProvider,
                'Light',
                'Always use light theme',
                Icons.light_mode,
                ThemeMode.light,
              ),
              _buildBottomSheetOption(
                context,
                themeProvider,
                'Dark',
                'Always use dark theme',
                Icons.dark_mode,
                ThemeMode.dark,
              ),
              _buildBottomSheetOption(
                context,
                themeProvider,
                'System',
                'Follow system settings',
                Icons.settings_brightness,
                ThemeMode.system,
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    IconData icon,
    ThemeMode mode,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return InkWell(
      onTap: () async {
        await themeProvider.setThemeMode(mode);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
