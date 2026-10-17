// Create file: lib/features/sync/presentation/screen/sync_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/sync_api_service.dart';
import '../../data/sync_repository.dart';
import '../../domain/sync_models.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';

class SyncScreen extends StatefulWidget {
  final String volunteerId;

  const SyncScreen({
    super.key,
    this.volunteerId = 'COHV-26-0001',
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final SyncRepository _repository = SyncRepository();
  final SyncApiService _apiService = SyncApiService();
  final AuthApiService _authApiService = AuthApiService();

  late SyncSummary _summary;
  bool _treatAsConnected = true;
  bool _isOverridden = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  void _refreshState() {
    setState(() {
      _summary = _repository.getSummary();
      _treatAsConnected = _summary.isOnline;
      _isOverridden = _summary.isOverridden;
    });
  }

  Future<void> _handleSyncNow() async {
    if (!_summary.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot synchronise: Device is currently offline.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final pending = _repository.getPendingRecords();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All records are already synchronised with server.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      // Use Case 4: Token Validation Guard before sensitive sync batch operation
      final isTokenValid = await _authApiService.validateTokenGuard();
      if (!isTokenValid) {
        if (!mounted) return;
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please sign in again to sync records.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
        return;
      }

      final uploadedIds = await _apiService.uploadBatch(
        volunteerId: widget.volunteerId,
        records: pending,
      );

      _repository.markRecordsAsSynced(uploadedIds);
      _refreshState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${uploadedIds.length} record(s) synchronised successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Synchronisation failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Synchronisation',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            // Notifications Bell
            _buildAppBarButton(
              icon: Icons.notifications_none_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),

            // Active Sync Icon
            _buildAppBarButton(
              icon: Icons.sync_rounded,
              onTap: _refreshState,
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with [R] emblem
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF472B6), width: 0.8),
                      ),
                      child: const Text(
                        'R',
                        style: TextStyle(
                          color: Color(0xFF9D174D),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Offline & synchronisation',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Explanatory paragraph matching prototype
                const Text(
                  'Everything works with no connection: forms open, records save, and reports are produced on the device. Records queue locally and upload themselves when connectivity returns. Each carries a unique ID, so a retry cannot create a duplicate, and the capture timestamp is preserved.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),

                // Metric Rows
                _buildMetricRow('Total records', _summary.totalRecords.toString()),
                const Divider(color: AppColors.divider, height: 1),

                _buildMetricRow(
                  'Pending synchronisation',
                  _summary.pendingSync.toString(),
                  valueColor: _summary.pendingSync > 0 ? AppColors.primary : AppColors.textDark,
                ),
                const Divider(color: AppColors.divider, height: 1),

                _buildMetricRow('Synchronised', _summary.synchronised.toString()),
                const Divider(color: AppColors.divider, height: 1),

                _buildMetricRow(
                  'Device connection',
                  _summary.isOnline ? 'Online' : 'Offline',
                  valueColor: _summary.isOnline ? AppColors.textDark : AppColors.error,
                ),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 18),

                // Checkbox: Treat this device as connected
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _treatAsConnected,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _treatAsConnected = val ?? true;
                            _repository.setConnectionOverride(_treatAsConnected);
                            _refreshState();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Treat this device as connected',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),

                if (_isOverridden) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Overridden by you — the app is ignoring the real connection.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Outlined button: Follow the device connection
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _repository.setConnectionOverride(null);
                        _refreshState();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Follow the device connection',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Primary Action Button: Synchronise now
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSyncing ? null : _handleSyncNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSyncing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Synchronise now',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
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
        onTap: (index) => Navigator.pop(context, index),
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
