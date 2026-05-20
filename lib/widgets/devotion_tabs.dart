import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DevotionTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const DevotionTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Daily Devotion',
            isActive: activeTab == 'daily',
            onTap: () => onTabChanged('daily'),
          ),
          _TabButton(
            label: 'Articles',
            isActive: activeTab == 'articles',
            onTap: () => onTabChanged('articles'),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              color: isActive ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
