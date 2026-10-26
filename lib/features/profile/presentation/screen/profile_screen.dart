import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';
import 'package:cohv/features/auth/data/auth_api_service.dart';
import 'package:cohv/features/auth/domain/auth_models.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';

import '../../data/profile_api_service.dart';
import '../../domain/profile_models.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String volunteerId;

  const ProfileScreen({super.key, this.volunteerId = ''});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final AuthApiService _authApiService = AuthApiService();

  late DetailedVolunteerProfile _profile;
  List<LoginHistoryEntry> _loginHistory = [];
  bool _isLoading = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Default baseline profile
    _profile = DetailedVolunteerProfile(
      fullName: '',
      volunteerId: widget.volunteerId,
      designation: 'Public Health Department',
      gender: '—',
      dob: '—',
      mobileNumber: '—',
      email: '—',
      village: '—',
      panchayat: '—',
      block: '—',
      division: '—',
      district: '—',
      state: '—',
      dateOfJoining: '—',
      qualification: '—',
      profession: '—',
      supervisor: '—',
      healthFacilityLinked: 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: 'English',
      status: 'Active',
      lastLogin: '—',
      registrationGps: '—',
      photoUrl: null,
    );

    // Fast load from cached detailed profile (zero latency offline display)
    SessionManager.getDetailedProfile().then((cached) {
      if (cached != null && mounted) {
        setState(() => _profile = cached);
      }
    });

    // Fallback load from cached user session
    SessionManager.getUserSession().then((session) {
      if (session != null && mounted && _profile.fullName.isEmpty) {
        setState(() {
          _profile = DetailedVolunteerProfile.fromUserSession(session);
        });
      }
    });

    // Fetch fresh profile from GET /api/volunteers/profile
    _loadProfileData();
  }

  /// Fetches latest profile details from GET /api/volunteers/profile and dynamic login history
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final session = await SessionManager.getUserSession();
      final effectiveVolunteerId = widget.volunteerId.trim().isNotEmpty
          ? widget.volunteerId.trim()
          : (session?.volunteerId ??
                await SessionManager.getVolunteerId() ??
                '');
      final profile = await _profileApiService.getDetailedProfile(
        effectiveVolunteerId,
      );
      final history = await _profileApiService.getLoginHistory(
        effectiveVolunteerId,
      );
      if (mounted) {
        setState(() {
          // If lastLogin is not provided from backend, fallback to the latest login history entry
          if (history.isNotEmpty &&
              (_profile.lastLogin.isEmpty ||
                  _profile.lastLogin == '—' ||
                  _profile.lastLogin == 'Active session verified')) {
            _profile = profile.copyWith(lastLogin: history.first.timestamp);
          } else {
            _profile = profile;
          }
          _loginHistory = history;
        });
      }
    } on AuthException catch (e) {
      if (e.isUnauthorized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Session expired. Redirecting to Sign In...'),
          ),
        );
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
        return;
      }
    } catch (e) {
      debugPrint(
        '[PROFILE] Error loading profile from /api/volunteers/profile: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Logout action: POST /api/auth/logout with Bearer token
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: const Color(0xFF136B4F), size: 22),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from this handset? You will need your PIN to sign back in.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF136B4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await _authApiService.logout();
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Logout failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: const Color(0xFF136B4F),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) ...[
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF136B4F),
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 8),
            ],
            // 1. Volunteer Full Profile Card
            _buildProfileDetailsCard(),
            const SizedBox(height: 16),

            // 2. Login History Card (scrollable within its card)
            _buildLoginHistoryCard(),
            const SizedBox(height: 16),

            // 3. Logout Option
            _buildLogoutButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Approach A: Navigate to dedicated EditProfileScreen
  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    );

    if (updated == true && mounted) {
      _loadProfileData();
    }
  }

  // =========================================================================
  // CARD 1: FULL PROFILE DETAILS
  // =========================================================================

  Widget _buildProfileDetailsCard() {
    final initialLetter = _profile.fullName.trim().isNotEmpty
        ? _profile.fullName.trim()[0].toUpperCase()
        : 'V';

    final rawPhoto = _profile.photoUrl;
    final isLocalFile =
        rawPhoto != null &&
        rawPhoto.isNotEmpty &&
        !rawPhoto.startsWith('http') &&
        File(rawPhoto).existsSync();
    final candidateUrls = ApiConstants.resolveImageCandidateUrls(rawPhoto);

    // Linked institution display
    final institutionDisplay = _profile.institutionDisplay;
    final institutionLabel =
        _profile.institutionFieldLabel != null &&
            _profile.institutionFieldLabel!.isNotEmpty
        ? _profile.institutionFieldLabel!
        : 'Institution linked';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Volunteer Profile Photo Avatar + Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showPhotoPreview(
                  candidateUrls,
                  isLocalFile ? rawPhoto : null,
                ),
                child: _buildHeaderAvatar(
                  candidateUrls,
                  isLocalFile ? rawPhoto : null,
                  initialLetter,
                ),
              ),
              const SizedBox(width: 14),
              // Name, ID, Designation & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _profile.fullName.isNotEmpty
                                ? _profile.fullName
                                : 'Volunteer Profile',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        _buildStatusBadge(_profile.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _profile.volunteerId,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF136B4F),
                          ),
                        ),
                        const Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textLight,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _profile.designation,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Activity Summary Metric Cards from GET /api/volunteers/profile
          // _buildActivityMetricsStrip(),
          // const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),

          // Key-Value Pairs
          _buildDetailRow(label: 'Gender', value: _profile.gender),
          _buildDivider(),
          _buildDetailRow(
            label: 'Age / date of birth',
            value: _profile.ageAndDobDisplay,
          ),
          _buildDivider(),
          _buildDetailRow(label: 'Mobile number', value: _profile.mobileNumber),
          _buildDivider(),
          _buildDetailRow(label: 'Email', value: _profile.email),
          _buildDivider(),
          _buildDetailRow(label: 'Village / ward', value: _profile.village),
          _buildDivider(),
          _buildDetailRow(
            label: 'Gram Panchayat /\nMunicipality',
            value: _profile.panchayat,
          ),
          _buildDivider(),
          _buildDetailRow(label: 'Block / Taluk', value: _profile.block),
          _buildDivider(),
          _buildDetailRow(label: 'Division', value: _profile.division),
          _buildDivider(),
          _buildDetailRow(label: 'District', value: _profile.district),
          _buildDivider(),
          _buildDetailRow(label: 'State', value: _profile.state),
          _buildDivider(),
          _buildDetailRow(
            label: 'Date of joining',
            value: _profile.dateOfJoining,
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'COHV Type',
            value:
                _profile.cohvType ??
                _profile.departmentName ??
                'Public Health Department',
          ),
          _buildDivider(),
          _buildDetailRow(
            label: 'Educational\nqualification',
            value: _profile.qualification,
          ),
          _buildDivider(),
          _buildDetailRow(label: 'Designation', value: _profile.designation),
          _buildDivider(),
          _buildDetailRow(
            label: 'Reporting supervisor',
            value: _profile.supervisor,
          ),
          if (_profile.supervisorMobile != null &&
              _profile.supervisorMobile!.isNotEmpty) ...[
            _buildDivider(),
            _buildDetailRow(
              label: 'Supervisor contact',
              value: _profile.supervisorMobile!,
            ),
          ],
          if (institutionDisplay != '—' && institutionDisplay.isNotEmpty) ...[
            _buildDivider(),
            _buildDetailRow(label: institutionLabel, value: institutionDisplay),
          ],
          _buildDivider(),
          _buildDetailRow(
            label: 'Preferred language',
            value: _profile.preferredLanguage,
          ),
          _buildDivider(),
          _buildDetailRow(label: 'Status', value: _profile.status),
          _buildDivider(),
          _buildDetailRow(label: 'Last login', value: _profile.lastLogin),
          _buildDivider(),
          _buildDetailRow(
            label: 'Registration GPS',
            value: _profile.registrationGps,
          ),
          const SizedBox(height: 18),

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _openEditProfile,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF136B4F),
              ),
              label: const Text(
                'Edit profile',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF136B4F),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF136B4F), width: 1.2),
                backgroundColor: const Color(0xFF136B4F).withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: const Color(0xFF136B4F),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Visually pleasant volunteer avatar
  Widget _buildHeaderAvatar(
    List<String> candidateUrls,
    String? localFilePath,
    String initialLetter,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF136B4F).withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: FallbackNetworkImage(
              urls: candidateUrls,
              localFilePath: localFilePath,
              fallbackBuilder: (context) => _buildAvatarFallback(initialLetter),
            ),
          ),
        ),
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF136B4F),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// Elegant typographic fallback when photo is loading/absent
  Widget _buildAvatarFallback(String initialLetter) {
    return Container(
      color: const Color(0xFFF0FDF4),
      alignment: Alignment.center,
      child: Text(
        initialLetter,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF136B4F),
        ),
      ),
    );
  }

  /// Visually pleasant status pill badge
  Widget _buildStatusBadge(String status) {
    final isActive = status.trim().toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isActive ? const Color(0xFF15803D) : AppColors.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// High-resolution photo preview dialog
  void _showPhotoPreview(List<String> candidateUrls, String? localFilePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 280,
                          color: const Color(0xFFF0FDF4),
                          child: FallbackNetworkImage(
                            urls: candidateUrls,
                            localFilePath: localFilePath,
                            fallbackBuilder: (context) => _buildAvatarFallback(
                              _profile.fullName.isNotEmpty
                                  ? _profile.fullName[0].toUpperCase()
                                  : 'V',
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  '${_profile.volunteerId} · ${_profile.designation}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openEditProfile();
                            },
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Color(0xFF136B4F),
                            ),
                            label: const Text(
                              'Edit Photo',
                              style: TextStyle(
                                color: Color(0xFF136B4F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // CARD 2: LOGIN HISTORY (Scrollable within its card & dynamically updated)
  // =========================================================================

  Widget _buildLoginHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login history',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Recorded automatically at each sign-in.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          if (_loginHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No login records found.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 185),
              child: Scrollbar(
                thumbVisibility: _loginHistory.length > 2,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(right: 6),
                  physics: const ClampingScrollPhysics(),
                  itemCount: _loginHistory.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.divider, height: 22),
                  itemBuilder: (context, index) {
                    final entry = _loginHistory[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.timestamp,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${entry.authMethod} · device ${entry.deviceId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // LOGOUT ACTION
  // =========================================================================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _handleLogout,
        icon: _isLoggingOut
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF136B4F),
                ),
              )
            : const Icon(
                Icons.logout_rounded,
                color: Color(0xFF136B4F),
                size: 18,
              ),
        label: Text(
          _isLoggingOut ? 'Logging out...' : 'Log out',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF136B4F),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF136B4F), width: 1.2),
          backgroundColor: const Color(0xFF136B4F).withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          foregroundColor: const Color(0xFF136B4F),
        ),
      ),
    );
  }

  // =========================================================================
  // REUSABLE BUILDERS
  // =========================================================================

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: AppColors.divider, height: 1);
  }
}
