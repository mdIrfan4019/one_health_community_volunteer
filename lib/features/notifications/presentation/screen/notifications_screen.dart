// Create file: lib/features/notifications/presentation/screen/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/notifications_api_service.dart';
import '../../domain/notification_models.dart';

class NotificationsScreen extends StatefulWidget {
  final String volunteerId;

  const NotificationsScreen({
    super.key,
    this.volunteerId = '',
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsApiService _apiService = NotificationsApiService();
  final ScrollController _scrollController = ScrollController();

  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId = widget.volunteerId.trim().isNotEmpty
          ? widget.volunteerId.trim()
          : (session?.volunteerId ?? await SessionManager.getVolunteerId() ?? '');
      final items = await _apiService.getNotifications(effectiveVolunteerId);
      if (mounted) {
        setState(() {
          _notifications = items;
        });
      }
    } catch (_) {
      // Keep existing cache on network error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.setuBackground,
        appBar: AuthenticatedAppBar(
          title: 'Notifications',
          volunteerId: widget.volunteerId,
          isNotificationsActive: true,
          backgroundColor: const Color(0xFF136B4F),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF136B4F)),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _notifications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'No notifications available.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _notifications.length,
                              separatorBuilder: (context, index) => const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.divider,
                              ),
                              itemBuilder: (context, index) {
                                final item = _notifications[index];
                                return _buildNotificationTile(item);
                              },
                            ),
                          ),
                  ),
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }


  Widget _buildNotificationTile(AppNotification item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${item.timestamp} — ${item.message}',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Returning index allows DashboardScreen to immediately switch to that tab
          Navigator.pop(context, index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.textLight,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
