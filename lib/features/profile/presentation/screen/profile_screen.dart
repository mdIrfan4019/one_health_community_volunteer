// Create file: lib/features/profile/presentation/screen/profile_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/profile_api_service.dart';
import '../../domain/profile_models.dart';

class ProfileScreen extends StatefulWidget {
  final String volunteerId;

  const ProfileScreen({
    super.key,
    this.volunteerId = 'COHV-26-0001',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileApiService _apiService = ProfileApiService();

  late DetailedVolunteerProfile _profile;
  List<LoginHistoryEntry> _loginHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default initial state
    _profile = DetailedVolunteerProfile(
      fullName: 'Test1',
      volunteerId: widget.volunteerId,
      gender: 'Male',
      dob: '10 Jul 1997',
      mobileNumber: '9565897524',
      email: 'test1@gmail.com',
      village: 'Mannanur',
      panchayat: 'Mannanur',
      block: 'Amrabad',
      division: 'Mahabubnagar Division',
      district: 'Nagarkurnool',
      state: 'Telangana',
      dateOfJoining: '11 Oct 2026',
      qualification: 'Higher Secondary',
      profession: 'Farmer',
      supervisor: 'Assigned on approval',
      healthFacilityLinked: 'CHC',
      veterinaryInstitutionLinked: '—',
      forestInstitutionLinked: '—',
      preferredLanguage: 'English',
      status: 'Active',
      lastLogin: '14 Oct 2026, 10:23',
      registrationGps: '28.609306, 77.367452',
    );
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getDetailedProfile(widget.volunteerId);
      final history = await _apiService.getLoginHistory(widget.volunteerId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loginHistory = history;
        });
      }
    } catch (_) {
      // Keep local state
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Volunteer Full Profile Card
          _buildProfileDetailsCard(),
          const SizedBox(height: 16),

          // 2. Login History Card
          _buildLoginHistoryCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD 1: FULL PROFILE DETAILS
  // =========================================================================

  Widget _buildProfileDetailsCard() {
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
          // Header Row with [A] Badge and Name
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: const Text(
                  'A',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9D174D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _profile.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Volunteer ID & Designation
          Row(
            children: [
              Text(
                _profile.volunteerId,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                ' · ',
                style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
              ),
              Text(
                _profile.designation,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Photo Placeholder Box
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.textLight,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),

          // 21 Key-Value Pairs
          _buildDetailRow(label: 'Gender', value: _profile.gender),
          _buildDivider(),
          _buildDetailRow(label: 'Age / date of birth', value: _profile.dob),
          _buildDivider(),
          _buildDetailRow(label: 'Mobile number', value: _profile.mobileNumber),
          _buildDivider(),
          _buildDetailRow(label: 'Email', value: _profile.email),
          _buildDivider(),
          _buildDetailRow(label: 'Village / ward', value: _profile.village),
          _buildDivider(),
          _buildDetailRow(label: 'Gram Panchayat / Municipality', value: _profile.panchayat),
          _buildDivider(),
          _buildDetailRow(label: 'Block / Taluk', value: _profile.block),
          _buildDivider(),
          _buildDetailRow(label: 'Division', value: _profile.division),
          _buildDivider(),
          _buildDetailRow(label: 'District', value: _profile.district),
          _buildDivider(),
          _buildDetailRow(label: 'State', value: _profile.state),
          _buildDivider(),
          _buildDetailRow(label: 'Date of joining', value: _profile.dateOfJoining),
          _buildDivider(),
          _buildDetailRow(label: 'Educational qualification', value: _profile.qualification),
          _buildDivider(),
          _buildDetailRow(label: 'Profession', value: _profile.profession),
          _buildDivider(),
          _buildDetailRow(label: 'Reporting supervisor', value: _profile.supervisor),
          _buildDivider(),
          _buildDetailRow(label: 'Health facility linked', value: _profile.healthFacilityLinked),
          _buildDivider(),
          _buildDetailRow(label: 'Veterinary institution linked', value: _profile.veterinaryInstitutionLinked),
          _buildDivider(),
          _buildDetailRow(label: 'Forest institution linked', value: _profile.forestInstitutionLinked),
          _buildDivider(),
          _buildDetailRow(label: 'Preferred language', value: _profile.preferredLanguage),
          _buildDivider(),
          _buildDetailRow(label: 'Status', value: _profile.status),
          _buildDivider(),
          _buildDetailRow(label: 'Last login', value: _profile.lastLogin),
          _buildDivider(),
          _buildDetailRow(label: 'Registration GPS', value: _profile.registrationGps),
          const SizedBox(height: 18),

          // Edit Profile Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile edit mode ready.')),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: AppColors.primary,
              ),
              child: const Text(
                'Edit profile',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD 2: LOGIN HISTORY (Section 2 Shared Handset Audit Log)
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          if (_loginHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No login records found.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _loginHistory.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.divider,
                height: 22,
              ),
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
        ],
      ),
    );
  }

  // =========================================================================
  // REUSABLE BUILDERS
  // =========================================================================

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
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
