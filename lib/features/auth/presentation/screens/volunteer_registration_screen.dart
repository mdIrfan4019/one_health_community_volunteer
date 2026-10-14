// Create file: lib/features/auth/presentation/screens/volunteer_registration_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../data/demographic_repository.dart';
import '../../domain/auth_models.dart';
import '../widgets/attention_banner.dart';
import 'awaiting_approval_screen.dart';

class VolunteerRegistrationScreen extends StatefulWidget {
  final String? mobileNumber;

  const VolunteerRegistrationScreen({
    super.key,
    this.mobileNumber,
  });

  @override
  State<VolunteerRegistrationScreen> createState() => _VolunteerRegistrationScreenState();
}

class _VolunteerRegistrationScreenState extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _apiService = AuthApiService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late final TextEditingController _mobileController;
  final _pinController = TextEditingController();

  // Form Selections
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedCohvType;

  // Cascading Geographic Anchors
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedBlock;
  String? _selectedPanchayat;
  String? _selectedVillage;

  DateTime? _selectedDateOfJoining = DateTime.now();
  String? _selectedQualification;
  String? _selectedProfession;

  // System & Hardware Values
  final String _volunteerId = 'COHV-26-0013'; // Device-sequenced candidate ID
  final String _deviceId = 'DEV-C0YBZ9WK';
  double _lat = 28.609306;
  double _lng = 77.367452;
  int _accuracy = 153;
  DateTime _gpsTimestamp = DateTime.now();

  bool _isLoading = false;
  List<String> _attentionErrors = [];

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.mobileNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // =========================================================================
  // DATE PICKERS & SPEC VALIDATIONS
  // =========================================================================

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      // Validate dynamic age >= 18 years
      if (picked.isAfter(eighteenYearsAgo)) {
        setState(() {
          _attentionErrors = ['Volunteer must be at least 18 years old.'];
        });
        return;
      }
      setState(() {
        _selectedDob = picked;
        _attentionErrors = [];
      });
    }
  }

  Future<void> _pickJoiningDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfJoining ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDateOfJoining = picked);
    }
  }

  void _refreshGps() {
    setState(() {
      _gpsTimestamp = DateTime.now();
      _accuracy = 12; // Simulated fused location lock
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates refreshed (High accuracy lock).'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // =========================================================================
  // SUBMISSION & SUPERVISOR GATE
  // =========================================================================

  Future<void> _handleRegister() async {
    setState(() => _attentionErrors = []);

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _attentionErrors = ['Please fill all mandatory fields marked with an asterisk (*).'];
      });
      return;
    }

    if (_selectedDob == null) {
      setState(() => _attentionErrors = ['Date of Birth is mandatory.']);
      return;
    }

    if (_selectedState == null || _selectedDistrict == null || _selectedBlock == null ||
        _selectedPanchayat == null || _selectedVillage == null) {
      setState(() => _attentionErrors = ['Complete geographic cascading selection is mandatory.']);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = VolunteerRegistrationRequest(
        fullName: _nameController.text.trim(),
        gender: _selectedGender!,
        dob: _selectedDob!,
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        cohvType: _selectedCohvType!,
        state: _selectedState!,
        district: _selectedDistrict!,
        block: _selectedBlock!,
        panchayat: _selectedPanchayat!,
        village: _selectedVillage!,
        dateOfJoining: _selectedDateOfJoining ?? DateTime.now(),
        qualification: _selectedQualification!,
        profession: _selectedProfession!,
        pin: _pinController.text.trim(),
        volunteerId: _volunteerId,
        latitude: _lat,
        longitude: _lng,
      );

      final result = await _apiService.registerVolunteer(request);

      if (!mounted) return;

      // Navigate to Awaiting Approval Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AwaitingApprovalScreen(
            fullName: result.fullName,
            volunteerId: result.volunteerId,
            supervisorStatus: result.supervisorStatus,
            accountStatus: result.accountStatus,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Volunteer Registration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_attentionErrors.isNotEmpty) ...[
                      AttentionBanner(errors: _attentionErrors),
                      const SizedBox(height: 18),
                    ],

                    // Volunteer Name *
                    _buildLabel('Volunteer Name *'),
                    _buildTextFormField(
                      controller: _nameController,
                      hint: 'Full name',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Gender *
                    _buildLabel('Gender *'),
                    _buildDropdown(
                      value: _selectedGender,
                      items: DemographicRepository.genders,
                      onChanged: (val) => setState(() => _selectedGender = val),
                      validator: (val) => val == null ? 'Please select gender' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth *
                    _buildLabel('Date of Birth *'),
                    _buildDatePickerTile(
                      displayValue: _selectedDob == null
                          ? 'dd-mm-yyyy'
                          : '${_selectedDob!.day.toString().padLeft(2, '0')}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.year}',
                      onTap: _pickDob,
                    ),
                    const SizedBox(height: 16),

                    // Mobile Number *
                    _buildLabel('Mobile Number *'),
                    _buildTextFormField(
                      controller: _mobileController,
                      hint: '10-digit mobile number',
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                          return 'Valid 10-digit mobile number required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // E-mail *
                    _buildLabel('E-mail *'),
                    _buildTextFormField(
                      controller: _emailController,
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || !val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // COHV Type *
                    _buildLabel('COHV Type *'),
                    _buildDropdown(
                      value: _selectedCohvType,
                      items: DemographicRepository.cohvTypes,
                      onChanged: (val) => setState(() => _selectedCohvType = val),
                      validator: (val) => val == null ? 'Please select COHV Type' : null,
                    ),
                    const SizedBox(height: 16),

                    // =========================================================
                    // CASCADING GEOGRAPHIC HIERARCHY (Spec Section 3)
                    // =========================================================

                    // State *
                    _buildLabel('State *'),
                    _buildDropdown(
                      value: _selectedState,
                      items: DemographicRepository.getStates(),
                      onChanged: (val) {
                        setState(() {
                          _selectedState = val;
                          _selectedDistrict = null;
                          _selectedBlock = null;
                          _selectedPanchayat = null;
                          _selectedVillage = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select State' : null,
                    ),
                    const SizedBox(height: 16),

                    // District *
                    _buildLabel('District *'),
                    _buildDropdown(
                      value: _selectedDistrict,
                      items: DemographicRepository.getDistricts(_selectedState),
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrict = val;
                          _selectedBlock = null;
                          _selectedPanchayat = null;
                          _selectedVillage = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select District' : null,
                    ),
                    const SizedBox(height: 16),

                    // Block / Taluk *
                    _buildLabel('Block / Taluk *'),
                    _buildDropdown(
                      value: _selectedBlock,
                      items: DemographicRepository.getBlocks(_selectedState, _selectedDistrict),
                      onChanged: (val) {
                        setState(() {
                          _selectedBlock = val;
                          _selectedPanchayat = null;
                          _selectedVillage = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select Block / Taluk' : null,
                    ),
                    const SizedBox(height: 16),

                    // Gram Panchayat / Municipality *
                    _buildLabel('Gram Panchayat / Municipality *'),
                    _buildDropdown(
                      value: _selectedPanchayat,
                      items: DemographicRepository.getPanchayats(_selectedState, _selectedDistrict, _selectedBlock),
                      onChanged: (val) {
                        setState(() {
                          _selectedPanchayat = val;
                          _selectedVillage = null;
                        });
                      },
                      validator: (val) => val == null ? 'Please select Panchayat / Municipality' : null,
                    ),
                    const SizedBox(height: 16),

                    // Village / Ward *
                    _buildLabel('Village / Ward *'),
                    _buildDropdown(
                      value: _selectedVillage,
                      items: DemographicRepository.getVillages(
                        _selectedState,
                        _selectedDistrict,
                        _selectedBlock,
                        _selectedPanchayat,
                      ),
                      onChanged: (val) => setState(() => _selectedVillage = val),
                      validator: (val) => val == null ? 'Please select Village / Ward' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date of Joining *
                    _buildLabel('Date of Joining *'),
                    _buildDatePickerTile(
                      displayValue: _selectedDateOfJoining == null
                          ? 'dd-mm-yyyy'
                          : '${_selectedDateOfJoining!.day.toString().padLeft(2, '0')}-${_selectedDateOfJoining!.month.toString().padLeft(2, '0')}-${_selectedDateOfJoining!.year}',
                      onTap: _pickJoiningDate,
                    ),
                    const SizedBox(height: 16),

                    // Educational Qualification *
                    _buildLabel('Educational Qualification *'),
                    _buildDropdown(
                      value: _selectedQualification,
                      items: DemographicRepository.qualifications,
                      onChanged: (val) => setState(() => _selectedQualification = val),
                      validator: (val) => val == null ? 'Select qualification' : null,
                    ),
                    const SizedBox(height: 16),

                    // Profession *
                    _buildLabel('Profession *'),
                    _buildDropdown(
                      value: _selectedProfession,
                      items: DemographicRepository.professions,
                      onChanged: (val) => setState(() => _selectedProfession = val),
                      validator: (val) => val == null ? 'Select profession' : null,
                    ),
                    const SizedBox(height: 16),

                    // Reporting Supervisor (Read-only)
                    _buildLabel('Reporting Supervisor'),
                    _buildReadOnlyField('Assigned on approval'),
                    const SizedBox(height: 16),

                    // PIN * (4-6 digits)
                    _buildLabel('PIN *'),
                    _buildTextFormField(
                      controller: _pinController,
                      hint: '4–6 numeric digits',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || !RegExp(r'^\d{4,6}$').hasMatch(val.trim())) {
                          return 'PIN must be 4 to 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Volunteer ID (Read-only Preview)
                    _buildLabel('Volunteer ID'),
                    _buildReadOnlyField(_volunteerId),
                    const SizedBox(height: 20),

                    // Profile Photograph Section
                    _buildSectionHeader('PROFILE PHOTOGRAPH'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDashedActionButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Camera capture module ready.')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildDashedActionButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gallery selector ready.')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Registration Location Card
                    _buildSectionHeader('REGISTRATION LOCATION'),
                    const SizedBox(height: 8),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_gpsTimestamp.year}-${_gpsTimestamp.month.toString().padLeft(2, '0')}-${_gpsTimestamp.day.toString().padLeft(2, '0')} ${_gpsTimestamp.hour.toString().padLeft(2, '0')}:${_gpsTimestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Volunteer — · Device $_deviceId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _refreshGps,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              minimumSize: const Size(80, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text('Refresh', style: TextStyle(fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Register', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Back to sign in link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back to sign in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // REUSABLE FIELD BUILDERS
  // =========================================================================

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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
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

  Widget _buildDatePickerTile({
    required String displayValue,
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
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: displayValue == 'dd-mm-yyyy' ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const Icon(Icons.calendar_today_outlined, color: AppColors.textDark, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildDashedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.border, style: BorderStyle.solid),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
