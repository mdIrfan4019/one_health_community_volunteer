// Dynamic Sample Support Form Screen with API Binding & Media Attachments
// File: lib/features/sample_reprot/screens/sample_support_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/features/auth/domain/demographic_models.dart';
import '../domain/sample_support_models.dart';
import '../data/sample_support_api_service.dart';

class SampleSupportFormScreen extends StatefulWidget {
  final SampleSupportApiService? apiService;
  final String? initialVolunteerId;

  const SampleSupportFormScreen({
    super.key,
    this.apiService,
    this.initialVolunteerId,
  });

  @override
  State<SampleSupportFormScreen> createState() =>
      _SampleSupportFormScreenState();
}

class _SampleSupportFormScreenState extends State<SampleSupportFormScreen> {
  static const Color primary = Color(0xFF136B4F);
  static const Color background = Color(0xFFF2F7F4);
  static const Color primary1 = Color(0xFFEF0527);
  final _formKey = GlobalKey<FormState>();
  late final SampleSupportApiService _apiService;
  final ImagePicker _picker = ImagePicker();

  final _facilitatedController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _otherSampleTypeController = TextEditingController();

  // Dynamic dropdown state
  List<SampleTypeModel> _sampleTypes = [];
  SampleTypeModel? _selectedSampleType;
  bool _isLoadingSampleTypes = false;

  List<VillageModel> _villages = [];
  VillageModel? _selectedVillage;
  bool _isLoadingVillages = false;

  DateTime _date = DateTime.now();
  bool _isSubmitting = false;

  // Media attachments
  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<String> _documents = [];

  // User session & Location state
  String _volunteerId = 'COHV-26-0001';
  String _volunteerSector = 'human';
  String _villageName = 'Achampet';
  String _panchayatName = 'Achampet';
  String _districtName = 'Nagarkurnool';
  String _stateName = 'Telangana';
  final String _deviceId = 'DEV-WZU69XEL';

