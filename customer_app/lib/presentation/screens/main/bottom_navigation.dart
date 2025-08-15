// screens/main/bottom_navigation.dart
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    List<BottomNavigationBarItem> items = [
      _buildItem(
        context,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        isDark: isDark,
        primary: primary,
      ),
      _buildItem(
        context,
        icon: Icons.list_alt_outlined,
        activeIcon: Icons.list_alt,
        label: 'Orders',
        isDark: isDark,
        primary: primary,
      ),
      _buildItem(
        context,
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on,
        label: 'Track',
        isDark: isDark,
        primary: primary,
      ),
      _buildItem(
        context,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        isDark: isDark,
        primary: primary,
      ),
    ];

    return BottomNavigationBar(
      items: items,
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      // Colors, typography and elevation come from BottomNavigationBarTheme
    );
  }

  BottomNavigationBarItem _buildItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
    required Color primary,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: isDark ? _glowIcon(primary, activeIcon) : Icon(activeIcon),
      label: label,
    );
  }

  Widget _glowIcon(Color primary, IconData iconData) {
    // Light (bright) glow effect for selected item in dark mode
    final Color glow = Colors.white.withOpacity(0.55);
    final Color glowBg = Colors.white.withOpacity(0.0);
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowBg, // subtle light background
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: primary, // keep brand color for the glyph
      ),
    );
  }
}
