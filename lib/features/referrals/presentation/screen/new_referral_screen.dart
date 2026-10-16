// Create file: lib/features/referrals/presentation/screen/new_referral_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:cohv/features/referrals/data/referrals_api_service.dart';
import 'package:cohv/features/referrals/domain/referral_models.dart';


class NewReferralScreen extends StatefulWidget {
  final String volunteerId;

  const NewReferralScreen({
    super.key,
    this.volunteerId = 'COHV-26-0001',
  });

  @override
  State<NewReferralScreen> createState() => _NewReferralScreenState();
}

class _NewReferralScreenState extends State<NewReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReferralsApiService _apiService = ReferralsApiService();
  final ImagePicker _picker = ImagePicker();

  String _selectedStream = 'Human';
  String? _selectedReferralType;
  String? _selectedVillage;

  DateTime _eventDate = DateTime.now();
  DateTime _referralDate = DateTime.now();

  final TextEditingController _reasonController = TextEditingController();
  bool _isFollowedUp = false;

  final List<String> _mediaFiles = [];
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Location parameters matching prototype
  double _lat = 28.60928;
  double _lng = 77.367449;
  int _accuracy = 133;
  DateTime _gpsTimestamp = DateTime.now();
  final String _deviceId = 'DEV-C0YBZ9WK';

  bool _isSaving = false;

  final List<String> _streams = [
    'Human',
    'Veterinary / Animal',
    'Environmental / Sanitation',
  ];

  final List<String> _referralTypes = [
    'CHC (Community Health Centre)',
    'PHC (Primary Health Centre)',
    'Sub-Center / Health Wellness Centre',
    'District Hospital',
    'Veterinary Dispensary / Hospital',
  ];

  final List<String> _villages = [
    'Mannanur',
    'Amrabad',
    'Farhabad',
    'Padara',
    'Macharam',
    'Jangamreddipalli',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _mediaCaptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isEventDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEventDate ? _eventDate : _referralDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isEventDate) {
          _eventDate = picked;
        } else {
          _referralDate = picked;
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) setState(() => _mediaFiles.add(photo.path));
    } catch (_) {}
  }

  void _refreshGps() {
    setState(() {
      _gpsTimestamp = DateTime.now();
      _accuracy = 16;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS coordinates refreshed (High accuracy lock).')),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all mandatory fields (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final seq = DateTime.now().millisecondsSinceEpoch % 1000;
      final newReferral = ReferralItem(
        id: 'REF-26-${seq.toString().padLeft(4, '0')}',
        facilityName: _selectedReferralType?.split(' ').first ?? 'CHC',
        stream: _selectedStream,
        referralType: _selectedReferralType!,
        village: _selectedVillage!,
        eventDate: _eventDate,
        referralDate: _referralDate,
        reason: _reasonController.text.trim(),
        isFollowedUp: _isFollowedUp,
        status: 'synced',
        mediaFiles: _mediaFiles,
        mediaCaption: _mediaCaptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: widget.volunteerId,
        deviceId: _deviceId,
      );

      final result = await _apiService.createReferral(newReferral);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral ${result.id} recorded successfully.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventDateStr =
        '${_eventDate.day.toString().padLeft(2, '0')}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.year}';
    final refDateStr =
        '${_referralDate.day.toString().padLeft(2, '0')}-${_referralDate.month.toString().padLeft(2, '0')}-${_referralDate.year}';

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
            'New Referral',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            _buildAppBarButton(
              icon: Icons.notifications_none_rounded,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            _buildAppBarButton(
              icon: Icons.sync_rounded,
              onTap: () {},
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Referral stream *
                  _buildLabel('Referral stream *'),
                  _buildDropdown(
                    value: _selectedStream,
                    items: _streams,
                    onChanged: (val) => setState(() => _selectedStream = val!),
                  ),
                  const SizedBox(height: 16),

                  // Referral type *
                  _buildLabel('Referral type *'),
                  _buildDropdown(
                    value: _selectedReferralType,
                    items: _referralTypes,
                    onChanged: (val) => setState(() => _selectedReferralType = val),
                    validator: (val) => val == null ? 'Select referral type' : null,
                  ),
                  const SizedBox(height: 16),

                  // Village / ward *
                  _buildLabel('Village / ward *'),
                  _buildDropdown(
                    value: _selectedVillage,
                    items: _villages,
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    validator: (val) => val == null ? 'Select village / ward' : null,
                  ),
                  const SizedBox(height: 16),

                  // Event date * & Referral date *
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Event date *'),
                            _buildPickerTile(
                              text: eventDateStr,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => _pickDate(true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Referral date *'),
                            _buildPickerTile(
                              text: refDateStr,
                              icon: Icons.calendar_today_outlined,
                              onTap: () => _pickDate(false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reason for referral
                  _buildLabel('Reason for referral'),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Checkbox: Referral followed up
                  Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _isFollowedUp,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _isFollowedUp = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Referral followed up',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 16),

                  // PHOTO / VIDEO / DOCUMENTATION
                  _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Photograph',
                          onTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Video',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Document',
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Up to 5 photographs (5 MB each), 2 videos (25 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 12),

                  // Description / caption
                  _buildLabel('Description / caption'),
                  TextFormField(
                    controller: _mediaCaptionController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Privacy Notice
                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 20),

                  // LOCATION
                  _buildSectionHeader('LOCATION'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_lat, $_lng · ±$_accuracy m',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_eventDate.year}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.day.toString().padLeft(2, '0')} 16:03 · ${_selectedVillage ?? "Mannanur"} › Amrabad › Nagarkurnool › Telangana',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Volunteer ${widget.volunteerId} · Device $_deviceId',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _refreshGps,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Refresh', style: TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 13.5, color: AppColors.textDark)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
      decoration: InputDecoration(
        hintText: 'Select',
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
            Icon(icon, color: AppColors.textDark, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
        currentIndex: 1, // Highlight 'Actions'
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
