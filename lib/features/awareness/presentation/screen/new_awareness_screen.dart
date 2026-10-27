// Awareness Activity Creation Screen with Dynamic Backend Dropdowns
// File: lib/features/awareness/presentation/screen/new_awareness_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/core/widgets/multi_select_dropdown.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';

class NewAwarenessScreen extends StatefulWidget {
  final String volunteerId;

  const NewAwarenessScreen({
    super.key,
    this.volunteerId = '',
  });

  @override
  State<NewAwarenessScreen> createState() => _NewAwarenessScreenState();
}

class _NewAwarenessScreenState extends State<NewAwarenessScreen> {
  final _formKey = GlobalKey<FormState>();
  final AwarenessApiService _apiService = AwarenessApiService();
  final ImagePicker _picker = ImagePicker();

  // Volunteer Session Info & Location Hierarchy
  VolunteerSessionInfo? _volunteerInfo;

  // Dropdown Data Lists
  List<AwarenessActivityTypeModel> _activityTypes = [];
  List<VillageModel> _villages = [];
  List<AwarenessTopicModel> _topics = [];
  List<DepartmentModel> _departments = [];

  // Loading Flags
  bool _isLoadingActivityTypes = true;
  bool _isLoadingVillages = true;
  bool _isLoadingTopics = true;
  bool _isLoadingDepartments = true;

  // Selected Values
  AwarenessActivityTypeModel? _selectedActivityType;
  DateTime _selectedDate = DateTime.now();
  VillageModel? _selectedVillage;
  List<AwarenessTopicModel> _selectedTopics = [];
  DepartmentModel? _selectedDepartment;

  // Text Controllers
  final TextEditingController _peopleReachedController = TextEditingController();
  final TextEditingController _otherActivityController = TextEditingController();
  final TextEditingController _otherTopicController = TextEditingController();
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Media Attachments
  final List<String> _photoFiles = [];
  final List<String> _videoFiles = [];
  final List<String> _documentFiles = [];

