import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';
import 'package:cohv/features/auth/data/demographic_repository.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../../data/profile_api_service.dart';
import '../../domain/profile_models.dart';

class EditProfileScreen extends StatefulWidget {
  final DetailedVolunteerProfile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileApiService _apiService = ProfileApiService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _dobController;
  late TextEditingController _otherInstitutionController;

  String? _gender;
  String? _language;
  File? _newPhotoFile;
  bool _isSaving = false;
  bool _isLoadingDropdowns = false;
  bool _isLoadingInstitutions = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _languageOptions = ['English', 'Telugu', 'Hindi'];

  // Dynamic Metadata
  List<ProfessionModel> _professions = [];
  ProfessionModel? _selectedProfession;

  List<EducationModel> _educations = [];
  EducationModel? _selectedEducation;

  List<DepartmentModel> _departments = [];
  DepartmentModel? _selectedDepartment;

  List<InstitutionModel> _institutions = [];
  InstitutionModel? _selectedInstitution;
  String _institutionFieldLabel = 'Institution';

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController =
        TextEditingController(text: p.fullName != '—' ? p.fullName : '');
    _mobileController =
        TextEditingController(text: p.mobileNumber != '—' ? p.mobileNumber : '');
    _emailController =
        TextEditingController(text: p.email != '—' ? p.email : '');
    _dobController = TextEditingController(text: p.dob != '—' ? p.dob : '');
    _otherInstitutionController = TextEditingController(
      text: p.otherInstitutionName ??
          (p.institutionName != null && p.institutionName != 'CHC'
              ? p.institutionName!
              : ''),
    );

    _gender = _genderOptions.contains(p.gender) ? p.gender : 'Male';
    _language = _languageOptions.contains(p.preferredLanguage)
        ? p.preferredLanguage
        : 'English';

