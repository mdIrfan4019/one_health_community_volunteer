import 'package:flutter/material.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/features/notifications/presentation/screen/notifications_screen.dart';
import 'package:cohv/features/sync/presentation/screen/sync_screen.dart';

/// Centralized navigation service for global Notification and Synchronisation screens.
/// Guarantees that duplicate screen instances are not pushed on rapid double taps.
class AuthenticatedNavigation {
  static bool _isNavigating = false;

  /// Resets the navigation debounce lock (used by tests and teardowns).
  static void resetLock() {
    _isNavigating = false;
  }

  /// Navigates to the Notifications screen.
  static Future<void> openNotifications(
    BuildContext context, {
    String volunteerId = '',
    ValueChanged<int>? onTabReturned,
  }) async {
    if (_isNavigating) return;

    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.settings.name == '/notifications') return;
    if (context.widget is NotificationsScreen) return;

    _isNavigating = true;
    try {
      final effectiveVolunteerId = volunteerId.trim().isNotEmpty
          ? volunteerId.trim()
          : (await SessionManager.getVolunteerId() ?? '');

      if (!context.mounted) return;

      final pushFuture = Navigator.push<int>(
        context,
        MaterialPageRoute<int>(
          settings: const RouteSettings(name: '/notifications'),
          builder: (_) => NotificationsScreen(volunteerId: effectiveVolunteerId),
        ),
      );

      Future.microtask(() => _isNavigating = false);

      final result = await pushFuture;
      if (result != null && onTabReturned != null) {
        onTabReturned(result);
      }
    } finally {
      _isNavigating = false;
    }
  }

  /// Navigates to the Synchronisation screen.
  static Future<void> openSync(
    BuildContext context, {
    String volunteerId = '',
    ValueChanged<int>? onTabReturned,
  }) async {
    if (_isNavigating) return;

    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.settings.name == '/sync') return;
    if (context.widget is SyncScreen) return;

    _isNavigating = true;
    try {
      final effectiveVolunteerId = volunteerId.trim().isNotEmpty
          ? volunteerId.trim()
          : (await SessionManager.getVolunteerId() ?? '');

      if (!context.mounted) return;

      final pushFuture = Navigator.push<int>(
        context,
        MaterialPageRoute<int>(
          settings: const RouteSettings(name: '/sync'),
          builder: (_) => SyncScreen(volunteerId: effectiveVolunteerId),
        ),
      );

      Future.microtask(() => _isNavigating = false);

      final result = await pushFuture;
      if (result != null && onTabReturned != null) {
        onTabReturned(result);
      }
    } finally {
      _isNavigating = false;
    }
  }
}

/// Reusable action buttons (Notification & Synchronisation) for authenticated screen headers.
class AuthenticatedHeaderActions extends StatelessWidget {
  final String volunteerId;
  final ValueChanged<int>? onTabReturned;
  final bool isNotificationsActive;
  final bool isSyncActive;
  final VoidCallback? onSyncTap;

  const AuthenticatedHeaderActions({
    super.key,
    this.volunteerId = '',
    this.onTabReturned,
    this.isNotificationsActive = false,
    this.isSyncActive = false,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Notification Icon Button
        _buildHeaderButton(
          key: const ValueKey('global_notification_button'),
          context: context,
          icon: isNotificationsActive
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: () {
            if (!isNotificationsActive) {
              AuthenticatedNavigation.openNotifications(
                context,
                volunteerId: volunteerId,
                onTabReturned: onTabReturned,
              );
            }
          },
        ),

        const SizedBox(width: 8),

        // 2. Synchronisation Icon Button
        _buildHeaderButton(
          key: const ValueKey('global_sync_button'),
          context: context,
          icon: Icons.sync_rounded,
          tooltip: 'Synchronisation',
          onTap: () {
            if (onSyncTap != null) {
              onSyncTap!();
            } else if (!isSyncActive) {
              AuthenticatedNavigation.openSync(
                context,
                volunteerId: volunteerId,
                onTabReturned: onTabReturned,
              );
            }
          },
        ),

        const SizedBox(width: 14),
      ],
    );
  }

  Widget _buildHeaderButton({
    required BuildContext context,
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Shared fixed header AppBar for all authenticated screens across the application.
class AuthenticatedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final VoidCallback? onBackPressed;
  final String volunteerId;
  final ValueChanged<int>? onTabReturned;
  final Color? backgroundColor;
  final List<Widget>? extraActions;
  final bool isNotificationsActive;
  final bool isSyncActive;
  final VoidCallback? onSyncTap;

  const AuthenticatedAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.onBackPressed,
    this.volunteerId = '',
    this.onTabReturned,
    this.backgroundColor,
    this.extraActions,
    this.isNotificationsActive = false,
    this.isSyncActive = false,
    this.onSyncTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (automaticallyImplyLeading) {
      final canPop = Navigator.canPop(context);
      if (canPop) {
        leadingWidget = IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 19,
          ),
          onPressed: onBackPressed ?? () => Navigator.pop(context),
        );
      }
    }

    final titleContent = titleWidget ??
        (title != null
            ? Text(
                title!,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              )
            : null);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leadingWidget,
      automaticallyImplyLeading: leadingWidget != null,
      title: titleContent,
      actions: [
        ...?extraActions,
        AuthenticatedHeaderActions(
          volunteerId: volunteerId,
          onTabReturned: onTabReturned,
          isNotificationsActive: isNotificationsActive,
          isSyncActive: isSyncActive,
          onSyncTap: onSyncTap,
        ),
      ],
    );
  }
}