  // Real GPS and Device Metadata
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;
  final String _deviceId = 'DEV-C0YBZ9WK';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fetchDeviceLocation();
  }

  Future<void> _fetchDeviceLocation({bool showDialogOnError = false}) async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    final loc = await LocationService().getCurrentLocation(forceFresh: true);
    if (!mounted) return;
    setState(() {
      _locationData = loc;
      _isFetchingLocation = false;
      if (loc.isAvailable) {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _accuracy = loc.accuracyM;
        _gpsTimestamp = loc.timestamp ?? DateTime.now();
      }
    });
    if (!loc.isAvailable && showDialogOnError && mounted) {
      await LocationService().showLocationResolutionDialog(
        context,
        status: loc.status,
        onRetry: () => _fetchDeviceLocation(showDialogOnError: true),
      );
    }
  }

  @override
  void dispose() {
    _peopleReachedController.dispose();
    _otherActivityController.dispose();
    _otherTopicController.dispose();
    _mediaCaptionController.dispose();
    super.dispose();
  }

  /// Initial load: fetches volunteer profile and triggers parallel metadata fetching
  Future<void> _loadInitialData() async {
    try {
      final info = await _apiService.getVolunteerSessionInfo(
        fallbackVolunteerId: widget.volunteerId,
      );

      if (mounted) {
        setState(() {
          _volunteerInfo = info;
        });
      }

      // Fetch all dropdown metadata concurrently for maximum responsiveness
      await Future.wait([
        _fetchActivityTypes(info.sectorKey),
        _fetchVillages(
          info.gramPanchayatLgdCode,
          defaultVillageLgdCode: info.villageLgdCode,
        ),
        _fetchTopics(),
        _fetchDepartments(),
      ]);
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error initializing screen data: $e');
      if (mounted) {
        setState(() {
          _isLoadingActivityTypes = false;
          _isLoadingVillages = false;
          _isLoadingTopics = false;
          _isLoadingDepartments = false;
        });
      }
    }
  }

  /// 1. Fetch Activity Types filtered by Volunteer Sector (cohv_type)
  /// GET /api/awareness-activities/activity-types
  Future<void> _fetchActivityTypes(String sectorKey) async {
    setState(() => _isLoadingActivityTypes = true);
    try {
      final types = await _apiService.fetchActivityTypes(filterSector: sectorKey);
      if (mounted) {
        setState(() {
          _activityTypes = types;
          _isLoadingActivityTypes = false;

          // Preserve selection if valid, else reset
          if (_selectedActivityType != null &&
              !_activityTypes.any((t) =>
              t.awarenessActivityId == _selectedActivityType!.awarenessActivityId)) {
            _selectedActivityType = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error fetching activity types: $e');
      if (mounted) setState(() => _isLoadingActivityTypes = false);
    }
  }

  /// 2. Fetch Villages for the Logged-in Volunteer's Gram Panchayat
  /// GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<void> _fetchVillages(int? gpCode, {int? defaultVillageLgdCode}) async {
    if (gpCode == null) {
      if (mounted) setState(() => _isLoadingVillages = false);
      return;
    }
    setState(() => _isLoadingVillages = true);
    try {
      final villages = await _apiService.fetchVillagesForPanchayat(gpCode);
      if (mounted) {
        setState(() {
          _villages = villages;
          _isLoadingVillages = false;

          // Pre-select volunteer's home village if available and not yet set
          if (_selectedVillage == null && defaultVillageLgdCode != null) {
            final match = villages.where(
                  (v) =>
              v.id == defaultVillageLgdCode ||
                  v.effectiveLgdCode == defaultVillageLgdCode.toString(),
            );
            if (match.isNotEmpty) {
              _selectedVillage = match.first;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error fetching villages: $e');
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  /// 3. Fetch Topics
  /// GET /api/awareness-activities/topics
  Future<void> _fetchTopics() async {
    setState(() => _isLoadingTopics = true);
    try {
      final topics = await _apiService.fetchTopics();
      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoadingTopics = false;
        });
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error fetching topics: $e');
      if (mounted) setState(() => _isLoadingTopics = false);
    }
  }

  /// 4. Fetch Departments
  /// GET /api/departments
  Future<void> _fetchDepartments() async {
    setState(() => _isLoadingDepartments = true);
    try {
      final depts = await _apiService.fetchDepartments();
      if (mounted) {
        setState(() {
          _departments = depts;
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error fetching departments: $e');
      if (mounted) setState(() => _isLoadingDepartments = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<ImageSource?> _showMediaSourcePicker({
    required String title,
    required String cameraLabel,
    required String galleryLabel,
    required IconData cameraIcon,
    required IconData galleryIcon,
  }) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF136B4F).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(cameraIcon, color: const Color(0xFF136B4F), size: 22),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cameraLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF136B4F).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(galleryIcon, color: const Color(0xFF136B4F), size: 22),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                galleryLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    if (_photoFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photographs allowed.')),
      );
      return;
    }

    final source = await _showMediaSourcePicker(
      title: 'Select Photo Source',
      cameraLabel: 'Camera',
      galleryLabel: 'Gallery',
      cameraIcon: Icons.camera_alt_outlined,
      galleryIcon: Icons.photo_library_outlined,
    );

    if (source == null) return;

    try {
      XFile? photo;
      if (source == ImageSource.camera) {
        photo = await MediaPickerService().capturePhoto(context);
      } else {
        final galleryPhotos = await MediaPickerService().pickImagesFromGallery(context, allowMultiple: false);
        photo = galleryPhotos.isNotEmpty ? galleryPhotos.first : null;
      }
      if (photo != null && mounted) {
        final file = File(photo.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photograph exceeds maximum size of 5 MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }
        setState(() => _photoFiles.add(photo!.path));
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error picking photo: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_videoFiles.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 2 videos allowed.')),
      );
      return;
    }

    final source = await _showMediaSourcePicker(
      title: 'Select Video Source',
      cameraLabel: 'Record Video',
      galleryLabel: 'Gallery',
      cameraIcon: Icons.videocam_outlined,
      galleryIcon: Icons.video_library_outlined,
    );

    if (source == null) return;

    try {
      XFile? video;
      if (source == ImageSource.camera) {
        video = await MediaPickerService().recordVideo(context);
      } else {
        video = await MediaPickerService().pickVideoFromGallery(context);
      }
      if (video != null && mounted) {
        final file = File(video.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > 25 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video exceeds maximum size of 25 MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }
        setState(() => _videoFiles.add(video!.path));
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error picking video: $e');
    }
  }

  Future<void> _pickDocument() async {
    if (_documentFiles.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 documents allowed.')),
      );
      return;
    }

    try {
      final docs = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: false,
      );
      if (docs.isNotEmpty) {
        final doc = docs.first;
        final filePath = doc.path ?? '';
        if (filePath.isNotEmpty) {
          final sizeInBytes = (await doc.length()) ??
              doc.lengthSync() ??
              (File(filePath).existsSync() ? File(filePath).lengthSync() : 0);
          if (sizeInBytes > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document exceeds maximum size of 10 MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
          if (!_documentFiles.contains(filePath)) {
            setState(() => _documentFiles.add(filePath));
          }
        }
      }
    } catch (e) {
      debugPrint('[NEW_AWARENESS] Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshGps() async {
    await _fetchDeviceLocation(showDialogOnError: true);
    if (mounted && (_locationData?.isAvailable ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates refreshed (High accuracy lock).')),
      );
    }
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

    if (_selectedActivityType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Activity (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedActivityType!.isOther &&
        _otherActivityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify the activity name (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Village / ward (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final actDate =
    DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (actDate.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity date cannot be in the future.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one Topic covered (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final hasOtherTopic = _selectedTopics.any((t) => t.isOther);
    if (hasOtherTopic && _otherTopicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify the topic name (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final villageCodeInt = _selectedVillage!.id != 0
          ? _selectedVillage!.id
          : (int.tryParse(_selectedVillage!.villageLgdCode) ?? 90000004);

      final effectiveVolunteerCode =
          _volunteerInfo?.volunteerCode ?? widget.volunteerId;

      // Determine primary topic and additional/other topics
      final primaryTopic = _selectedTopics.firstWhere(
            (t) => !t.isOther,
        orElse: () => _selectedTopics.first,
      );
      final int primaryTopicId = primaryTopic.awarenessTopicId;

      String? finalTopicOther;
      final otherTopicSelected = _selectedTopics.any((t) => t.isOther);
      final customOtherText = _otherTopicController.text.trim();

      final remainingTopics = _selectedTopics
          .where((t) => t.awarenessTopicId != primaryTopicId && !t.isOther)
          .map((t) => t.awarenessTopicName)
          .toList();

      if (otherTopicSelected && customOtherText.isNotEmpty) {
        if (remainingTopics.isNotEmpty) {
          finalTopicOther = '$customOtherText; Also: ${remainingTopics.join(', ')}';
        } else {
          finalTopicOther = customOtherText;
        }
      } else if (remainingTopics.isNotEmpty) {
        finalTopicOther = 'Also: ${remainingTopics.join(', ')}';
      }

      if (finalTopicOther != null && finalTopicOther.length > 200) {
        finalTopicOther = finalTopicOther.substring(0, 200);
      }

      final fullTopicsList = _selectedTopics.map((t) {
        if (t.isOther && customOtherText.isNotEmpty) {
          return customOtherText;
        }
        return t.awarenessTopicName;
      }).join(', ');

      final request = AwarenessActivityCreateRequest(
        clientRef: 'AWR-CLI-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: _deviceId,
        awarenessActivityId: _selectedActivityType!.awarenessActivityId,
        activityDate: _selectedDate,
        villageLgdCode: villageCodeInt,
        peopleReached: int.tryParse(_peopleReachedController.text.trim()),
        awarenessTopicId: primaryTopicId,
        topicOther: finalTopicOther,
        departmentId: _selectedDepartment?.departmentId,
        departmentOther: null,
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        gpsUnavailableReason: _lat == null ? 'Location unavailable or permission denied' : null,
        photos: _photoFiles,
        videos: _videoFiles,
        documents: _documentFiles,
      );

      final result = await _apiService.submitAwarenessActivity(request);

      if (!mounted) return;

      final awarenessCode = result.awarenessCode.isNotEmpty
          ? result.awarenessCode
          : 'AWR-26-${DateTime.now().millisecondsSinceEpoch % 10000}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Awareness activity $awarenessCode submitted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );

      final effectiveNumericId = await SessionManager.getNumericVolunteerId() ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerCode);

      final newActivity = AwarenessItem(
        id: awarenessCode,
        awarenessActivityId: _selectedActivityType!.awarenessActivityId,
        activityType: _selectedActivityType!.awarenessActivityName,
        otherActivityName: _selectedActivityType?.isOther == true
            ? _otherActivityController.text.trim()
            : null,
        date: _selectedDate,
        villageLgdCode: villageCodeInt,
        village: _selectedVillage!.villageName,
        peopleReached:
        int.tryParse(_peopleReachedController.text.trim()) ?? 0,
        topicId: primaryTopicId,
        topicCovered: fullTopicsList.isNotEmpty
            ? fullTopicsList
            : 'General Awareness',
        otherTopicName: otherTopicSelected ? customOtherText : null,
        departmentId: _selectedDepartment?.departmentId,
        departmentInvolved: _selectedDepartment?.departmentName ??
            'Multi-Sectoral Joint Team',
        status: result.verificationStatus.toLowerCase(),
        mediaFiles: [..._photoFiles, ..._videoFiles, ..._documentFiles],
        mediaCaption: _mediaCaptionController.text.trim().isEmpty
            ? null
            : _mediaCaptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: effectiveVolunteerCode,
        numericVolunteerId: effectiveNumericId,
        volunteerCode: effectiveVolunteerCode,
        deviceId: _deviceId,
      );

      // Cache locally scoped to active volunteer
      await SessionManager.saveSubmittedAwarenessActivity(
        newActivity,
        volunteerId: effectiveVolunteerCode,
        numericVolunteerId: effectiveNumericId,
      );

      if (!mounted) return;
      Navigator.pop(context, newActivity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';

    final effectiveVolunteer =
        _volunteerInfo?.volunteerCode ?? widget.volunteerId;
    final effectiveVillage = _selectedVillage?.villageName ??
        _volunteerInfo?.villageName ??
        'Mannanur';
    final effectiveGramPanchayat =
        _volunteerInfo?.gramPanchayatName ?? 'Amrabad';
    final effectiveDistrict =
        _volunteerInfo?.districtName ?? 'Nagarkurnool';
    final effectiveState = _volunteerInfo?.stateName ?? 'Telangana';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'New Awareness Activity',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: effectiveVolunteer,
          onBackPressed: () => Navigator.pop(context),
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
                  // 1. Activity * (Dynamic: GET /api/awareness-activities/activity-types filtered by sector)
                  _buildLabel('Activity *'),
                  SearchableDropdownFormField<AwarenessActivityTypeModel>(
                    key: ValueKey(
                      'activity_type_${_selectedActivityType?.awarenessActivityId ?? 'none'}_${_activityTypes.length}',
                    ),
                    fieldId: 'activity_type',
                    items: _activityTypes,
                    value: _selectedActivityType,
                    itemLabel: (item) => item.awarenessActivityName,
                    hintText: 'Select',
                    isLoading: _isLoadingActivityTypes,
                    onChanged: (val) {
                      setState(() {
                        _selectedActivityType = val;
                        if (val?.isOther != true) {
                          _otherActivityController.clear();
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Select activity' : null,
                    primaryColor: const Color(0xFF136B4F),
                  ),
                  if (_selectedActivityType?.isOther == true) ...[
                    const SizedBox(height: 10),
                    _buildLabel('Specify Activity *'),
                    TextFormField(
                      controller: _otherActivityController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      decoration: _inputDecoration(hintText: 'Enter activity name'),
                      validator: (val) {
                        if (_selectedActivityType?.isOther == true &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Please specify activity';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 2. Date *
                  _buildLabel('Date *'),
                  _buildPickerTile(
                    text: dateStr,
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // 3. Village / ward * (Dynamic: GET /api/locations/villages?gram_panchayat_lgd_code=)
                  _buildLabel('Village / ward *'),
                  SearchableDropdownFormField<VillageModel>(
                    key: ValueKey(
                      'village_ward_${_selectedVillage?.effectiveLgdCode ?? 'none'}_${_villages.length}',
                    ),
                    fieldId: 'village_ward',
                    items: _villages,
                    value: _selectedVillage,
                    itemLabel: (v) => v.villageName,
                    hintText: 'Select',
                    isLoading: _isLoadingVillages,
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    validator: (val) => val == null ? 'Select village / ward' : null,
                    primaryColor: const Color(0xFF136B4F),
                  ),
                  const SizedBox(height: 16),

                  // 4. Number of people reached with the livestock extension services
                  _buildLabel('Number of people reached with the livestock extension services'),
                  TextFormField(
                    controller: _peopleReachedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: _inputDecoration(hintText: 'e.g. 45'),
                  ),
                  const SizedBox(height: 16),

                  // 5. Topic covered (Dynamic: GET /api/awareness-activities/topics - Multi-Select)
                  _buildLabel('Topic covered'),
                  MultiSelectDropdownFormField<AwarenessTopicModel>(
                    key: ValueKey(
                      'topic_covered_${_selectedTopics.map((t) => t.awarenessTopicId).join('_')}_${_topics.length}',
                    ),
                    items: _topics,
                    value: _selectedTopics,
                    itemLabel: (t) => t.awarenessTopicName,
                    hintText: 'Select topic(s)',
                    title: 'Select Topics Covered',
                    isLoading: _isLoadingTopics,
                    onChanged: (vals) {
                      setState(() {
                        _selectedTopics = vals;
                        if (!_selectedTopics.any((t) => t.isOther)) {
                          _otherTopicController.clear();
                        }
                      });
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please select at least one topic';
                      }
                      return null;
                    },
                  ),
                  if (_selectedTopics.any((t) => t.isOther)) ...[
                    const SizedBox(height: 10),
                    _buildLabel('Specify Topic *'),
                    TextFormField(
                      controller: _otherTopicController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      decoration: _inputDecoration(hintText: 'Enter topic name'),
                      validator: (val) {
                        if (_selectedTopics.any((t) => t.isOther) &&
                            (val == null || val.trim().isEmpty)) {
                          return 'Please specify topic';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 6. Departments / stakeholders involved (Dynamic: GET /api/departments)
                  _buildLabel('Departments / stakeholders involved'),
                  SearchableDropdownFormField<DepartmentModel>(
                    key: ValueKey(
                      'department_involved_${_selectedDepartment?.departmentId ?? 'none'}_${_departments.length}',
                    ),
                    fieldId: 'department_involved',
                    items: _departments,
                    value: _selectedDepartment,
                    itemLabel: (d) => d.departmentName,
                    hintText: 'Select',
                    isLoading: _isLoadingDepartments,
                    onChanged: (val) => setState(() => _selectedDepartment = val),
                    primaryColor: const Color(0xFF136B4F),
                  ),
                  const SizedBox(height: 20),

                  // PHOTO / VIDEO / DOCUMENTATION
                  _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Photograph',
                          onTap: _pickPhoto,
                          backgroundColor: const Color(0xFFE2EDFF),
                          icon: Icons.photo_camera_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Video',
                          onTap: _pickVideo,
                          backgroundColor: const Color(0xFFDFF4E8),
                          icon: Icons.videocam_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Document',
                          onTap: _pickDocument,
                          backgroundColor: const Color(0xFFFFF4DF),
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ],
                  ),

                  // Attachment previews
                  _buildAttachmentsPreview(),

                  const SizedBox(height: 10),
                  const Text(
                    'Up to 5 photographs (5 MB each), 2 videos (25 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Description / caption
                  _buildLabel('Description / caption'),
                  TextFormField(
                    controller: _mediaCaptionController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: _inputDecoration(),
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
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD1F2DD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFetchingLocation
                              ? 'Acquiring GPS fix...'
                              : (_lat != null && _lng != null
                              ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)} · ±${_accuracy ?? 0} m'
                              : (_locationData?.displayText ?? 'Location unavailable (Tap Refresh GPS)')),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: (_lat != null && _lng != null)
                                ? const Color(0xFF136B4F)
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} 16:42 · $effectiveVillage › $effectiveGramPanchayat › $effectiveDistrict › $effectiveState',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Volunteer $effectiveVolunteer · Device $_deviceId',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _refreshGps,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD1F2DD)),
                            foregroundColor: const Color(0xFF136B4F),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Refresh', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                        backgroundColor: const Color(0xFF136B4F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        foregroundColor: const Color(0xFF136B4F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF136B4F)),
                      ),
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

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
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
        borderSide: const BorderSide(color: Color(0xFF136B4F), width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text) {
    if (text.contains('*')) {
      final parts = text.split('*');
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: parts[0],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(
                text: '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF050D),
                ),
              ),
              if (parts.length > 1 && parts[1].isNotEmpty)
                TextSpan(
                  text: parts[1],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
            ],
          ),
        ),
      );
    }
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

  Widget _buildAttachmentsPreview() {
    final allFiles = [
      ..._photoFiles.map((p) => MapEntry('Photo', p)),
      ..._videoFiles.map((v) => MapEntry('Video', v)),
      ..._documentFiles.map((d) => MapEntry('Doc', d)),
    ];

    if (allFiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allFiles.map((entry) {
          final fileName = entry.value.split(Platform.pathSeparator).last;
          return Chip(
            avatar: Icon(
              entry.key == 'Photo'
                  ? Icons.photo_camera_rounded
                  : entry.key == 'Video'
                  ? Icons.videocam_rounded
                  : Icons.description_rounded,
              size: 16,
              color: const Color(0xFF136B4F),
            ),
            label: Text(
              fileName,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 16),
            onDeleted: () {
              setState(() {
                if (entry.key == 'Photo') _photoFiles.remove(entry.value);
                if (entry.key == 'Video') _videoFiles.remove(entry.value);
                if (entry.key == 'Doc') _documentFiles.remove(entry.value);
              });
            },
            backgroundColor: entry.key == 'Photo'
                ? const Color(0xFFE2EDFF)
                : entry.key == 'Video'
                ? const Color(0xFFDFF4E8)
                : const Color(0xFFFFF4DF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashedButton({
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        side: BorderSide(color: const Color(0xFF136B4F).withValues(alpha: 0.22)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: const Color(0xFF136B4F),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF136B4F)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
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
        currentIndex: 1, // 'Actions' tab
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF136B4F),
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
