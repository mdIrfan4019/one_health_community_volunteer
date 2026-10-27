// Screen for creating a New Referral
// File: lib/features/referrals/presentation/screen/new_referral_screen.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import '../../../../core/storage/volunteer_ownership_filter.dart';
import '../../../../core/widgets/authenticated_header.dart';
import '../../../../core/widgets/searchable_dropdown.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/domain/demographic_models.dart';
import '../../data/referrals_api_service.dart';
import '../../domain/referral_models.dart';

// Soft upload-card colors matching the supplied form palette.
const Color _photoUploadCardColor = Color(0xFFE2EDFF); // Soft blue
const Color _videoUploadCardColor = Color(0xFFDFF4E8); // Soft mint green
const Color _documentUploadCardColor = Color(0xFFFFF4DF); // Warm cream

class NewReferralScreen extends StatefulWidget {
  final String volunteerId;

  const NewReferralScreen({
    super.key,
    this.volunteerId = '',
  });

  @override
  State<NewReferralScreen> createState() => _NewReferralScreenState();
}

class _NewReferralScreenState extends State<NewReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReferralsApiService _apiService = ReferralsApiService();
  final ImagePicker _picker = ImagePicker();

  UserSession? _userSession;
  bool _isLoadingProfile = true;

  String _selectedStream = 'Human';
  final List<String> _streams = const ['Human', 'Animal'];

  ReferralFacility? _selectedReferralFacility;
  List<ReferralFacility> _facilities = [];
  bool _isLoadingFacilities = false;

  VillageModel? _selectedVillage;
  List<VillageModel> _villages = [];
  bool _isLoadingVillages = false;

  DateTime _eventDate = DateTime.now();
  DateTime _referralDate = DateTime.now();

  final TextEditingController _reasonController = TextEditingController();
  bool _isFollowedUp = false;

  final List<String> _photoFiles = [];
  final List<String> _videoFiles = [];
  final List<String> _documentFiles = [];
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Real GPS location parameters
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
    _loadMetadata();
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

  Future<void> _loadMetadata() async {
    setState(() {
      _isLoadingProfile = true;
      _isLoadingFacilities = true;
      _isLoadingVillages = true;
    });

    try {
      // 1. Fetch user profile from /api/auth/me (or local session)
      final profile = await _apiService.fetchUserProfile();
      if (mounted) {
        setState(() {
          _userSession = profile;
          _isLoadingProfile = false;

          // Determine referral stream from volunteer's cohv_type
          final cohv = profile.sector.toLowerCase();
          if (cohv.contains('animal') || cohv.contains('veterinary')) {
            _selectedStream = 'Animal';
          } else {
            _selectedStream = 'Human';
          }
        });
      }

      // 2. Fetch facilities based on referral stream
      await _fetchFacilitiesForStream(_selectedStream);

      // 3. Fetch villages for volunteer's Gram Panchayat
      if (profile.gramPanchayatLgdCode != null) {
        await _fetchVillages(
          profile.gramPanchayatLgdCode!,
          defaultVillageLgdCode: profile.villageLgdCode,
        );
      } else {
        if (mounted) setState(() => _isLoadingVillages = false);
      }
    } catch (e) {
      debugPrint('[NEW_REFERRAL] Error loading initial metadata: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        await _fetchFacilitiesForStream(_selectedStream);
      }
    }
  }

  Future<void> _fetchFacilitiesForStream(String stream) async {
    setState(() => _isLoadingFacilities = true);
    try {
      final facilities = await _apiService.fetchFacilities(stream);
      if (mounted) {
        setState(() {
          _facilities = facilities;
          _isLoadingFacilities = false;
          if (_selectedReferralFacility != null &&
              !_facilities.any(
                    (f) => f.facilityId == _selectedReferralFacility!.facilityId,
              )) {
            _selectedReferralFacility = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[NEW_REFERRAL] Error fetching facilities: $e');
      if (mounted) setState(() => _isLoadingFacilities = false);
    }
  }

  Future<void> _fetchVillages(
      int gramPanchayatLgdCode, {
        int? defaultVillageLgdCode,
      }) async {
    setState(() => _isLoadingVillages = true);
    try {
      final villages = await _apiService.fetchVillagesForPanchayat(
        gramPanchayatLgdCode,
      );
      if (mounted) {
        setState(() {
          _villages = villages;
          _isLoadingVillages = false;
          if (defaultVillageLgdCode != null) {
            final matched = _villages.cast<VillageModel?>().firstWhere(
                  (v) =>
              v?.id == defaultVillageLgdCode ||
                  v?.villageLgdCode == defaultVillageLgdCode.toString(),
              orElse: () => null,
            );
            if (matched != null) {
              _selectedVillage = matched;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[NEW_REFERRAL] Error fetching villages: $e');
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  void _onStreamChanged(String? newStream) {
    if (newStream == null || newStream == _selectedStream) return;
    setState(() {
      _selectedStream = newStream;
      _selectedReferralFacility = null;
    });
    _fetchFacilitiesForStream(newStream);
  }

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
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
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
                                  color: const Color(0xFF136B4F).withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cameraIcon,
                                  color: const Color(0xFF19765E),
                                  size: 22,
                                ),
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
                                  color: const Color(0xFF136B4F).withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  galleryIcon,
                                  color: const Color(0xFF136B4F),
                                  size: 22,
                                ),
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
      debugPrint('[NEW_REFERRAL] Error picking photo: $e');
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
      debugPrint('[NEW_REFERRAL] Error picking video: $e');
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
      debugPrint('[NEW_REFERRAL] Error picking document: $e');
    }
  }

  Future<void> _refreshGps() async {
    await _fetchDeviceLocation(showDialogOnError: true);
    if (mounted && (_locationData?.isAvailable ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates refreshed (High accuracy lock).'),
        ),
      );
    }
  }

  /// Submit referral via POST /api/referrals (multipart/form-data)
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

    if (_selectedReferralFacility == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a Referral type (*).'),
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

    if (_referralDate.isBefore(_eventDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral date cannot be before Event date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final effectiveVolunteerCode = (_userSession?.volunteerId.trim().isNotEmpty == true)
          ? _userSession!.volunteerId.trim()
          : (widget.volunteerId.trim().isNotEmpty
          ? widget.volunteerId.trim()
          : (await SessionManager.getVolunteerId() ?? ''));

      final volunteerIdInt = _userSession?.numericVolunteerId ??
          int.tryParse(effectiveVolunteerCode) ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerCode) ??
          (await SessionManager.getNumericVolunteerId()) ??
          0;

      final villageCodeInt = _selectedVillage!.id != 0
          ? _selectedVillage!.id
          : (int.tryParse(_selectedVillage!.villageLgdCode) ?? 90000004);

      final streamCode = _selectedStream.toUpperCase().contains('ANIMAL')
          ? 'ANIMAL'
          : 'HUMAN';

      final request = ReferralCreateRequest(
        volunteerId: volunteerIdInt,
        clientRef: 'REF-CLI-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: _deviceId,
        referralStream: streamCode,
        referralFacilityId: _selectedReferralFacility!.facilityId,
        villageLgdCode: villageCodeInt,
        eventDate: _eventDate,
        referralDate: _referralDate,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
        isFollowedUp: _isFollowedUp,
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        gpsUnavailableReason: _lat == null ? 'Location unavailable or permission denied' : null,
        capturedAt: _gpsTimestamp,
        photos: _photoFiles,
        videos: _videoFiles,
        documents: _documentFiles,
      );

      final result = await _apiService.submitReferral(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.status == 'queued_offline'
                ? 'Referral ${result.referralCode} queued offline for sync.'
                : 'Referral ${result.referralCode} recorded successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      final referralItem = ReferralItem(
        id: result.referralCode,
        facilityName: _selectedReferralFacility!.facilityName,
        stream: _selectedStream,
        referralType: _selectedReferralFacility!.facilityName,
        village: _selectedVillage!.villageName,
        eventDate: result.eventDate,
        referralDate: result.referralDate,
        reason: request.reason,
        isFollowedUp: result.isFollowedUp,
        status: result.status,
        mediaFiles: [..._photoFiles, ..._videoFiles, ..._documentFiles],
        mediaCaption: _mediaCaptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: effectiveVolunteerCode,
        numericVolunteerId: volunteerIdInt,
        deviceId: _deviceId,
      );

      // Cache referral locally scoped to active volunteer so it shows immediately in list screens
      await SessionManager.saveSubmittedReferral(
        referralItem,
        volunteerId: effectiveVolunteerCode,
        numericVolunteerId: volunteerIdInt,
      );

      if (!mounted) return;
      Navigator.pop(context, referralItem);
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
    final eventDateStr =
        '${_eventDate.day.toString().padLeft(2, '0')}-${_eventDate.month.toString().padLeft(2, '0')}-${_eventDate.year}';
    final refDateStr =
        '${_referralDate.day.toString().padLeft(2, '0')}-${_referralDate.month.toString().padLeft(2, '0')}-${_referralDate.year}';

    final effectiveVillage = _selectedVillage?.villageName ??
        _userSession?.villageName ??
        'Mannanur';
    final effectiveGramPanchayat =
        _userSession?.gramPanchayatName ?? 'Amrabad';
    final effectiveDistrict = _userSession?.districtName ?? 'Nagarkurnool';
    final effectiveState = _userSession?.stateName ?? 'Telangana';
    final effectiveVolunteerId =
        _userSession?.volunteerId ?? widget.volunteerId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'New Referral',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: effectiveVolunteerId,
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
                  // 1. Referral stream * (Searchable Dropdown)
                  _buildLabel('Referral stream *'),
                  SearchableDropdownFormField<String>(
                    key: ValueKey('stream_dropdown_$_selectedStream'),
                    fieldId: 'referral_stream',
                    items: _streams,
                    value: _selectedStream,
                    itemLabel: (s) => s,
                    hintText: 'Select',
                    isLoading: _isLoadingProfile,
                    onChanged: _onStreamChanged,
                    validator: (val) =>
                    val == null || val.isEmpty ? 'Select stream' : null,
                    primaryColor: const Color(0xFF136B4F),
                  ),
                  const SizedBox(height: 16),

                  // 2. Referral type * (Searchable Dropdown, depends on stream)
                  _buildLabel('Referral type *'),
                  SearchableDropdownFormField<ReferralFacility>(
                    key: ValueKey(
                      'facility_dropdown_${_selectedReferralFacility?.facilityId ?? 'none'}_${_facilities.length}',
                    ),
                    fieldId: 'referral_facility',
                    items: _facilities,
                    value: _selectedReferralFacility,
                    itemLabel: (f) => f.facilityName,
                    hintText: 'Select',
                    isLoading: _isLoadingFacilities,
                    onChanged: (val) =>
                        setState(() => _selectedReferralFacility = val),
                    validator: (val) =>
                    val == null ? 'Select referral type' : null,
                    primaryColor: const Color(0xFF136B4F),
                  ),
                  const SizedBox(height: 16),

                  // 3. Village / ward * (Searchable Dropdown, filtered by GP)
                  _buildLabel('Village / ward *'),
                  SearchableDropdownFormField<VillageModel>(
                    key: ValueKey(
                      'village_dropdown_${_selectedVillage?.effectiveLgdCode ?? 'none'}_${_villages.length}',
                    ),
                    fieldId: 'village_ward',
                    items: _villages,
                    value: _selectedVillage,
                    itemLabel: (v) => v.villageName,
                    hintText: 'Select',
                    isLoading: _isLoadingVillages,
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    validator: (val) =>
                    val == null ? 'Select village / ward' : null,
                    primaryColor: const Color(0xFF136B4F),
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
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textDark,
                    ),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF136B4F),
                          width: 1.5,
                        ),
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
                          activeColor: const Color(0xFF136B4F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) =>
                              setState(() => _isFollowedUp = val ?? false),
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
                          backgroundColor: _photoUploadCardColor,
                          icon: Icons.photo_camera_outlined,
                          onTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Video',
                          backgroundColor: _videoUploadCardColor,
                          icon: Icons.videocam_outlined,
                          onTap: _pickVideo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Document',
                          backgroundColor: _documentUploadCardColor,
                          icon: Icons.description_outlined,
                          onTap: _pickDocument,
                        ),
                      ),
                    ],
                  ),

                  // Attachment previews
                  _buildAttachmentsPreview(),

                  const SizedBox(height: 10),
                  const Text(
                    'Up to 5 photographs (5 MB each), 2 videos (25 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description / caption
                  _buildLabel('Description / caption'),
                  TextFormField(
                    controller: _mediaCaptionController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
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
                        borderSide: const BorderSide(
                          color: Color(0xFF136B4F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Privacy Notice
                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
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
                          '${_gpsTimestamp.year}-${_gpsTimestamp.month.toString().padLeft(2, '0')}-${_gpsTimestamp.day.toString().padLeft(2, '0')} ${_gpsTimestamp.hour.toString().padLeft(2, '0')}:${_gpsTimestamp.minute.toString().padLeft(2, '0')} · $effectiveVillage › $effectiveGramPanchayat › $effectiveDistrict › $effectiveState',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Volunteer $effectiveVolunteerId · Device $_deviceId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _refreshGps,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD1F2DD)),
                            foregroundColor: const Color(0xFF136B4F),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        foregroundColor: const Color(0xFF136B4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF136B4F),
                        ),
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
                ? _photoUploadCardColor
                : entry.key == 'Video'
                ? _videoUploadCardColor
                : _documentUploadCardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
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
                  color: Color(0xFFE11028),
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
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            ),
            Icon(icon, color: AppColors.textDark, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedButton({
    required String label,
    required Color backgroundColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: const Color(0xFF19765E),
        side: BorderSide(
          color: const Color(0xFF19765E).withValues(alpha: 0.22),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF19765E)),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF233B33),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