  // Real GPS Location parameters
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SampleSupportApiService();
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
    _facilitatedController.dispose();
    _descriptionController.dispose();
    _otherSampleTypeController.dispose();
    super.dispose();
  }

  /// Load volunteer profile, sector, gram panchayat, sample types, and villages
  Future<void> _loadInitialData() async {
    int? gramPanchayatCode;
    int? defaultVillageCode;
    String? defaultVillageName;

    try {
      final session = await SessionManager.getUserSession();
      final profile = await SessionManager.getDetailedProfile();

      final rawVolunteerId = widget.initialVolunteerId?.trim().isNotEmpty == true
          ? widget.initialVolunteerId!
          : (session?.volunteerId.isNotEmpty == true
              ? session!.volunteerId
              : (profile?.volunteerId.isNotEmpty == true
                  ? profile!.volunteerId
                  : 'COHV-26-0001'));

      final deptOrSector = session?.sector.isNotEmpty == true
          ? session!.sector
          : (session?.departmentName?.isNotEmpty == true
              ? session!.departmentName!
              : (profile?.departmentName?.isNotEmpty == true
                  ? profile!.departmentName!
                  : (profile?.cohvType?.isNotEmpty == true
                      ? profile!.cohvType!
                      : '')));

      _volunteerSector =
          SampleSupportApiService.mapDepartmentToSector(deptOrSector);

      gramPanchayatCode =
          session?.gramPanchayatLgdCode ?? profile?.gramPanchayatLgdCode;
      defaultVillageCode = session?.villageLgdCode ?? profile?.villageLgdCode;
      defaultVillageName = session?.villageName ?? profile?.village;

      if (mounted) {
        setState(() {
          _volunteerId = rawVolunteerId;
          if (session?.villageName?.isNotEmpty == true) {
            _villageName = session!.villageName!;
          } else if (profile?.village.isNotEmpty == true) {
            _villageName = profile!.village;
          }

          if (session?.gramPanchayatName?.isNotEmpty == true) {
            _panchayatName = session!.gramPanchayatName!;
          } else if (profile?.panchayat.isNotEmpty == true) {
            _panchayatName = profile!.panchayat;
          }

          if (session?.districtName?.isNotEmpty == true) {
            _districtName = session!.districtName!;
          } else if (profile?.district.isNotEmpty == true) {
            _districtName = profile!.district;
          }

          if (session?.stateName?.isNotEmpty == true) {
            _stateName = session!.stateName!;
          } else if (profile?.state.isNotEmpty == true) {
            _stateName = profile!.state;
          }
        });
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error loading session: $e');
    }

    // Fetch dynamic sample types (filtered by volunteer's sector)
    _fetchSampleTypes();

    // Fetch dynamic villages for logged in user's Gram Panchayat
    _fetchVillages(
      gramPanchayatCode,
      defaultVillageCode: defaultVillageCode,
      defaultVillageName: defaultVillageName,
    );
  }

  /// GET /api/sample-support/types
  Future<void> _fetchSampleTypes() async {
    if (mounted) setState(() => _isLoadingSampleTypes = true);

    try {
      final types = await _apiService.fetchSampleTypes(
        sectorFilter: _volunteerSector,
      );

      if (mounted) {
        setState(() {
          _sampleTypes = types;
          _isLoadingSampleTypes = false;

          // Preserve selection if still valid in filtered list
          if (_selectedSampleType != null &&
              !_sampleTypes.any(
                (t) => t.sampleTypeId == _selectedSampleType!.sampleTypeId,
              )) {
            _selectedSampleType = null;
          }
        });
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error fetching sample types: $e');
      if (mounted) setState(() => _isLoadingSampleTypes = false);
    }
  }

  /// GET /api/locations/villages?gram_panchayat_lgd_code={code}
  Future<void> _fetchVillages(
    int? gpCode, {
    int? defaultVillageCode,
    String? defaultVillageName,
  }) async {
    if (mounted) setState(() => _isLoadingVillages = true);

    try {
      final villages = await _apiService.fetchVillagesForPanchayat(gpCode);

      if (mounted) {
        setState(() {
          _villages = villages;
          _isLoadingVillages = false;

          // Pre-select volunteer's home village if available and not yet set
          if (_selectedVillage == null && villages.isNotEmpty) {
            if (defaultVillageCode != null && defaultVillageCode > 0) {
              final match = villages.where(
                (v) =>
                    v.id == defaultVillageCode ||
                    v.effectiveLgdCode == defaultVillageCode.toString(),
              );
              if (match.isNotEmpty) {
                _selectedVillage = match.first;
              }
            }

            if (_selectedVillage == null &&
                defaultVillageName != null &&
                defaultVillageName.trim().isNotEmpty) {
              final match = villages.where(
                (v) =>
                    v.villageName.toLowerCase() ==
                    defaultVillageName.toLowerCase().trim(),
              );
              if (match.isNotEmpty) {
                _selectedVillage = match.first;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error fetching villages: $e');
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  /// Bottom sheet to choose between Camera and Gallery for photos and videos
  Future<ImageSource?> _showSourcePicker({
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF29252C),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF89838F),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, ImageSource.camera),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9E3EA)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(cameraIcon, color: primary, size: 21),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cameraLabel,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF29252C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F6F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9E3EA)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(galleryIcon, color: primary, size: 21),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              galleryLabel,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF29252C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick photograph from Camera or Gallery (up to 5 photos, 5 MB each)
  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) {
      _message('You can add up to 5 photographs.');
      return;
    }

    final source = await _showSourcePicker(
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
            _message('Photograph exceeds maximum size of 5 MB.');
            return;
          }
        }
        if (!_photos.contains(photo!.path)) {
          setState(() => _photos.add(photo!.path));
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error picking photo: $e');
    }
  }

  /// Pick video from Camera or Gallery (up to 2 videos, 25 MB each)
  Future<void> _pickVideo() async {
    if (_videos.length >= 2) {
      _message('You can add up to 2 videos.');
      return;
    }

    final source = await _showSourcePicker(
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
            _message('Video exceeds maximum size of 25 MB.');
            return;
          }
        }
        if (!_videos.contains(video!.path)) {
          setState(() => _videos.add(video!.path));
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error picking video: $e');
    }
  }

  /// Pick documents – PDF, Word, Excel (up to 4 documents, 10 MB each)
  Future<void> _pickDocuments() async {
    if (_documents.length >= 4) {
      _message('You can add up to 4 documents.');
      return;
    }

    try {
      final docs = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (docs.isNotEmpty && mounted) {
        for (final doc in docs) {
          if (_documents.length >= 4) break;
          final path = doc.path;
          if (path == null || path.isEmpty) continue;

          final sizeInBytes = (await doc.length()) ??
              doc.lengthSync() ??
              (File(path).existsSync() ? File(path).lengthSync() : 0);
          if (sizeInBytes > 10 * 1024 * 1024) {
            _message('Document exceeds maximum size of 10 MB.');
            continue;
          }

          if (!_documents.contains(path)) {
            setState(() => _documents.add(path));
          }
        }
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error picking documents: $e');
      if (mounted) _message('Could not pick documents: $e');
    }
  }

  Future<void> _refreshGps() async {
    _message('Location coordinates refreshed.');
    await _fetchDeviceLocation(showDialogOnError: WidgetsBinding.instance is WidgetsFlutterBinding);
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: AppColors.textDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatLocationTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _buildLocationString() {
    final effectiveVillage = _selectedVillage?.villageName ?? _villageName;
    final locText = _isFetchingLocation
        ? 'Acquiring GPS fix...'
        : (_lat != null && _lng != null
            ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)} · ±${_accuracy ?? 0} m'
            : (_locationData?.displayText ?? 'Location unavailable (Tap Refresh GPS)'));
    return '$locText\n'
        '${_formatLocationTimestamp(_gpsTimestamp)} · $effectiveVillage › $_panchayatName › '
        '$_districtName › $_stateName\n'
        'Volunteer $_volunteerId · Device $_deviceId';
  }

  Future<void> _save() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedSampleType == null) {
      _message('Please select sample type.');
      return;
    }

    if (_selectedVillage == null) {
      _message('Please select village / ward.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Resolve numeric volunteer ID
      int numericVolunteerId = 1;
      final storedNumId = await SessionManager.getNumericVolunteerId();
      if (storedNumId != null && storedNumId > 0) {
        numericVolunteerId = storedNumId;
      } else {
        final session = await SessionManager.getUserSession();
        if (session?.numericVolunteerId != null &&
            session!.numericVolunteerId! > 0) {
          numericVolunteerId = session.numericVolunteerId!;
        } else {
          final digits = RegExp(r'(\d+)').allMatches(_volunteerId);
          if (digits.isNotEmpty) {
            numericVolunteerId =
                int.tryParse(digits.last.group(0) ?? '') ?? 1;
          }
        }
      }

      // 2. Resolve village LGD code
      final villageLgd = _selectedVillage!.id != 0
          ? _selectedVillage!.id
          : (int.tryParse(_selectedVillage!.villageLgdCode) ??
              int.tryParse(_selectedVillage!.effectiveLgdCode) ??
              1);

      // 3. Format sample date as YYYY-MM-DD
      final sampleDate =
          '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

      // 4. Construct payload matching POST /api/sample-support OpenAPI specification
      final request = SampleSupportCreateRequest(
        volunteerId: numericVolunteerId,
        clientRef: 'SMP-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: _deviceId,
        sampleTypeId: _selectedSampleType!.sampleTypeId,
        sampleDate: sampleDate,
        sampleCount: int.tryParse(_facilitatedController.text.trim()) ?? 1,
        villageLgdCode: villageLgd,
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        gpsUnavailableReason: _lat == null ? 'Location unavailable or permission denied' : null,
        capturedAt: _gpsTimestamp.toUtc().toIso8601String(),
        photos: List<String>.from(_photos),
        videos: List<String>.from(_videos),
        documents: List<String>.from(_documents),
      );

      final response = await _apiService.submitSampleSupport(request);

      if (!mounted) return;

      if (response.success) {
        _message(response.message);

        final report = <String, dynamic>{
          'sampleType': response.sampleTypeName ?? _selectedSampleType!.sampleTypeName,
          'sampleTypeId': response.sampleTypeId ?? _selectedSampleType!.sampleTypeId,
          'sampleId': response.sampleId,
          'sampleCode': response.sampleCode,
          'id': response.sampleCode,
          'isOther': _selectedSampleType!.isOther,
          'otherSampleType': _otherSampleTypeController.text.trim(),
          'date': _date.toIso8601String(),
          'numberFacilitated': response.sampleCount ?? (int.tryParse(_facilitatedController.text) ?? 1),
          'village': response.villageName ?? _selectedVillage!.villageName,
          'villageLgdCode': response.villageLgdCode?.toString() ?? _selectedVillage!.effectiveLgdCode,
          'photos': List<String>.from(_photos),
          'videos': List<String>.from(_videos),
          'documents': List<String>.from(_documents),
          'description': _descriptionController.text.trim(),
          'location': _buildLocationString(),
        };

        debugPrint('[SAMPLE_SUPPORT_FORM] Submitted report successfully: $report');
        Navigator.pop(context, report);
      } else {
        setState(() => _isSubmitting = false);
        _message(response.message);
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_FORM] Error during submission: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _message('Failed to submit sample report: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveVillage = _selectedVillage?.villageName ?? _villageName;

    return Scaffold(
      backgroundColor: background,
      appBar: AuthenticatedAppBar(
        title: 'New Sample Support',
        onBackPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFF136B4F),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              // 1. Sample Type * (Dynamic: GET /api/sample-support/types)
              _label('Sample type', required: true),
              SearchableDropdownFormField<SampleTypeModel>(
                key: ValueKey(
                  'sample_type_${_selectedSampleType?.sampleTypeId ?? 'none'}_${_sampleTypes.length}',
                ),
                fieldId: 'sample_type',
                primaryColor: primary,
                items: _sampleTypes,
                value: _selectedSampleType,
                itemLabel: (t) => t.sampleTypeName,
                hintText: 'Select',
                isLoading: _isLoadingSampleTypes,
                onChanged: (val) {
                  setState(() => _selectedSampleType = val);
                },
                validator: (val) =>
                    val == null ? 'Please select sample type' : null,
              ),

              // If 'Other' is selected, provide specify text field
              if (_selectedSampleType?.isOther == true) ...[
                const SizedBox(height: 12),
                _label('Specify sample type', required: true),
                TextFormField(
                  controller: _otherSampleTypeController,
                  decoration: _fieldDecoration(
                    hintText: 'Enter sample type details',
                  ),
                  validator: (val) {
                    if (_selectedSampleType?.isOther == true &&
                        (val == null || val.trim().isEmpty)) {
                      return 'Please specify the sample type';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),

              // 2. Date *
              _label('Date', required: true),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: _inputDecoration(),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(_date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF29252C),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF29252C),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Number Facilitated
              _label('Number facilitated'),
              TextFormField(
                controller: _facilitatedController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration(),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Village / Ward * (Dynamic: GET /api/locations/villages)
              _label('Village / ward', required: true),
              SearchableDropdownFormField<VillageModel>(
                key: ValueKey(
                  'village_ward_${_selectedVillage?.effectiveLgdCode ?? 'none'}_${_villages.length}',
                ),
                fieldId: 'village_ward',
                primaryColor: primary,
                items: _villages,
                value: _selectedVillage,
                itemLabel: (v) => v.villageName,
                hintText: 'Select',
                isLoading: _isLoadingVillages,
                onChanged: (val) => setState(() => _selectedVillage = val),
                validator: (val) =>
                    val == null ? 'Please select village / ward' : null,
              ),
              const SizedBox(height: 22),

              // 5. PHOTO / VIDEO / DOCUMENTATION
              const Text(
                'PHOTO / VIDEO / DOCUMENTATION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.7,
                  color: Color(0xFF89838F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _uploadButton('Photograph', onTap: _pickPhotos),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _uploadButton('Video', onTap: _pickVideo),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _uploadButton('Document', onTap: _pickDocuments),
                  ),
                ],
              ),

              // Attachments Preview Chips
              _buildAttachmentsPreview(),

              const SizedBox(height: 12),
              const Text(
                'Up to 5 photographs (5 MB each), 2 videos (25 MB each) and 4 documents – PDF, Word or Excel (10 MB each).',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Color(0xFF89838F),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Description / Caption
              _label('Description / caption'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 12),

              const Text(
                'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Color(0xFF89838F),
                ),
              ),
              const SizedBox(height: 22),

              // 7. LOCATION
              const Text(
                'LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.7,
                  color: Color(0xFF89838F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  border: Border.all(color: const Color(0xFFD1F2DD)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buildLocationString(),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.6,
                        color: (_lat != null && _lng != null)
                            ? const Color(0xFF136B4F)
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _refreshGps,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primary,
                        side: const BorderSide(color: Color(0xFFD1F2DD)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 8. Actions: Save & Cancel
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsPreview() {
    final items = [
      ..._photos.map((p) => MapEntry('Photo', p)),
      ..._videos.map((v) => MapEntry('Video', v)),
      ..._documents.map((d) => MapEntry('Document', d)),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((entry) {
          final fileName = entry.value.split(Platform.pathSeparator).last;
          return Chip(
            avatar: Icon(
              entry.key == 'Photo'
                  ? Icons.photo_camera_rounded
                  : entry.key == 'Video'
                      ? Icons.videocam_rounded
                      : Icons.description_rounded,
              size: 15,
              color: primary,
            ),
            label: Text(
              fileName,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () {
              setState(() {
                if (entry.key == 'Photo') _photos.remove(entry.value);
                if (entry.key == 'Video') _videos.remove(entry.value);
                if (entry.key == 'Document') _documents.remove(entry.value);
              });
            },
            backgroundColor: const Color(0xFFF1F5F9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF29252C),
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: primary1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _uploadButton(String title, {required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF39333E),
        side: const BorderSide(color: Color(0xFFE9E3EA)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF29252C),
        ),
      ),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFE9E3EA)),
    );
  }

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF89838F)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE9E3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE9E3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: primary),
      ),
    );
  }
}
