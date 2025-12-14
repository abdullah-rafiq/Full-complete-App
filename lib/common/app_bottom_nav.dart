import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final Color selectedColor =
        isDark ? Colors.white : colorScheme.primary;
    // ignore: deprecated_member_use
    final Color unselectedColor = isDark
        ? Colors.white70
        : colorScheme.onSurface.withOpacity(0.6);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: selectedColor,
      // ignore: deprecated_member_use
      unselectedItemColor: unselectedColor,
      onTap: onTap,
      items: items,
    );
  }
}
