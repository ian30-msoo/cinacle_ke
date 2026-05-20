import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state.dart';

class CenacleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData titleIcon;
  final bool showMenu;
  final VoidCallback? onProfileTap;
  final Widget? action;

  const CenacleAppBar({
    super.key,
    required this.title,
    required this.titleIcon,
    this.showMenu = false,
    this.onProfileTap,
    this.action,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: showMenu
              ? Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.white, size: 22),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    splashRadius: 20,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
          title: Row(
            children: [
              Icon(titleIcon, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            if (action != null) action!,
            if (onProfileTap != null)
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: state.isLoggedIn ? AppColors.gold : Colors.white38,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: state.isLoggedIn && state.currentUser != null
                        ? Text(
                            state.currentUser!.initials,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          )
                        : const Icon(Icons.person_outline, color: AppColors.white, size: 20),
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }
}
