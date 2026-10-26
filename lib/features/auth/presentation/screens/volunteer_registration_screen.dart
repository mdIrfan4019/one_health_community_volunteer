// Create file: lib/features/auth/presentation/screens/volunteer_registration_screen.dart

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/auth_api_service.dart';
import '../../data/demographic_repository.dart';
import '../../domain/auth_models.dart';
import '../../domain/demographic_models.dart';
import '../widgets/attention_banner.dart';
import 'awaiting_approval_screen.dart';

import 'package:flutter/services.dart';

import 'dart:io';

import 'package:image_picker/image_picker.dart';

const Color _primaryGreen = Color(0xFF136B4F);
const Color _formBackground = Color(0xFFF2F7F4);
const Color _locationCardBg = Color(0xFFE8F5E9);
const Color _locationCardBorder = Color(0xFFD1F2DD);

class VolunteerRegistrationScreen extends StatefulWidget {
  final String? mobileNumber;

  const VolunteerRegistrationScreen({super.key, this.mobileNumber});

  @override
  State<VolunteerRegistrationScreen> createState() =>
      VolunteerRegistrationScreenState();
}

class VolunteerRegistrationScreenState
    extends State<VolunteerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _apiService = AuthApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Selected Profile Photograph
  File? _pickedImage;
  String? _pickedImagePath;

  // Controllers
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final TextEditingController _otherQualificationController =
      TextEditingController();
  final TextEditingController _customInstitutionController =
      TextEditingController();
  late final TextEditingController _mobileController;
  final _pinController = TextEditingController();

  // Form Selections
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedCohvType;
  DepartmentModel? _selectedDepartmentModel;
  int? _selectedDepartmentId;
  List<DepartmentModel> _departmentList = [];
  bool _isLoadingDepartments = false;
  String? _departmentLoadError;

  // Institution Selection (Cascading from selected Department / COHV Type)
  List<InstitutionModel> _institutionList = [];
  bool _isLoadingInstitutions = false;
  String? _institutionLoadError;
  InstitutionModel? _selectedInstitutionModel;
  int? _selectedInstitutionTypeId;
  String? _selectedInstitutionOption;
  int _departmentRequestToken = 0;

  // Cascading Geographic Anchors
  List<StateModel> _stateList = [];
  bool _isLoadingStates = false;
  String? _stateLoadError;
  StateModel? _selectedStateModel;
  String? _selectedState;

  List<DistrictModel> _districtList = [];
  bool _isLoadingDistricts = false;
  String? _districtLoadError;
  DistrictModel? _selectedDistrictModel;
  String? _selectedDistrict;

  List<BlockModel> _blockList = [];
  bool _isLoadingBlocks = false;
  String? _blockLoadError;
  BlockModel? _selectedBlockModel;
  String? _selectedBlock;

  List<PanchayatModel> _panchayatList = [];
  bool _isLoadingPanchayats = false;
  String? _panchayatLoadError;
  PanchayatModel? _selectedPanchayatModel;
  String? _selectedPanchayat;

  List<VillageModel> _villageList = [];
  bool _isLoadingVillages = false;
  String? _villageLoadError;
  VillageModel? _selectedVillageModel;
  String? _selectedVillage;

  DateTime? _selectedDateOfJoining = DateTime.now();

  List<EducationModel> _educationList = [];
  bool _isLoadingEducations = false;
  String? _educationLoadError;
  EducationModel? _selectedEducationModel;
  String? _selectedQualification;

  List<ProfessionModel> _professionList = [];
  bool _isLoadingProfessions = false;
  String? _professionLoadError;
  ProfessionModel? _selectedProfessionModel;
  String? _selectedProfession;

  VillageModel? get selectedVillageModel => _selectedVillageModel;
  EducationModel? get selectedEducationModel => _selectedEducationModel;
  ProfessionModel? get selectedProfessionModel => _selectedProfessionModel;
  DepartmentModel? get selectedDepartmentModel => _selectedDepartmentModel;
  InstitutionModel? get selectedInstitutionModel => _selectedInstitutionModel;

  String get _currentInstitutionFieldLabel {
    if (_institutionList.isNotEmpty &&
        _institutionList.first.fieldLabel.trim().isNotEmpty) {
      return _institutionList.first.fieldLabel.trim();
    }
    if (_selectedInstitutionModel != null &&
        _selectedInstitutionModel!.fieldLabel.trim().isNotEmpty) {
      return _selectedInstitutionModel!.fieldLabel.trim();
    }
    final dept = _selectedCohvType?.toLowerCase() ?? '';
    if (dept.contains('public health')) return 'Health facility';
    if (dept.contains('animal')) return 'Veterinary institution';
    if (dept.contains('wildlife')) return 'Forest institution';
    if (dept.contains('environment')) return 'Environment institution';
    return 'Institution';
  }

  String get currentInstitutionFieldLabel => _currentInstitutionFieldLabel;

  String get _customInstitutionInputLabel {
    final label = _currentInstitutionFieldLabel;
    if (label.isEmpty) return 'Specify institution *';
    final lowerStart = '${label[0].toLowerCase()}${label.substring(1)}';
    return 'Specify $lowerStart *';
  }

  String get customInstitutionInputLabel => _customInstitutionInputLabel;

  List<SupervisorModel> _supervisorList = [];
  bool _isLoadingSupervisors = false;
  String? _supervisorLoadError;
  SupervisorModel? _selectedSupervisorModel;
  String? _selectedSupervisor;

  SupervisorModel? get selectedSupervisorModel => _selectedSupervisorModel;

  @visibleForTesting
  DateTime get maxDobCutoff => _maxDobCutoff;
  @visibleForTesting
  DateTime? get selectedDob => _selectedDob;
  @visibleForTesting
  set selectedDob(DateTime? val) => setState(() => _selectedDob = val);
  @visibleForTesting
  TextEditingController get mobileController => _mobileController;
  @visibleForTesting
  List<DepartmentModel> get departmentList => _departmentList;
  @visibleForTesting
  List<StateModel> get stateList => _stateList;
  @visibleForTesting
  List<DistrictModel> get districtList => _districtList;
  @visibleForTesting
  List<BlockModel> get blockList => _blockList;
  @visibleForTesting
  List<PanchayatModel> get panchayatList => _panchayatList;
  @visibleForTesting
  List<VillageModel> get villageList => _villageList;
  @visibleForTesting
  List<EducationModel> get educationList => _educationList;
  @visibleForTesting
  List<ProfessionModel> get professionList => _professionList;
  @visibleForTesting
  List<SupervisorModel> get supervisorList => _supervisorList;
  @visibleForTesting
  String? get selectedCohvType => _selectedCohvType;
  @visibleForTesting
  Future<void> handleRegister() => _handleRegister();

  // System & Hardware Values
  // final String _volunteerId = 'COHV-26-0013'; // Device-sequenced candidate ID
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
    String initialMobile = widget.mobileNumber ?? '';
    initialMobile = initialMobile.replaceAll(RegExp(r'\D'), '');
    if (initialMobile.length > 10) {
      initialMobile = initialMobile.substring(initialMobile.length - 10);
    }
    _mobileController = TextEditingController(text: initialMobile);
    _loadDepartments();
    _loadStates();
    _loadEducations();
    _loadProfessions();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
      _departmentLoadError = null;
    });

    try {
      final depts = await DemographicRepository.fetchDepartmentsFromApi();
      if (mounted) {
        setState(() {
          _isLoadingDepartments = false;
          _departmentList = depts;
          _departmentLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _departmentLoadError = 'Failed to load COHV types.';
          _isLoadingDepartments = false;
          _departmentList = [];
        });
      }
    }
  }

  Future<void> _loadInstitutions(int departmentId) async {
    final currentToken = ++_departmentRequestToken;

    setState(() {
      _isLoadingInstitutions = true;
      _institutionLoadError = null;
    });

    try {
      final institutions = await DemographicRepository.fetchInstitutionsFromApi(
        departmentId,
      );
      if (mounted &&
          currentToken == _departmentRequestToken &&
          _selectedDepartmentId == departmentId) {
        setState(() {
          _isLoadingInstitutions = false;
          _institutionList = institutions;
          _institutionLoadError = null;
        });
      }
    } catch (e) {
      if (mounted &&
          currentToken == _departmentRequestToken &&
          _selectedDepartmentId == departmentId) {
        setState(() {
          _institutionLoadError = 'Failed to load institutions.';
          _isLoadingInstitutions = false;
          _institutionList = [];
        });
      }
    }
  }

  void _onDepartmentChanged(String? val) {
    setState(() {
      _selectedCohvType = val;

      final dept = _departmentList.firstWhere(
        (d) => d.departmentName == val,
        orElse: () =>
            DepartmentModel(departmentId: 0, departmentName: val ?? ''),
      );

      _selectedDepartmentModel = dept;
      _selectedDepartmentId = dept.departmentId > 0 ? dept.departmentId : null;

      // Clear previous institution selection, custom institution text, errors
      _selectedInstitutionOption = null;
      _selectedInstitutionModel = null;
      _selectedInstitutionTypeId = null;
      _customInstitutionController.clear();
      _institutionList = [];
      _institutionLoadError = null;

      // Clear supervisor selection
      _selectedSupervisor = null;
      _selectedSupervisorModel = null;
    });

    if (_selectedDepartmentId != null && _selectedDepartmentId! > 0) {
      _loadInstitutions(_selectedDepartmentId!);
    }
    _checkAndLoadSupervisors();
  }

  void _onInstitutionChanged(String? val) {
    setState(() {
      _selectedInstitutionOption = val;
      if (val == null || val.trim().isEmpty) {
        _selectedInstitutionModel = null;
        _selectedInstitutionTypeId = null;
        _customInstitutionController.clear();
        return;
      }

      final matched = _institutionList.firstWhere(
        (i) => i.optionName == val,
        orElse: () => InstitutionModel(
          institutionTypeId: 0,
          departmentId: _selectedDepartmentId ?? 0,
          fieldLabel: _currentInstitutionFieldLabel,
          optionName: val,
          isOther: val.trim().toLowerCase() == 'other',
          sortOrder: 999,
        ),
      );

      _selectedInstitutionModel = matched;
      _selectedInstitutionTypeId = matched.institutionTypeId > 0
          ? matched.institutionTypeId
          : null;

      if (!matched.isOther) {
        _customInstitutionController.clear();
      }
    });
  }

  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
      _stateLoadError = null;
    });

    try {
      final states = await DemographicRepository.fetchStatesFromApi();
      if (mounted) {
        setState(() {
          _stateList = states;
          _isLoadingStates = false;
          _stateLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stateLoadError = 'Failed to load states.';
          _isLoadingStates = false;
          _stateList = [];
        });
      }
    }
  }

  Future<void> _loadDistricts(String stateLgdCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districtLoadError = null;
    });

    try {
      final districts = await DemographicRepository.fetchDistrictsFromApi(
        stateLgdCode,
      );
      if (mounted) {
        setState(() {
          _districtList = districts;
          _isLoadingDistricts = false;
          _districtLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _districtLoadError = 'Failed to load districts.';
          _isLoadingDistricts = false;
          _districtList = [];
        });
      }
    }
  }

  Future<void> _loadBlocks(String districtLgdCode) async {
    setState(() {
      _isLoadingBlocks = true;
      _blockLoadError = null;
    });

    try {
      final blocks = await DemographicRepository.fetchBlocksFromApi(
        districtLgdCode,
      );
      if (mounted) {
        setState(() {
          _blockList = blocks;
          _isLoadingBlocks = false;
          _blockLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _blockLoadError = 'Failed to load blocks.';
          _isLoadingBlocks = false;
          _blockList = [];
        });
      }
    }
  }

  Future<void> _loadPanchayats(String blockLgdCode) async {
    setState(() {
      _isLoadingPanchayats = true;
      _panchayatLoadError = null;
    });

    try {
      final panchayats = await DemographicRepository.fetchPanchayatsFromApi(
        blockLgdCode,
      );
      if (mounted) {
        setState(() {
          _isLoadingPanchayats = false;
          _panchayatList = panchayats;
          _panchayatLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _panchayatLoadError = 'Failed to load panchayats.';
          _isLoadingPanchayats = false;
          _panchayatList = [];
        });
      }
    }
  }

  Future<void> _loadVillages(String gramPanchayatLgdCode) async {
    setState(() {
      _isLoadingVillages = true;
      _villageLoadError = null;
    });

    try {
      final villages = await DemographicRepository.fetchVillagesFromApi(
        gramPanchayatLgdCode,
      );
      if (mounted) {
        setState(() {
          _isLoadingVillages = false;
          _villageList = villages;
          _villageLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _villageLoadError = 'Failed to load villages.';
          _isLoadingVillages = false;
          _villageList = [];
        });
      }
    }
  }

  Future<void> _loadEducations() async {
    setState(() {
      _isLoadingEducations = true;
      _educationLoadError = null;
    });

    try {
      final edus = await DemographicRepository.fetchEducationsFromApi();
      if (mounted) {
        setState(() {
          _educationList = edus;
          _isLoadingEducations = false;
          _educationLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _educationLoadError = 'Failed to load qualifications.';
          _isLoadingEducations = false;
          _educationList = [];
        });
      }
    }
  }

  Future<void> _loadProfessions() async {
    setState(() {
      _isLoadingProfessions = true;
      _professionLoadError = null;
    });

    try {
      final profs = await DemographicRepository.fetchProfessionsFromApi();
      if (mounted) {
        setState(() {
          _professionList = profs;
          _isLoadingProfessions = false;
          _professionLoadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _professionLoadError = 'Failed to load professions.';
          _isLoadingProfessions = false;
          _professionList = [];
        });
      }
    }
  }

  void _checkAndLoadSupervisors() {
    final cohvType = _selectedCohvType;
    final stateLgd = _selectedStateModel?.stateLgdCode;
    final districtLgd = _selectedDistrictModel?.districtLgdCode;

    if (cohvType != null &&
        cohvType.isNotEmpty &&
        stateLgd != null &&
        stateLgd.isNotEmpty &&
        districtLgd != null &&
        districtLgd.isNotEmpty) {
      _loadSupervisors(cohvType, stateLgd, districtLgd);
    } else {
      setState(() {
        _supervisorList = [];
        _selectedSupervisor = null;
        _selectedSupervisorModel = null;
        _supervisorLoadError = null;
      });
    }
  }

  Future<void> _loadSupervisors(
    String cohvType,
    String stateLgdCode,
    String districtLgdCode,
  ) async {
    setState(() {
      _isLoadingSupervisors = true;
      _supervisorLoadError = null;
    });

    try {
      final sups = await DemographicRepository.fetchSupervisorsFromApi(
        cohvType: cohvType,
        stateLgdCode: stateLgdCode,
        districtLgdCode: districtLgdCode,
      );
      if (mounted) {
        setState(() {
          _isLoadingSupervisors = false;
          _supervisorList = sups;
          _supervisorLoadError = null;
          if (sups.length == 1) {
            _selectedSupervisorModel = sups.first;
            _selectedSupervisor = sups.first.displayName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _supervisorLoadError = 'Failed to load supervisors.';
          _isLoadingSupervisors = false;
          _supervisorList = [];
        });
      }
    }
  }

  @override
  void dispose() {
    _otherQualificationController.dispose();
    _customInstitutionController.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // =========================================================================
  // CAMERA & GALLERY PICKER
  // =========================================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _pickedImage = File(photo.path);
          _pickedImagePath = photo.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                source == ImageSource.camera
                    ? 'Photo captured successfully.'
                    : 'Photo selected from gallery.',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to access ${source == ImageSource.camera ? "camera" : "gallery"}: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _pickedImage = null;
      _pickedImagePath = null;
    });
  }

  // =========================================================================
  // DATE PICKERS & SPEC VALIDATIONS
  // =========================================================================

  // Future<void> _pickDob() async {
  //   final now = DateTime.now();
  //   final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
  //
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _selectedDob ?? DateTime(now.year - 22, now.month, now.day),
  //     firstDate: DateTime(1940),
  //     lastDate: now,
  //     builder: (context, child) => Theme(
  //       data: Theme.of(context).copyWith(
  //         colorScheme: const ColorScheme.light(primary: AppColors.primary),
  //       ),
  //       child: child!,
  //     ),
  //   );
  //
  //   if (picked != null) {
  //     // Validate dynamic age >= 18 years
  //     if (picked.isAfter(eighteenYearsAgo)) {
  //       setState(() {
  //         _attentionErrors = ['Volunteer must be at least 18 years old.'];
  //       });
  //       return;
  //     }
  //     setState(() {
  //       _selectedDob = picked;
  //       _attentionErrors = [];
  //     });
  //   }
  // }

  // Calculate age in years
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  DateTime get _maxDobCutoff {
    final now = DateTime.now();
    final day = (now.month == 2 && now.day == 29) ? 28 : now.day;
    return DateTime(now.year - 18, now.month, day);
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final cutoff = _maxDobCutoff;
    final firstDate = DateTime(now.year - 100, 1, 1);

    DateTime initial = _selectedDob ??
        DateTime(
          2008,
          now.month,
          (now.month == 2 && now.day > 28) ? 28 : now.day,
        );
    if (initial.isAfter(cutoff)) {
      initial = cutoff;
    }
    if (initial.isBefore(firstDate)) {
      initial = firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: cutoff,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryGreen),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final age = _calculateAge(picked);
      if (age < 18) {
        setState(() {
          _attentionErrors = [
            'Volunteer must be at least 18 years old.',
          ];
        });
        return;
      }
      if (age >= 80) {
        setState(() {
          _attentionErrors = [
            'Volunteer age must be less than 80 years.',
          ];
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
          colorScheme: const ColorScheme.light(primary: _primaryGreen),
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

    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date of Birth is mandatory.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _attentionErrors = ['Date of Birth is mandatory.']);
      _scrollToTop();
      return;
    }

    final age = _calculateAge(_selectedDob!);
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer must be at least 18 years old.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(
        () => _attentionErrors = [
          'Volunteer must be at least 18 years old.',
        ],
      );
      _scrollToTop();
      return;
    }
    if (age >= 80) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer age must be less than 80 years.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(
        () => _attentionErrors = [
          'Volunteer age must be less than 80 years.',
        ],
      );
      _scrollToTop();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _attentionErrors = [
          'Please fill all mandatory fields marked with an asterisk (*).',
        ];
      });
      _scrollToTop();
      return;
    }

    final stateCode =
        int.tryParse(_selectedStateModel?.stateLgdCode ?? '') ?? 0;
    final districtCode =
        int.tryParse(_selectedDistrictModel?.districtLgdCode ?? '') ?? 0;
    final blockCode =
        int.tryParse(_selectedBlockModel?.effectiveLgdCode ?? '') ?? 0;
    final panchayatCode =
        int.tryParse(_selectedPanchayatModel?.gramPanchayatLgdCode ?? '') ??
        (_selectedPanchayatModel?.id ?? 0);
    final villageCode =
        int.tryParse(_selectedVillageModel?.villageLgdCode ?? '') ??
        (_selectedVillageModel?.id ?? 0);

    if (stateCode <= 0 ||
        districtCode <= 0 ||
        blockCode <= 0 ||
        panchayatCode <= 0 ||
        villageCode <= 0) {
      setState(
        () => _attentionErrors = [
          'Complete geographic cascading selection (State, District, Block, Gram Panchayat, and Village) is mandatory.',
        ],
      );
      _scrollToTop();
      return;
    }

    final cohvType = DemographicRepository.normalizeCohvType(
      _selectedCohvType ?? '',
    );
    if (cohvType.isEmpty) {
      setState(() => _attentionErrors = ['Please select a COHV Sector/Type.']);
      _scrollToTop();
      return;
    }

    if (_selectedInstitutionOption == null ||
        _selectedInstitutionOption!.trim().isEmpty) {
      setState(
        () => _attentionErrors = [
          'Please select a $_currentInstitutionFieldLabel.',
        ],
      );
      _scrollToTop();
      return;
    }

    final isOtherInstitution =
        _selectedInstitutionModel?.isOther == true ||
        _selectedInstitutionOption!.trim().toLowerCase() == 'other';
    if (isOtherInstitution) {
      final customName = _customInstitutionController.text.trim();
      if (customName.isEmpty) {
        setState(
          () => _attentionErrors = [
            'Please specify ${_currentInstitutionFieldLabel.toLowerCase()}.',
          ],
        );
        _scrollToTop();
        return;
      }
    }

    final int educationId = _selectedEducationModel?.educationId ?? 0;
    if (educationId <= 0) {
      setState(
        () =>
            _attentionErrors = ['Please select an Educational Qualification.'],
      );
      _scrollToTop();
      return;
    }

    final int professionId = _selectedProfessionModel?.professionId ?? 0;
    if (professionId <= 0) {
      setState(() => _attentionErrors = ['Please select a Profession.']);
      _scrollToTop();
      return;
    }

    final int? supervisorId =
        (_selectedSupervisorModel != null &&
            _selectedSupervisorModel!.supervisorId > 0)
        ? _selectedSupervisorModel!.supervisorId
        : null;

    setState(() => _isLoading = true);

    try {
      final mobile = _mobileController.text.trim();
      final finalQualificationName =
          (_selectedQualification?.trim().toLowerCase() == 'other' ||
              _selectedEducationModel?.isOther == true)
          ? _otherQualificationController.text.trim()
          : _selectedQualification;

      final isOtherInst =
          _selectedInstitutionModel?.isOther == true ||
          _selectedInstitutionOption?.trim().toLowerCase() == 'other';
      final customInstName = isOtherInst
          ? _customInstitutionController.text.trim()
          : null;

      final request = VolunteerRegistrationRequest(
        volunteerName: _nameController.text.trim(),
        gender: _selectedGender ?? 'Male',
        dateOfBirth: _selectedDob!,
        mobileNo: mobile,
        email: _emailController.text.trim(),
        cohvType: cohvType,
        stateLgdCode: stateCode,
        districtLgdCode: districtCode,
        blockLgdCode: blockCode,
        gramPanchayatLgdCode: panchayatCode,
        villageLgdCode: villageCode,
        dateOfJoining: _selectedDateOfJoining ?? DateTime.now(),
        educationId: educationId,
        professionId: professionId,
        pin: _pinController.text.trim(),
        supervisorId: supervisorId,
        latitude: _lat,
        longitude: _lng,
        gpsAccuracyM: _accuracy,
        deviceId: _deviceId,
        photoPath: _pickedImagePath,
        stateName: _selectedState,
        districtName: _selectedDistrict,
        blockName: _selectedBlock,
        panchayatName: _selectedPanchayat,
        villageName: _selectedVillage,
        // qualificationName: _selectedQualification,
        qualificationName: finalQualificationName,
        professionName: _selectedProfession,
        departmentId: _selectedDepartmentId,
        institutionTypeId: _selectedInstitutionTypeId,
        institutionName: _selectedInstitutionOption,
        customInstitutionName: customInstName,
      );

      final result = await _apiService.registerVolunteer(request);

      if (!mounted) return;

      // Navigates to Awaiting Approval Screen showing the newly assigned Volunteer Code
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AwaitingApprovalScreen(
            fullName: result.fullName.isNotEmpty
                ? result.fullName
                : _nameController.text.trim(),
            volunteerId: result.volunteerCode.isNotEmpty
                ? result.volunteerCode
                : result.volunteerId,
            supervisorStatus:
                _selectedSupervisorModel?.displayName ??
                _selectedSupervisor ??
                result.supervisorStatus,
            accountStatus: result.status == 'ACTIVE' ? 'Active' : 'Inactive',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _attentionErrors = [e.toString().replaceAll('Exception: ', '')];
      });
      _scrollToTop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _formBackground,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
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
          controller: _scrollController,
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
                    color: Colors.black.withValues(alpha: 0.03),
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
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Full name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Gender *
                    _buildLabel('Gender *'),
                    _buildDropdown(
                      fieldId: 'gender',
                      value: _selectedGender,
                      items: DemographicRepository.genders,
                      onChanged: (val) => setState(() => _selectedGender = val),
                      validator: (val) =>
                          val == null ? 'Please select gender' : null,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (val) {
                        if (val == null ||
                            !RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
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
                        if (val == null ||
                            !val.contains('@') ||
                            !val.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // COHV Type *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('COHV Type *')),
                        if (_isLoadingDepartments)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'cohv_type',
                      value: _selectedCohvType,
                      items: _departmentList
                          .map((d) => d.departmentName)
                          .toList(),
                      isLoading: _isLoadingDepartments,
                      hintText: _isLoadingDepartments
                          ? 'Loading COHV Types...'
                          : (_departmentList.isEmpty
                              ? 'No COHV types available'
                              : 'Select COHV Type'),
                      emptyMessage: 'No COHV types available',
                      onRetry: _loadDepartments,
                      onChanged: _onDepartmentChanged,
                      validator: (val) =>
                          val == null ? 'Please select COHV Type' : null,
                    ),
                    if (_departmentLoadError != null &&
                        _departmentList.isEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _departmentLoadError ?? 'Failed to load COHV types.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _loadDepartments,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // =========================================================
                    // CASCADING GEOGRAPHIC HIERARCHY (Spec Section 3)
                    // =========================================================

                    // State *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('State *')),
                        if (_isLoadingStates)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'state',
                      value: _selectedState,
                      items: _stateList.map((s) => s.stateName).toList(),
                      isLoading: _isLoadingStates,
                      hintText: _isLoadingStates
                          ? 'Loading states...'
                          : (_stateList.isEmpty
                              ? 'No states available'
                              : 'Select State'),
                      emptyMessage: 'No states available',
                      onRetry: _loadStates,
                      onChanged: (val) {
                        setState(() {
                          _selectedState = val;
                          _selectedStateModel = _stateList.firstWhere(
                            (s) => s.stateName == val,
                            orElse: () => StateModel(
                              stateName: val ?? '',
                              stateLgdCode: '',
                            ),
                          );
                          _selectedDistrict = null;
                          _selectedDistrictModel = null;
                          _districtList = [];
                          _selectedBlock = null;
                          _selectedBlockModel = null;
                          _blockList = [];
                          _selectedPanchayat = null;
                          _selectedPanchayatModel = null;
                          _panchayatList = [];
                          _selectedVillage = null;
                          _selectedVillageModel = null;
                          _villageList = [];
                          _selectedSupervisor = null;
                          _selectedSupervisorModel = null;
                          _supervisorList = [];
                        });

                        if (_selectedStateModel != null &&
                            _selectedStateModel!.stateLgdCode.isNotEmpty) {
                          _loadDistricts(_selectedStateModel!.stateLgdCode);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Please select State' : null,
                    ),
                    if (_stateLoadError != null && _stateList.isEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _stateLoadError ?? 'Failed to load states.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _loadStates,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // District *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('District *')),
                        if (_isLoadingDistricts)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'district',
                      value: _selectedDistrict,
                      items: _districtList.map((d) => d.districtName).toList(),
                      isLoading: _isLoadingDistricts,
                      hintText: _selectedState == null
                          ? 'Select State first'
                          : (_isLoadingDistricts
                                ? 'Loading districts...'
                                : (_districtList.isEmpty
                                    ? 'No districts found'
                                    : 'Select District')),
                      emptyMessage: 'No districts found',
                      onRetry:
                          (_selectedStateModel != null &&
                              _selectedStateModel!.stateLgdCode.isNotEmpty)
                          ? () => _loadDistricts(
                              _selectedStateModel!.stateLgdCode,
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedDistrict = val;
                          _selectedDistrictModel = _districtList.firstWhere(
                            (d) => d.districtName == val,
                            orElse: () => DistrictModel(
                              districtName: val ?? '',
                              districtLgdCode: '',
                            ),
                          );
                          _selectedBlock = null;
                          _selectedBlockModel = null;
                          _blockList = [];
                          _selectedPanchayat = null;
                          _selectedPanchayatModel = null;
                          _panchayatList = [];
                          _selectedVillage = null;
                          _selectedVillageModel = null;
                          _villageList = [];
                          _selectedSupervisor = null;
                          _selectedSupervisorModel = null;
                          _supervisorList = [];
                        });

                        if (_selectedDistrictModel != null &&
                            _selectedDistrictModel!
                                .districtLgdCode
                                .isNotEmpty) {
                          _loadBlocks(_selectedDistrictModel!.districtLgdCode);
                        }
                        _checkAndLoadSupervisors();
                      },
                      validator: (val) =>
                          val == null ? 'Please select District' : null,
                    ),
                    if (_districtLoadError != null &&
                        _districtList.isEmpty &&
                        _selectedState != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _districtLoadError ?? 'Failed to load districts.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          if (_selectedStateModel != null &&
                              _selectedStateModel!.stateLgdCode.isNotEmpty)
                            InkWell(
                              onTap: () => _loadDistricts(
                                _selectedStateModel!.stateLgdCode,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Block / Taluk *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('Block / Taluk *')),
                        if (_isLoadingBlocks)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'block',
                      value: _selectedBlock,
                      items: _blockList.map((b) => b.blockName).toList(),
                      isLoading: _isLoadingBlocks,
                      hintText: _selectedDistrict == null
                          ? 'Select District first'
                          : (_isLoadingBlocks
                                ? 'Loading blocks...'
                                : (_blockList.isEmpty
                                    ? 'No blocks found'
                                    : 'Select Block / Taluk')),
                      emptyMessage: 'No blocks found',
                      onRetry:
                          (_selectedDistrictModel != null &&
                              _selectedDistrictModel!
                                  .districtLgdCode
                                  .isNotEmpty)
                          ? () => _loadBlocks(
                              _selectedDistrictModel!.districtLgdCode,
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedBlock = val;
                          _selectedBlockModel = _blockList.firstWhere(
                            (b) => b.blockName.trim() == (val ?? '').trim(),
                            orElse: () => BlockModel(
                              blockName: val ?? '',
                              blockLgdCode: '',
                            ),
                          );
                          _selectedPanchayat = null;
                          _selectedPanchayatModel = null;
                          _panchayatList = [];
                          _selectedVillage = null;
                          _selectedVillageModel = null;
                          _villageList = [];
                        });

                        final codeToUse =
                            _selectedBlockModel?.effectiveLgdCode ??
                            _selectedBlockModel?.blockLgdCode ??
                            '';
                        if (codeToUse.isNotEmpty) {
                          _loadPanchayats(codeToUse);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Please select Block / Taluk' : null,
                    ),
                    if (_blockLoadError != null &&
                        _blockList.isEmpty &&
                        _selectedDistrict != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _blockLoadError ?? 'Failed to load blocks.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          if (_selectedDistrictModel != null &&
                              _selectedDistrictModel!
                                  .districtLgdCode
                                  .isNotEmpty)
                            InkWell(
                              onTap: () => _loadBlocks(
                                _selectedDistrictModel!.districtLgdCode,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Gram Panchayat / Municipality *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildLabel('Gram Panchayat / Municipality *'),
                        ),
                        if (_isLoadingPanchayats)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'panchayat',
                      value: _selectedPanchayat,
                      items: _panchayatList
                          .map((p) => p.gramPanchayatName)
                          .toList(),
                      isLoading: _isLoadingPanchayats,
                      hintText: _selectedBlock == null
                          ? 'Select Block / Taluk first'
                          : (_isLoadingPanchayats
                                ? 'Loading panchayats...'
                                : (_panchayatList.isEmpty
                                    ? 'No panchayats found'
                                    : 'Select Gram Panchayat / Municipality')),
                      emptyMessage: 'No panchayats found',
                      onRetry:
                          (_selectedBlockModel != null &&
                              (_selectedBlockModel!
                                      .effectiveLgdCode
                                      .isNotEmpty ||
                                  _selectedBlockModel!.blockLgdCode.isNotEmpty))
                          ? () => _loadPanchayats(
                              _selectedBlockModel!.effectiveLgdCode.isNotEmpty
                                  ? _selectedBlockModel!.effectiveLgdCode
                                  : _selectedBlockModel!.blockLgdCode,
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedPanchayat = val;
                          _selectedPanchayatModel = _panchayatList.firstWhere(
                            (p) =>
                                p.gramPanchayatName.trim() ==
                                (val ?? '').trim(),
                            orElse: () => PanchayatModel(
                              gramPanchayatName: val ?? '',
                              gramPanchayatLgdCode: '',
                            ),
                          );
                          _selectedVillage = null;
                          _selectedVillageModel = null;
                          _villageList = [];
                        });

                        final codeToUse =
                            _selectedPanchayatModel?.effectiveLgdCode ??
                            _selectedPanchayatModel?.gramPanchayatLgdCode ??
                            '';
                        if (codeToUse.isNotEmpty) {
                          _loadVillages(codeToUse);
                        }
                      },
                      validator: (val) => val == null
                          ? 'Please select Panchayat / Municipality'
                          : null,
                    ),
                    if (_panchayatLoadError != null &&
                        _selectedBlock != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _panchayatLoadError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          if (_selectedBlockModel != null &&
                              (_selectedBlockModel!
                                      .effectiveLgdCode
                                      .isNotEmpty ||
                                  _selectedBlockModel!.blockLgdCode.isNotEmpty))
                            InkWell(
                              onTap: () => _loadPanchayats(
                                _selectedBlockModel!.effectiveLgdCode.isNotEmpty
                                    ? _selectedBlockModel!.effectiveLgdCode
                                    : _selectedBlockModel!.blockLgdCode,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Village / Ward *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('Village / Ward *')),
                        if (_isLoadingVillages)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'village',
                      value: _selectedVillage,
                      items: _villageList.map((v) => v.villageName).toList(),
                      isLoading: _isLoadingVillages,
                      hintText: _selectedPanchayat == null
                          ? 'Select Panchayat first'
                          : (_isLoadingVillages
                                ? 'Loading villages...'
                                : (_villageList.isEmpty
                                    ? 'No villages found'
                                    : 'Select Village / Ward')),
                      emptyMessage: 'No villages found',
                      onRetry:
                          (_selectedPanchayatModel != null &&
                              (_selectedPanchayatModel!
                                      .effectiveLgdCode
                                      .isNotEmpty ||
                                  _selectedPanchayatModel!
                                      .gramPanchayatLgdCode
                                      .isNotEmpty))
                          ? () => _loadVillages(
                              _selectedPanchayatModel!
                                      .effectiveLgdCode
                                      .isNotEmpty
                                  ? _selectedPanchayatModel!.effectiveLgdCode
                                  : _selectedPanchayatModel!
                                        .gramPanchayatLgdCode,
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedVillage = val;
                          _selectedVillageModel = _villageList.firstWhere(
                            (v) => v.villageName.trim() == (val ?? '').trim(),
                            orElse: () => VillageModel(
                              villageName: val ?? '',
                              villageLgdCode: '',
                            ),
                          );
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Please select Village / Ward' : null,
                    ),
                    if (_villageLoadError != null &&
                        _selectedPanchayat != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _villageLoadError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          if (_selectedPanchayatModel != null &&
                              (_selectedPanchayatModel!
                                      .effectiveLgdCode
                                      .isNotEmpty ||
                                  _selectedPanchayatModel!
                                      .gramPanchayatLgdCode
                                      .isNotEmpty))
                            InkWell(
                              onTap: () => _loadVillages(
                                _selectedPanchayatModel!
                                        .effectiveLgdCode
                                        .isNotEmpty
                                    ? _selectedPanchayatModel!.effectiveLgdCode
                                    : _selectedPanchayatModel!
                                          .gramPanchayatLgdCode,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _buildLabel('Educational Qualification *'),
                        ),
                        if (_isLoadingEducations)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Single Educational Qualification Dropdown Call
                    _buildDropdown(
                      fieldId: 'qualification',
                      value: _selectedQualification,
                      items: _educationList.map((e) => e.educationName).toList(),
                      isLoading: _isLoadingEducations,
                      hintText: _isLoadingEducations
                          ? 'Loading qualifications...'
                          : (_educationList.isEmpty
                              ? 'No qualifications available'
                              : 'Select qualification'),
                      emptyMessage: 'No qualifications available',
                      onRetry: _loadEducations,
                      onChanged: (val) {
                        setState(() {
                          _selectedQualification = val;

                          _selectedEducationModel = _educationList.firstWhere(
                            (e) => e.educationName.trim() == (val ?? '').trim(),
                            orElse: () => EducationModel(
                              educationId: 0,
                              educationName: val ?? '',
                              isOther:
                                  (val ?? '').trim().toLowerCase() == 'other',
                            ),
                          );

                          if (val?.trim().toLowerCase() != 'other') {
                            _otherQualificationController.clear();
                          }
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Select qualification' : null,
                    ),

                    // Conditional Field when "Other" is selected
                    if (_selectedQualification?.trim().toLowerCase() ==
                            'other' ||
                        _selectedEducationModel?.isOther == true) ...[
                      const SizedBox(height: 10),

                      _buildLabel('Specify other qualification *'),

                      _buildTextFormField(
                        controller: _otherQualificationController,
                        hint: 'Enter qualification name / description',
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please specify other qualification'
                            : null,
                      ),
                    ],

                    if (_educationLoadError != null &&
                        _educationList.isEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _educationLoadError ?? 'Failed to load qualifications.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _loadEducations,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    // const SizedBox(height: 16),

                    // Profession *
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('Designation *')),
                        if (_isLoadingProfessions)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'profession',
                      value: _selectedProfession,
                      items: _professionList
                          .map((p) => p.professionName)
                          .toList(),
                      isLoading: _isLoadingProfessions,
                      hintText: _isLoadingProfessions
                          ? 'Loading professions...'
                          : (_professionList.isEmpty
                              ? 'No professions available'
                              : 'Select profession'),
                      emptyMessage: 'No professions available',
                      onRetry: _loadProfessions,
                      onChanged: (val) {
                        setState(() {
                          _selectedProfession = val;
                          _selectedProfessionModel = _professionList.firstWhere(
                            (p) =>
                                p.professionName.trim() == (val ?? '').trim(),
                            orElse: () => ProfessionModel(
                              professionId: 0,
                              professionName: val ?? '',
                            ),
                          );
                        });
                      },
                      validator: (val) =>
                          val == null ? 'Select profession' : null,
                    ),
                    if (_professionLoadError != null &&
                        _professionList.isEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _professionLoadError ?? 'Failed to load professions.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _loadProfessions,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Reporting Supervisor
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildLabel('Reporting Supervisor')),
                        if (_isLoadingSupervisors)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Fetching from server...',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    _buildDropdown(
                      fieldId: 'supervisor',
                      value: _selectedSupervisor,
                      items: _supervisorList.isNotEmpty
                          ? _supervisorList.map((s) => s.displayName).toList()
                          : [],
                      isLoading: _isLoadingSupervisors,
                      hintText:
                          (_selectedCohvType == null ||
                              _selectedDistrict == null)
                          ? 'Select COHV Type & District first'
                          : (_isLoadingSupervisors
                                ? 'Loading supervisors...'
                                : (_supervisorList.isEmpty
                                      ? 'No supervisors available'
                                      : 'Select Reporting Supervisor')),
                      emptyMessage: 'No supervisors available',
                      onRetry:
                          (_selectedCohvType != null &&
                              _selectedDistrictModel != null &&
                              _selectedStateModel != null)
                          ? () => _loadSupervisors(
                              _selectedCohvType!,
                              _selectedStateModel!.stateLgdCode,
                              _selectedDistrictModel!.districtLgdCode,
                            )
                          : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedSupervisor = val;
                          _selectedSupervisorModel = _supervisorList.firstWhere(
                            (s) =>
                                s.displayName == val || s.supervisorName == val,
                            orElse: () => SupervisorModel(
                              supervisorId: 0,
                              supervisorCode: '',
                              supervisorName: val ?? '',
                            ),
                          );
                        });
                      },
                    ),
                    if (_supervisorLoadError != null &&
                        _selectedDistrict != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _supervisorLoadError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                          if (_selectedCohvType != null &&
                              _selectedDistrictModel != null &&
                              _selectedStateModel != null)
                            InkWell(
                              onTap: () => _loadSupervisors(
                                _selectedCohvType!,
                                _selectedStateModel!.stateLgdCode,
                                _selectedDistrictModel!.districtLgdCode,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Retry',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // =========================================================
                    // DYNAMIC INSTITUTION SELECTION (API-Driven)
                    // =========================================================
                    if (_selectedCohvType != null &&
                        _selectedDepartmentId != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: _buildLabel(
                              '$_currentInstitutionFieldLabel *',
                            ),
                          ),
                          if (_isLoadingInstitutions)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Fetching from server...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _primaryGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      _buildDropdown(
                        fieldId: 'institution',
                        value: _selectedInstitutionOption,
                        items: _institutionList
                            .map((i) => i.optionName)
                            .toList(),
                        isLoading: _isLoadingInstitutions,
                        hintText: _isLoadingInstitutions
                            ? 'Loading institutions...'
                            : (_institutionList.isEmpty
                                  ? 'No institutions found'
                                  : 'Select $_currentInstitutionFieldLabel'),
                        emptyMessage: 'No institutions found',
                        onRetry: _selectedDepartmentId != null
                            ? () => _loadInstitutions(_selectedDepartmentId!)
                            : null,
                        onChanged: _onInstitutionChanged,
                        validator: (val) {
                          if (_selectedCohvType != null &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Please select $_currentInstitutionFieldLabel';
                          }
                          return null;
                        },
                      ),
                      if (_institutionLoadError != null &&
                          _institutionList.isEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _institutionLoadError ?? 'Failed to load institutions.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                            if (_selectedDepartmentId != null)
                              InkWell(
                                onTap: () =>
                                    _loadInstitutions(_selectedDepartmentId!),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Conditional Field when "Other" is selected (is_other == true)
                      if (_selectedInstitutionModel?.isOther == true ||
                          (_selectedInstitutionOption?.trim().toLowerCase() ==
                              'other')) ...[
                        _buildLabel(_customInstitutionInputLabel),
                        _buildTextFormField(
                          controller: _customInstitutionController,
                          hint: 'Enter institution name here',
                          validator: (val) {
                            if (_selectedInstitutionModel?.isOther == true ||
                                _selectedInstitutionOption
                                        ?.trim()
                                        .toLowerCase() ==
                                    'other') {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please specify ${_currentInstitutionFieldLabel.toLowerCase()}';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // PIN * (4-6 digits)
                    _buildLabel('PIN *'),
                    _buildTextFormField(
                      controller: _pinController,
                      hint: '4–6 numeric digits',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null ||
                            !RegExp(r'^\d{4,6}$').hasMatch(val.trim())) {
                          return 'PIN must be 4 to 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // // Volunteer ID (Read-only Preview)
                    // _buildLabel('Volunteer ID'),
                    // _buildReadOnlyField(_volunteerId),
                    // const SizedBox(height: 20),

                    // // Profile Photograph Section
                    // _buildSectionHeader('PROFILE PHOTOGRAPH'),
                    // const SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: _buildDashedActionButton(
                    //         icon: Icons.camera_alt_outlined,
                    //         label: 'Camera',
                    //         onTap: () {
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(content: Text('Camera capture module ready.')),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //     const SizedBox(width: 14),
                    //     Expanded(
                    //       child: _buildDashedActionButton(
                    //         icon: Icons.photo_library_outlined,
                    //         label: 'Gallery',
                    //         onTap: () {
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(content: Text('Gallery selector ready.')),
                    //           );
                    //         },
                    //       ),
                    //     ),
                    //   ],
                    // ),

                    // Profile Photograph Section
                    _buildSectionHeader('PROFILE PHOTOGRAPH'),
                    const SizedBox(height: 8),

                    if (_pickedImage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _pickedImage!,
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Photo attached',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _pickedImagePath!
                                        .split(Platform.pathSeparator)
                                        .last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () =>
                                            _pickImage(ImageSource.camera),
                                        child: const Text(
                                          'Retake',
                                          style: TextStyle(
                                            color: _primaryGreen,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      InkWell(
                                        onTap: () =>
                                            _pickImage(ImageSource.gallery),
                                        child: const Text(
                                          'Gallery',
                                          style: TextStyle(
                                            color: _primaryGreen,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      InkWell(
                                        onTap: _removeImage,
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildDashedActionButton(
                              icon: Icons.camera_alt_outlined,
                              label: 'Camera',
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildDashedActionButton(
                              icon: Icons.photo_library_outlined,
                              label: 'Gallery',
                              onTap: () => _pickImage(ImageSource.gallery),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _locationCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _locationCardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_lat, $_lng · ±$_accuracy m',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_gpsTimestamp.year}-${_gpsTimestamp.month.toString().padLeft(2, '0')}-${_gpsTimestamp.day.toString().padLeft(2, '0')} ${_gpsTimestamp.hour.toString().padLeft(2, '0')}:${_gpsTimestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Volunteer — · Device $_deviceId',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _refreshGps,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: _locationCardBorder),
                              foregroundColor: _primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              minimumSize: const Size(80, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Refresh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Back to sign in link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Back to sign in',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

  // Widget _buildLabel(String text) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 6),
  //     child: Text(
  //       text,
  //       overflow: TextOverflow.ellipsis,
  //       style: const TextStyle(
  //         fontSize: 13,
  //         fontWeight: FontWeight.w600,
  //         color: AppColors.textDark,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLabel(String text) {
    final hasAsterisk = text.contains('*');
    final cleanText = text.replaceAll('*', '').trimRight();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: cleanText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            if (hasAsterisk)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primaryGreen, // Green asterisk
                ),
              ),
          ],
        ),
        overflow: TextOverflow.ellipsis,
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

  // Widget _buildTextFormField({
  //   required TextEditingController controller,
  //   required String hint,
  //   TextInputType keyboardType = TextInputType.text,
  //   bool obscureText = false,
  //   String? Function(String?)? validator,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     keyboardType: keyboardType,
  //     obscureText: obscureText,
  //     validator: validator,
  //     style: const TextStyle(fontSize: 14, color: AppColors.textDark),
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textLight),
  //       filled: true,
  //       fillColor: Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 14,
  //         vertical: 12,
  //       ),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: AppColors.border),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: AppColors.border),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
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
          borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  // Widget _buildDropdown({
  //   required String fieldId,
  //   required String? value,
  //   required List<String> items,
  //   required void Function(String?) onChanged,
  //   String? Function(String?)? validator,
  //   bool isLoading = false,
  //   String? hintText,
  //   VoidCallback? onRetry,
  // }) {
  //   final validValue = (value != null && items.contains(value)) ? value : null;
  //   return DropdownButtonFormField<String>(
  //     key: ValueKey('dropdown_${fieldId}_${validValue ?? 'none'}'),
  //     isExpanded: true,
  //     initialValue: validValue,
  //     items: items.map((item) {
  //       return DropdownMenuItem(
  //         value: item,
  //         child: Text(
  //           item,
  //           overflow: TextOverflow.ellipsis,
  //           style: const TextStyle(fontSize: 14, color: AppColors.textDark),
  //         ),
  //       );
  //     }).toList(),
  //     onChanged: isLoading ? null : onChanged,
  //     validator: validator,
  //     icon: isLoading
  //         ? const SizedBox(
  //             width: 16,
  //             height: 16,
  //             child: CircularProgressIndicator(
  //               strokeWidth: 2,
  //               color: _primaryGreen,
  //             ),
  //           )
  //         : (items.isEmpty && onRetry != null)
  //         ? InkWell(
  //             onTap: onRetry,
  //             child: const Icon(
  //               Icons.refresh,
  //               size: 20,
  //               color: _primaryGreen,
  //             ),
  //           )
  //         : const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
  //     decoration: InputDecoration(
  //       hintText: isLoading
  //           ? (hintText ?? 'Loading...')
  //           : (hintText ?? 'Select'),
  //       hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textLight),
  //       filled: true,
  //       fillColor: Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 14,
  //         vertical: 12,
  //       ),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: AppColors.border),
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: AppColors.border),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(8),
  //         borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDropdown({
    required String fieldId,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool isLoading = false,
    String? hintText,
    String? emptyMessage,
    VoidCallback? onRetry,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : null;

    return FormField<String>(
      key: ValueKey('dropdown_${fieldId}_${validValue ?? 'none'}'),
      initialValue: validValue,
      validator: validator,
      builder: (FormFieldState<String> state) {
        return _InlineSearchableDropdown(
          fieldId: fieldId,
          value: validValue,
          items: items,
          onChanged: (selected) {
            state.didChange(selected);
            onChanged(selected);
          },
          isLoading: isLoading,
          hintText: hintText,
          emptyMessage: emptyMessage,
          onRetry: onRetry,
          errorText: state.errorText,
        );
      },
    );
  }

  Widget _buildDatePickerTile({
    required String displayValue,
    required VoidCallback onTap,
  }) {
    final hasValue = displayValue != 'dd-mm-yyyy';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasValue ? _primaryGreen : AppColors.border,
            width: hasValue ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: displayValue == 'dd-mm-yyyy'
                    ? AppColors.textLight
                    : AppColors.textDark,
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textDark,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDashedActionButton({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return OutlinedButton(
  //     onPressed: onTap,
  //     style: OutlinedButton.styleFrom(
  //       side: const BorderSide(color: AppColors.border, style: BorderStyle.solid),
  //       padding: const EdgeInsets.symmetric(vertical: 12),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //     ),
  //     child: Text(
  //       label,
  //       style: const TextStyle(
  //         fontSize: 13,
  //         fontWeight: FontWeight.w500,
  //         color: AppColors.textDark,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDashedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppColors.textDark),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _InlineSearchableDropdown extends StatefulWidget {
  final String fieldId;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final String? hintText;
  final String? emptyMessage;
  final VoidCallback? onRetry;
  final String? errorText;

  const _InlineSearchableDropdown({
    required this.fieldId,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
    this.hintText,
    this.emptyMessage,
    this.onRetry,
    this.errorText,
  });

  @override
  State<_InlineSearchableDropdown> createState() =>
      _InlineSearchableDropdownState();
}

class _InlineSearchableDropdownState extends State<_InlineSearchableDropdown> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _filteredItems = List.from(widget.items);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _InlineSearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filteredItems = List.from(widget.items);
    }
    if (widget.value != oldWidget.value) {
      if (!_focusNode.hasFocus) {
        _controller.text = widget.value ?? '';
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _filteredItems = List.from(widget.items);
      _showOverlay();
    } else {
      _removeOverlay();
      final text = _controller.text.trim();
      final exactMatch = widget.items.firstWhere(
        (i) => i.toLowerCase() == text.toLowerCase(),
        orElse: () => '',
      );
      if (exactMatch.isNotEmpty) {
        _controller.text = exactMatch;
        if (exactMatch != widget.value) {
          widget.onChanged(exactMatch);
        }
      } else {
        _controller.text = widget.value ?? '';
      }
    }
  }

  void _filterItems(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(q))
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_isOpen || !mounted || widget.isLoading) return;
    if (widget.items.isEmpty) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(String item) {
    _controller.text = item;
    widget.onChanged(item);
    _focusNode.unfocus();
    _removeOverlay();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: TapRegion(
              groupId: widget.fieldId,
              child: Material(
                elevation: 6,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _filteredItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Text(
                              widget.emptyMessage ?? 'No matching options',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: _filteredItems.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              final isSelected =
                                  item == widget.value ||
                                  item.toLowerCase() ==
                                      _controller.text.trim().toLowerCase();

                              return InkWell(
                                onTap: () => _selectItem(item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  color: isSelected
                                      ? _primaryGreen.withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? _primaryGreen
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return TapRegion(
      groupId: widget.fieldId,
      onTapOutside: (_) {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          readOnly: widget.isLoading || widget.items.isEmpty,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          onTap: () {
            if (widget.items.isEmpty || widget.isLoading) return;
            if (!_isOpen) {
              _filteredItems = List.from(widget.items);
              _showOverlay();
            }
          },
          onChanged: (val) {
            _filterItems(val);
            if (!_isOpen && widget.items.isNotEmpty) {
              _showOverlay();
            }
          },
          decoration: InputDecoration(
            hintText: widget.isLoading
                ? (widget.hintText ?? 'Loading...')
                : (widget.hintText ?? 'Select'),
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textLight,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            errorText: widget.errorText,
            suffixIcon: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _primaryGreen,
                      ),
                    ),
                  )
                : (widget.items.isEmpty && widget.onRetry != null)
                ? InkWell(
                    onTap: widget.onRetry,
                    child: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: _primaryGreen,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _isOpen ? _primaryGreen : AppColors.textMuted,
                    ),
                    onPressed: () {
                      if (widget.items.isEmpty || widget.isLoading) return;
                      if (_isOpen) {
                        _focusNode.unfocus();
                        _removeOverlay();
                      } else {
                        _filteredItems = List.from(widget.items);
                        _focusNode.requestFocus();
                        _showOverlay();
                      }
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error
                    : (_isOpen ? _primaryGreen : AppColors.border),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : _primaryGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
