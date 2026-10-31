// File: lib/features/referrals/presentation/screen/referrals_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';

import 'new_referral_screen.dart';
import 'referral_detail_screen.dart';

class ReferralsListScreen extends StatefulWidget {
  final String? volunteerId;

  const ReferralsListScreen({super.key, this.volunteerId});

  @override
  State<ReferralsListScreen> createState() => _ReferralsListScreenState();
}

class _ReferralsListScreenState extends State<ReferralsListScreen> {
  final ReferralsApiService _apiService = ReferralsApiService();

  List<ReferralItem> _referrals = [];
  bool _isLoading = true;

  final List<String> _months = const [
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
    _fetchReferrals();
  }

  Future<void> _fetchReferrals() async {
    // Purge any phantom REF-26-0001 from disk cache immediately
    await SessionManager.removeSubmittedReferral('REF-26-0001');

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

      final items = await _apiService.getReferrals(
        effectiveVolunteerId,
        effectiveNumericId,
      );
      final filtered = items
          .where(
            (ref) => VolunteerOwnershipFilter.isOwnedByVolunteer(
              itemOwnerId: ref.volunteerId,
              itemNumericId: ref.numericVolunteerId,
              activeVolunteerId: effectiveVolunteerId,
              activeNumericId: effectiveNumericId,
            ),
          )
          .toList();

      if (mounted) setState(() => _referrals = filtered);
    } catch (e) {
      debugPrint('[REFERRALS_LIST] Error fetching referrals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatStream(String stream) {
    final s = stream.toLowerCase();
    if (s.contains('animal') || s.contains('vet')) return 'Animal';
    if (s.contains('env')) return 'Environmental';
    return 'Human';
  }

  Future<void> _openNewReferral() async {
    final session = await SessionManager.getUserSession();
    final effectiveVolunteerId =
        (widget.volunteerId != null && widget.volunteerId!.trim().isNotEmpty)
            ? widget.volunteerId!.trim()
            : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');
    if (!mounted) return;
    final created = await Navigator.push<ReferralItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewReferralScreen(volunteerId: effectiveVolunteerId),
      ),
    );
    if (created != null && mounted) {
      setState(() => _referrals.insert(0, created));
      await _fetchReferrals();
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
          title: 'Referrals',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () => Navigator.pop(context),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF136B4F)),
              )
            : RefreshIndicator(
                onRefresh: _fetchReferrals,
                color: const Color(0xFF136B4F),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  children: [
                    if (_referrals.isEmpty)
                      _buildEmptyState()
                    else
                      ..._referrals.map((item) => _buildReferralCard(item)),
                  ],
                ),
              ),

        // "+ New Referral" Floating Action Button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: ElevatedButton.icon(
            onPressed: _openNewReferral,
            icon: const Icon(Icons.add, color: Colors.white, size: 19),
            label: const Text(
              'New Referral',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF136B4F),
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
            'No referrals recorded yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use New Referral to create one.',
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

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    final isPending = lower.contains('pending') || lower.contains('offline');
    final bg = isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);
    final text = isPending ? const Color(0xFFD97706) : const Color(0xFF15803D);
    final label = isPending
        ? 'pending'
        : (lower == 'submitted' ? 'synced' : lower);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReferralCard(ReferralItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // Navigate to full referral detail screen on card tap (replaces bottom sheet)
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReferralDetailScreen(
                  referral: item,
                  referralId: item.referralId,
                ),
              ),
            );
            _fetchReferrals();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical Blue Accent Bar
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.facilityName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(item.status),
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
                                color: Color(0xFF136B4F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' · ${_formatDate(item.referralDate)} · ${item.village}',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatStream(item.stream)} · ${item.isFollowedUp ? "followed up" : "pending follow-up"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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
        selectedItemColor: const Color(0xFF136B4F),
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
