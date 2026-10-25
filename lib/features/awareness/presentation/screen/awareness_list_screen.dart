// Create file: lib/features/awareness/presentation/screen/awareness_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../../../../core/storage/session_manager.dart';
import '../../../../core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';

import 'new_awareness_screen.dart';
import 'awareness_detail_screen.dart';

class AwarenessListScreen extends StatefulWidget {
  final String? volunteerId;

  const AwarenessListScreen({super.key, this.volunteerId});

  @override
  State<AwarenessListScreen> createState() => _AwarenessListScreenState();
}

class _AwarenessListScreenState extends State<AwarenessListScreen> {
  final AwarenessApiService _apiService = AwarenessApiService();

  List<AwarenessItem> _activities = [];
  bool _isLoading = true;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId =
          (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
              ? widget.volunteerId!.trim()
              : (session?.volunteerId ??
                  await SessionManager.getVolunteerId() ??
                  '');
      final effectiveNumericId =
          session?.numericVolunteerId ??
          await SessionManager.getNumericVolunteerId() ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

      final items = await _apiService.getAwarenessList(
        effectiveVolunteerId,
        effectiveNumericId,
      );
      final filtered = items
          .where(
            (act) => VolunteerOwnershipFilter.isOwnedByVolunteer(
              itemOwnerId: act.volunteerId.isNotEmpty ? act.volunteerId : act.volunteerCode,
              itemNumericId: act.numericVolunteerId,
              activeVolunteerId: effectiveVolunteerId,
              activeNumericId: effectiveNumericId,
            ),
          )
          .toList();

      if (mounted) setState(() => _activities = filtered);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openNewActivity() async {
    final session = await SessionManager.getUserSession();
    final effectiveVolunteerId =
        (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
            ? widget.volunteerId!.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');
    if (!mounted) return;
    final created = await Navigator.push<AwarenessItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewAwarenessScreen(volunteerId: effectiveVolunteerId),
      ),
    );
    if (created != null && mounted) {
      setState(() => _activities.insert(0, created));
      await _fetchActivities();
    } else if (mounted) {
      await _fetchActivities();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
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
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'Awareness',
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                onRefresh: _fetchActivities,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    if (_activities.isEmpty)
                      _buildEmptyState()
                    else
                      ..._activities.map((item) => _buildActivityCard(item)),
                  ],
                ),
              ),

        // "+ New Activity" Pill Button at bottom right
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: ElevatedButton.icon(
            onPressed: _openNewActivity,
            icon: const Icon(Icons.add, color: Colors.white, size: 19),
            label: const Text(
              'New Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.25),
            ),
          ),
        ),

        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No awareness activities recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use New Activity to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(AwarenessItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AwarenessDetailScreen(
              activity: item,
              awarenessId: item.awarenessId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical Orange Accent Bar
            Container(
              width: 3.5,
              height: 48,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.activityType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: item.id,
                          style: const TextStyle(
                            color: Color(0xFF9D174D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${_formatDate(item.date)} · ${item.village}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.peopleReached} reached · ${item.topicCovered}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
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
        currentIndex: 1, // Highlight 'Actions'
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