    _loadDynamicMetadata();
  }

  Future<void> _loadDynamicMetadata() async {
    setState(() => _isLoadingDropdowns = true);

    try {
      final results = await Future.wait([
        DemographicRepository.fetchProfessionsFromApi()
            .catchError((_) => DemographicRepository.getFallbackProfessions()),
        DemographicRepository.fetchEducationsFromApi()
            .catchError((_) => DemographicRepository.getFallbackEducations()),
        DemographicRepository.fetchDepartmentsFromApi()
            .catchError((_) => DemographicRepository.getFallbackDepartments()),
      ]);

      final profs = results[0] as List<ProfessionModel>;
      final edus = results[1] as List<EducationModel>;
      final depts = results[2] as List<DepartmentModel>;

      if (mounted) {
        setState(() {
          _professions = profs;
          _educations = edus;
          _departments = depts;

          final p = widget.profile;
          // 1. Resolve Designation (mapped strictly from profession_id / profession_name)
          if (p.professionId != null && p.professionId! > 0) {
            _selectedProfession = profs
                    .where((item) => item.professionId == p.professionId)
                    .firstOrNull ??
                (profs.isNotEmpty
                    ? profs.first
                    : ProfessionModel(
                        professionId: p.professionId!,
                        professionName: p.profession,
                      ));
          } else if (p.profession.isNotEmpty && p.profession != '—') {
            _selectedProfession = profs
                    .where((item) =>
                        item.professionName.toLowerCase() ==
                        p.profession.toLowerCase())
                    .firstOrNull ??
                (profs.isNotEmpty ? profs.first : null);
          } else if (p.designation.isNotEmpty && p.designation != '—') {
            _selectedProfession = profs
                    .where((item) =>
                        item.professionName.toLowerCase() ==
                        p.designation.toLowerCase())
                    .firstOrNull ??
                (profs.isNotEmpty ? profs.first : null);
          } else if (profs.isNotEmpty) {
            _selectedProfession = profs.first;
          }

          // 2. Resolve Educational Qualification
          if (p.educationId != null && p.educationId! > 0) {
            _selectedEducation = edus
                    .where((item) => item.educationId == p.educationId)
                    .firstOrNull ??
                (edus.isNotEmpty
                    ? edus.first
                    : EducationModel(
                        educationId: p.educationId!,
                        educationName: p.qualification,
                      ));
          } else if (p.qualification.isNotEmpty && p.qualification != '—') {
            _selectedEducation = edus
                    .where((item) =>
                        item.educationName.toLowerCase() ==
                        p.qualification.toLowerCase())
                    .firstOrNull ??
                (edus.isNotEmpty ? edus.first : null);
          } else if (edus.isNotEmpty) {
            _selectedEducation = edus.first;
          }

          // 3. Resolve Department
          if (p.departmentId != null && p.departmentId! > 0) {
            _selectedDepartment = depts.firstWhere(
              (item) => item.departmentId == p.departmentId,
              orElse: () => depts.firstWhere(
                (d) => d.departmentId == 1,
                orElse: () => depts.first,
              ),
            );
          } else if (depts.isNotEmpty) {
            _selectedDepartment = depts.first;
          }
        });

        // 4. Fetch institutions for the resolved department
        final deptId = _selectedDepartment?.departmentId ??
            widget.profile.departmentId ??
            1;
        await _loadInstitutionsForDepartment(
          deptId,
          initialTypeId: widget.profile.institutionTypeId,
        );
      }
    } catch (e) {
      debugPrint('[EDIT_PROFILE] Error loading metadata: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  Future<void> _loadInstitutionsForDepartment(
    int departmentId, {
    int? initialTypeId,
    bool resetSelection = false,
  }) async {
    setState(() => _isLoadingInstitutions = true);

    try {
      final list = await DemographicRepository.fetchInstitutionsFromApi(
        departmentId,
      ).catchError(
        (_) => DemographicRepository.getFallbackInstitutions(departmentId),
      );

      if (mounted) {
        setState(() {
          _institutions = list;
          if (list.isNotEmpty) {
            _institutionFieldLabel = list.first.fieldLabel.isNotEmpty
                ? list.first.fieldLabel
                : 'Institution';

            if (!resetSelection && initialTypeId != null && initialTypeId > 0) {
              _selectedInstitution = list.firstWhere(
                (item) => item.institutionTypeId == initialTypeId,
                orElse: () => list.first,
              );
            } else if (resetSelection) {
              _selectedInstitution = list.isNotEmpty ? list.first : null;
            } else if (_selectedInstitution != null) {
              _selectedInstitution = list.firstWhere(
                (item) =>
                    item.institutionTypeId ==
                    _selectedInstitution!.institutionTypeId,
                orElse: () => list.first,
              );
            } else {
              _selectedInstitution = list.first;
            }
          } else {
            _institutionFieldLabel = 'Institution';
            _selectedInstitution = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[EDIT_PROFILE] Error loading institutions: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInstitutions = false);
    }
  }

  void _onDepartmentChanged(DepartmentModel? newDept) {
    if (newDept == null ||
        newDept.departmentId == _selectedDepartment?.departmentId) {
      return;
    }
    setState(() {
      _selectedDepartment = newDept;
    });
    _loadInstitutionsForDepartment(newDept.departmentId, resetSelection: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _otherInstitutionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _newPhotoFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('[PROFILE] Error picking image: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Take photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_newPhotoFile != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove selected photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _newPhotoFile = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime(1997, 7, 10);
    final currentText = _dobController.text.trim();
    if (currentText.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(currentText);
        if (parsed != null) initial = parsed;
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      const months = [
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
      final formatted =
          '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() => _dobController.text = formatted);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isOther = _selectedInstitution?.isOther == true;
      final customName =
          isOther ? _otherInstitutionController.text.trim() : null;
      final effectiveInstName = isOther
          ? customName
          : (_selectedInstitution?.optionName ??
              widget.profile.institutionName);

      final updatedProfile = widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : '—',
        gender: _gender ?? 'Male',
        dob: _dobController.text.trim().isNotEmpty
            ? _dobController.text.trim()
            : widget.profile.dob,
        qualification: _selectedEducation?.educationName ??
            widget.profile.qualification,
        educationId:
            _selectedEducation?.educationId ?? widget.profile.educationId,
        profession:
            _selectedProfession?.professionName ?? widget.profile.profession,
        professionId:
            _selectedProfession?.professionId ?? widget.profile.professionId,
        designation: _selectedProfession?.professionName ??
            widget.profile.designation,
        departmentId: _selectedDepartment?.departmentId ??
            widget.profile.departmentId,
        departmentName: _selectedDepartment?.departmentName ??
            widget.profile.departmentName,
        cohvType: _selectedDepartment?.departmentName ??
            widget.profile.cohvType,
        institutionTypeId: _selectedInstitution?.institutionTypeId ??
            widget.profile.institutionTypeId,
        institutionTypeName: _selectedInstitution?.optionName ??
            widget.profile.institutionTypeName,
        institutionFieldLabel: _institutionFieldLabel,
        institutionName: effectiveInstName,
        otherInstitutionName: customName,
        preferredLanguage: _language ?? 'English',
        photoUrl: _newPhotoFile != null
            ? _newPhotoFile!.path
            : widget.profile.photoUrl,
      );

      await _apiService.updateProfile(updatedProfile, photoFile: _newPhotoFile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPhotoUrl =
        ApiConstants.resolveImageUrl(widget.profile.photoUrl);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'Edit Profile',
          volunteerId: widget.profile.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Picture Editor Card
                _buildPhotoEditorCard(resolvedPhotoUrl),
                const SizedBox(height: 16),

                // 2. Personal & Contact Details Card
                _buildPersonalDetailsCard(),
                const SizedBox(height: 16),

                // 3. Locked / Assigned Administrative Jurisdictions Card
                _buildLockedJurisdictionCard(),
                const SizedBox(height: 24),

                // 4. Save Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoEditorCard(String? resolvedPhotoUrl) {
    final candidateUrls =
        ApiConstants.resolveImageCandidateUrls(widget.profile.photoUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF2F8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _newPhotoFile != null
                        ? Image.file(
                            _newPhotoFile!,
                            fit: BoxFit.cover,
                          )
                        : FallbackNetworkImage(
                            urls: candidateUrls,
                            localFilePath: widget.profile.photoUrl,
                            fallbackBuilder: (context) =>
                                _buildAvatarFallback(),
                          ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: InkWell(
                    onTap: _showImagePickerModal,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.profile.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            Text(
              widget.profile.volunteerId,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final initial = widget.profile.fullName.isNotEmpty
        ? widget.profile.fullName[0].toUpperCase()
        : 'V';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),

          // Full Name
          _buildTextField(
            label: 'Full Name *',
            controller: _nameController,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Full name is required' : null,
          ),
          const SizedBox(height: 12),

          // Gender
          _buildDropdownField<String>(
            label: 'Gender *',
            value: _gender,
            items: _genderOptions,
            onChanged: (val) => setState(() => _gender = val),
          ),
          const SizedBox(height: 12),

          // Date of Birth
          InkWell(
            onTap: _selectDateOfBirth,
            child: IgnorePointer(
              child: _buildTextField(
                label: 'Date of Birth (DOB) *',
                controller: _dobController,
                suffixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Date of birth is required'
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mobile Number
          _buildTextField(
            label: 'Mobile Number *',
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (val) {
              if (val == null || val.trim().length != 10) {
                return 'Enter valid 10-digit mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Email Address
          _buildTextField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Educational Qualification (API-driven)
          _buildDropdownField<EducationModel>(
            label: 'Educational Qualification',
            value: _selectedEducation,
            items: _educations,
            isLoading: _isLoadingDropdowns,
            onChanged: (val) => setState(() => _selectedEducation = val),
          ),
          const SizedBox(height: 12),

          // Designation (Mapped strictly to profession_id / profession_name)
          _buildDropdownField<ProfessionModel>(
            label: 'Designation',
            value: _selectedProfession,
            items: _professions,
            isLoading: _isLoadingDropdowns,
            onChanged: (val) => setState(() => _selectedProfession = val),
          ),
          const SizedBox(height: 12),

          // Department (Triggers dynamic reload of institution metadata)
          _buildDropdownField<DepartmentModel>(
            label: 'Department',
            value: _selectedDepartment,
            items: _departments,
            isLoading: _isLoadingDropdowns,
            onChanged: _onDepartmentChanged,
          ),
          const SizedBox(height: 12),

          // Dynamic Institution (API-driven based on selected department)
          if (_institutions.isNotEmpty) ...[
            _buildDropdownField<InstitutionModel>(
              label: _institutionFieldLabel,
              value: _selectedInstitution,
              items: _institutions,
              isLoading: _isLoadingInstitutions,
              onChanged: (val) => setState(() => _selectedInstitution = val),
            ),
            const SizedBox(height: 12),
            // Custom institution input when is_other is true
            if (_selectedInstitution?.isOther == true) ...[
              _buildTextField(
                label: 'Specify $_institutionFieldLabel *',
                controller: _otherInstitutionController,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please specify $_institutionFieldLabel name'
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ] else if (!_isLoadingInstitutions && _selectedDepartment != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'No institution options required for ${_selectedDepartment?.departmentName}.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Preferred Language
          _buildDropdownField<String>(
            label: 'Preferred Language',
            value: _language,
            items: _languageOptions,
            onChanged: (val) => setState(() => _language = val),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedJurisdictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                'Assigned Administrative Postings (Locked)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Assigned by district surveillance administration. Cannot be altered directly.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),

          _buildReadOnlyRow('Volunteer ID', widget.profile.volunteerId),
          _buildReadOnlyRow(
            'COHV Type',
            _selectedDepartment?.departmentName ??
                widget.profile.cohvType ??
                widget.profile.departmentName ??
                'Public Health Department',
          ),
          _buildReadOnlyRow('Reporting Supervisor', widget.profile.supervisor),
          _buildReadOnlyRow('Village / Ward', widget.profile.village),
          _buildReadOnlyRow('Gram Panchayat', widget.profile.panchayat),
          _buildReadOnlyRow('Block / Taluk', widget.profile.block),
          _buildReadOnlyRow('District', widget.profile.district),
          _buildReadOnlyRow('State', widget.profile.state),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            isDense: true,
            counterText: '',
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    bool isLoading = false,
    String? hintText,
  }) {
    final effectiveValue = items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          key: ValueKey(effectiveValue),
          initialValue: effectiveValue,
          onChanged: isLoading || items.isEmpty ? null : onChanged,
          isDense: true,
          isExpanded: true,
          hint: Text(
            isLoading ? 'Loading $label...' : (hintText ?? 'Select $label'),
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
