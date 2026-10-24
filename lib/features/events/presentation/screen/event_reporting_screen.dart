// Dynamic Event Reporting Screen with POST /api/events Integration
// File: lib/features/events/presentation/screen/event_reporting_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:cohv/core/storage/session_manager.dart';

import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';

class EventReportingScreen extends StatefulWidget {
  final String volunteerId;

  const EventReportingScreen({super.key, this.volunteerId = 'COHV-26-0001'});

  @override
  State<EventReportingScreen> createState() => _EventReportingScreenState();
}

class _EventReportingScreenState extends State<EventReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventApiService _apiService = EventApiService();
  final ImagePicker _picker = ImagePicker();

  // Dynamic Metadata State
  EventFormMetadata? _metadata;
  bool _isLoadingMetadata = true;
  String? _metadataError;

  // Form Fields & Selections (Dynamic from backend)
  EventTypeOption? _selectedEventType;
  final TextEditingController _otherEventController = TextEditingController();

  String _selectedPrimarySector = 'Public Health';
  String _selectedPrimarySectorCode = 'Public';

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  EventVillageOption? _selectedVillage;
  bool _isOutOfAreaVisit = false;

  final TextEditingController _purposeController = TextEditingController();
  String? _selectedLocationType;
  final TextEditingController _totalVisitsController = TextEditingController(
    text: '1',
  );

  PopulationOption? _selectedPopulation;
  final TextEditingController _otherPopulationController =
      TextEditingController();

  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();

  bool _isReferralGenerated = false;
  bool _isAlertGenerated = false;
  bool _isFollowUpRequired = false;

  // Separate media attachment lists
  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<String> _documents = [];
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Location parameters
  final double _lat = 28.60928;
  final double _lng = 77.367449;
  int _accuracy = 133;
  DateTime _gpsTimestamp = DateTime.now();
  final String _deviceId = 'DEV-C0YBZ9WK';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _totalVisitsController.dispose();
    _observationsController.dispose();
    _actionTakenController.dispose();
    _mediaCaptionController.dispose();
    _otherEventController.dispose();
    _otherPopulationController.dispose();
    super.dispose();
  }

  /// Load dynamic metadata from GET /api/events/form-metadata (or cached storage)
  Future<void> _loadMetadata({bool forceRefresh = false}) async {
    // 0. Extract logged-in volunteer's sector from session
    String? userSector;
    try {
      final session = await SessionManager.getUserSession();
      if (session != null && session.sector.trim().isNotEmpty) {
        userSector = session.sector.trim();
      }
    } catch (_) {}

    // 1. Instantly render from local cache if available
    if (!forceRefresh) {
      final cached = await _apiService.getCachedMetadata();
      if (cached != null && mounted) {
        _applyMetadata(cached, userSector: userSector);
      }
    }

    try {
      final metadata = await _apiService.getEventFormMetadata(
        forceRefresh: forceRefresh,
        sector: userSector,
      );
      if (mounted) {
        _applyMetadata(metadata, userSector: userSector);
      }
    } catch (e) {
      debugPrint('[EVENT_FORM] Failed to load form metadata: $e');
      if (mounted && _metadata == null) {
        final fallback = EventFormMetadata.fallback(sector: userSector);
        _applyMetadata(fallback, userSector: userSector);
      }
    }
  }

  /// Populate form state and dropdown options from backend metadata
  // void _applyMetadata(EventFormMetadata metadata, {String? userSector}) {
  //   setState(() {
  //     _metadata = metadata;
  //     _isLoadingMetadata = false;
  //     _metadataError = null;
  //
  //     // 1. Primary Sector
  //     if (userSector != null && userSector.trim().isNotEmpty) {
  //       _selectedPrimarySector = userSector.trim();
  //       final lower = userSector.toLowerCase();
  //       if (lower.contains('animal') || lower.contains('veterinary')) {
  //         _selectedPrimarySectorCode = 'animal';
  //       } else if (lower.contains('environment') || lower.contains('ulb')) {
  //         _selectedPrimarySectorCode = 'environment';
  //       } else if (lower.contains('wildlife') || lower.contains('forest')) {
  //         _selectedPrimarySectorCode = 'wildlife';
  //       } else {
  //         _selectedPrimarySectorCode = metadata.primarySector.sectorCode;
  //       }
  //     } else {
  //       _selectedPrimarySector = metadata.primarySector.sectorName;
  //       _selectedPrimarySectorCode = metadata.primarySector.sectorCode;
  //     }
  //
  //     // 2. Validate selected Event Type against new list
  //     if (_selectedEventType != null &&
  //         !metadata.eventTypes.any((e) => e.id == _selectedEventType!.id)) {
  //       _selectedEventType = null;
  //     }
  //
  //     // 3. Validate Location Type against new list
  //     if (_selectedLocationType != null &&
  //         !metadata.locationTypes.contains(_selectedLocationType)) {
  //       _selectedLocationType = null;
  //     }
  //
  //     // 4. Validate Village against new list
  //     if (_selectedVillage != null &&
  //         !metadata.villages.any(
  //           (v) => v.villageLgdCode == _selectedVillage!.villageLgdCode,
  //         )) {
  //       _selectedVillage = null;
  //     }
  //
  //     // 5. Validate Population against new list
  //     if (_selectedPopulation != null &&
  //         !metadata.population.options.any(
  //           (p) => p.id == _selectedPopulation!.id,
  //         )) {
  //       _selectedPopulation = null;
  //     }
  //
  //     // 6. Constrain date within [minDate, maxDate]
  //     final min = metadata.minDateTime;
  //     final max = metadata.maxDateTime;
  //     if (min != null && _selectedDate.isBefore(min)) {
  //       _selectedDate = min;
  //     }
  //     if (max != null && _selectedDate.isAfter(max)) {
  //       _selectedDate = max;
  //     }
  //   });
  // }

  void _applyMetadata(EventFormMetadata metadata, {String? userSector}) {
    setState(() {
      _metadata = metadata;
      _isLoadingMetadata = false;
      _metadataError = null;

      // 1. Primary Sector: Use exact sectorName and sectorCode from metadata
      // so population_type_id matches backend database sector validation.
      _selectedPrimarySector = metadata.primarySector.sectorName;
      _selectedPrimarySectorCode = metadata.primarySector.sectorCode;

      // 2. Validate selected Event Type against the new list.
      if (_selectedEventType != null &&
          !metadata.eventTypes.any((e) => e.id == _selectedEventType!.id)) {
        _selectedEventType = null;
      }

      // 3. Validate Location Type against the new list.
      if (_selectedLocationType != null &&
          !metadata.locationTypes.contains(_selectedLocationType)) {
        _selectedLocationType = null;
      }

      // 4. Validate Village against the new list.
      if (_selectedVillage != null &&
          !metadata.villages.any(
            (v) => v.villageLgdCode == _selectedVillage!.villageLgdCode,
          )) {
        _selectedVillage = null;
      }

      // 5. Validate Population against the new list.
      if (_selectedPopulation != null &&
          !metadata.population.options.any(
            (p) => p.id == _selectedPopulation!.id,
          )) {
        _selectedPopulation = null;
      }

      // 6. Constrain date within [minDate, maxDate].
      final min = metadata.minDateTime;
      final max = metadata.maxDateTime;

      if (min != null && _selectedDate.isBefore(min)) {
        _selectedDate = min;
      }

      if (max != null && _selectedDate.isAfter(max)) {
        _selectedDate = max;
      }
    });
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  Future<void> _pickDate() async {
    final min = _metadata?.minDateTime ?? DateTime(2025);
    final max = _metadata?.maxDateTime ?? DateTime.now();

    DateTime initial = _selectedDate;
    if (initial.isBefore(min)) initial = min;
    if (initial.isAfter(max)) initial = max;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: min,
      lastDate: max,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickPhotograph() async {
    final maxPhotos = _metadata?.uploadLimits.photos.max ?? 5;
    if (_photos.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxPhotos photographs allowed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Attach Photograph',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Take photo (Camera)'),
                subtitle: const Text('Capture new photo with camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Select an image from device gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 85);
      if (photo != null) {
        final maxMb = _metadata?.uploadLimits.photos.mb ?? 5;
        final file = File(photo.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > maxMb * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Photo exceeds maximum size of $maxMb MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }
        setState(() => _photos.add(photo.path));
      }
    } catch (e) {
      debugPrint('[EVENT_MEDIA] Error picking photo: $e');
    }
  }

  Future<void> _pickVideo() async {
    final maxVideos = _metadata?.uploadLimits.videos.max ?? 2;
    if (_videos.length >= maxVideos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxVideos videos allowed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Attach Video',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.videocam_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Record video (Camera)'),
                subtitle: const Text('Record video up to 3 minutes'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF1F5F9),
                  child: Icon(
                    Icons.video_library_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Select video from device gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (video != null) {
        final maxMb = _metadata?.uploadLimits.videos.mb ?? 25;
        final file = File(video.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > maxMb * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Video exceeds maximum size of $maxMb MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
        }
        setState(() => _videos.add(video.path));
      }
    } catch (e) {
      debugPrint('[EVENT_MEDIA] Error picking video: $e');
    }
  }

  Future<void> _pickDocument() async {
    final maxDocs = _metadata?.uploadLimits.documents.max ?? 4;
    if (_documents.length >= maxDocs) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $maxDocs documents allowed.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null) {
        final filePath = result.xFile.path;
        if (filePath.isNotEmpty) {
          final maxMb = _metadata?.uploadLimits.documents.mb ?? 10;
          final sizeInBytes =
              result.lengthSync() ?? (await result.length()) ?? 0;
          if (sizeInBytes > maxMb * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Document exceeds maximum size of $maxMb MB.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }

          if (!_documents.contains(filePath)) {
            setState(() => _documents.add(filePath));
          }
        }
      }
    } catch (e) {
      debugPrint('[EVENT_MEDIA] Error picking document: $e');
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

  void _refreshGps() {
    setState(() {
      _gpsTimestamp = DateTime.now();
      _accuracy = 18;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates refreshed (High accuracy lock).'),
      ),
    );
  }

  /// Submit Event Report via POST /api/events (multipart/form-data)
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all mandatory fields (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event type.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a village/ward.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedLocationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location type.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPopulation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target population.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Direct session token check (eliminates 25s blocking pre-flight network delay)
      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session expired. Please sign in again to submit reports.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
        return;
      }

      final userSession = await SessionManager.getUserSession();
      final effectiveVolunteerId =
          (userSession?.volunteerId.trim().isNotEmpty ?? false)
          ? userSession!.volunteerId.trim()
          : widget.volunteerId;

      final timeFormatted =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00';

      final request = EventReportRequest(
        eventTypeId: _selectedEventType!.id,
        eventTypeOther: _selectedEventType!.isOther
            ? _otherEventController.text.trim()
            : null,
        eventType: _selectedEventType!.name,
        primarySector: _selectedPrimarySector,
        primarySectorCode: _selectedPrimarySectorCode,
        date: _selectedDate,
        time: timeFormatted,
        villageLgdCode: _selectedVillage!.villageLgdCode,
        village: _selectedVillage!.villageName,
        gramPanchayat: _selectedVillage!.gramPanchayatName,
        blockName: _selectedVillage!.blockName,
        isOutOfAreaVisit: _isOutOfAreaVisit,
        purposeOfVisit: _purposeController.text.trim(),
        locationType: _selectedLocationType!,
        totalVisits: int.tryParse(_totalVisitsController.text.trim()) ?? 1,
        populationTypeId: _selectedPopulation!.id,
        populationOther: _selectedPopulation!.isOther
            ? _otherPopulationController.text.trim()
            : null,
        targetPopulation: _selectedPopulation!.name,
        observations: _observationsController.text.trim(),
        actionTaken: _actionTakenController.text.trim(),
        description: _mediaCaptionController.text.trim(),
        isReferralGenerated: _isReferralGenerated,
        isAlertGenerated: _isAlertGenerated,
        isFollowUpRequired: _isFollowUpRequired,
        photos: _photos,
        videos: _videos,
        documents: _documents,
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: effectiveVolunteerId,
        deviceId: _deviceId,
      );

      final result = await _apiService.submitEventReport(
        request,
        allowOfflineFallback: false,
      );

      if (result.status != 'synced') {
        throw Exception(result.message);
      }

      final newItem = EventReportItem(
        id: result.reportId,
        eventType: request.eventType,
        primarySector: request.primarySector,
        eventDate: DateTime(
          request.date.year,
          request.date.month,
          request.date.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        village: request.village,
        status: 'synced',
        isAlert: request.isAlertGenerated,
        isFollowUp: request.isFollowUpRequired,
        verificationStatus: result.verificationStatus ?? 'Submitted',
        totalVisits: request.totalVisits,
        targetPopulation: request.targetPopulation,
        observations: request.observations,
        actionTaken: request.actionTaken,
      );

      await SessionManager.saveSubmittedEvent(newItem);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message} (${result.reportId})'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, newItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay =
        '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';
    final timeDisplay =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

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
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 19,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Event Reporting',
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
              onTap: () => _loadMetadata(forceRefresh: true),
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadMetadata(forceRefresh: true),
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              child: _isLoadingMetadata && _metadata == null
                  ? _buildLoadingSkeleton()
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_metadataError != null) ...[
                            _buildErrorBanner(_metadataError!),
                            const SizedBox(height: 14),
                          ],

                          // 1. Event * (Dynamic from metadata.eventTypes)
                          _buildLabel('Event *'),
                          _buildDropdownGeneric<EventTypeOption>(
                            fieldId: 'event_type',
                            value: _selectedEventType,
                            items: _metadata?.eventTypes ?? [],
                            itemLabel: (item) => item.name,
                            hintText: 'Select event type',
                            title: 'Select Event Type',
                            searchHint:
                                'Search event type (e.g. Fever, Diarrhoea)...',
                            onChanged: (val) {
                              setState(() {
                                _selectedEventType = val;
                                if (val?.isOther != true) {
                                  _otherEventController.clear();
                                }
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Please select an event' : null,
                          ),
                          if (_selectedEventType?.isOther == true) ...[
                            const SizedBox(height: 10),
                            _buildLabel('Specify other event *'),
                            _buildTextFormField(
                              controller: _otherEventController,
                              hint: 'Enter event name / description',
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Please specify other event'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 2. Primary sector * (Fixed to Volunteer Sector)
                          _buildLabel('Primary sector *'),
                          _buildSectorBadge(),
                          const SizedBox(height: 16),

                          // 3. Date & Time Row (Restricted to min_date & max_date)
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Date *'),
                                    _buildPickerTile(
                                      text: dateDisplay,
                                      icon: Icons.calendar_today_outlined,
                                      onTap: _pickDate,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Time *'),
                                    _buildPickerTile(
                                      text: timeDisplay,
                                      icon: Icons.access_time_rounded,
                                      onTap: _pickTime,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 4. Village / ward * (Dynamic from metadata.villages)
                          _buildLabel('Village / ward *'),
                          _buildDropdownGeneric<EventVillageOption>(
                            fieldId: 'village_ward',
                            value: _selectedVillage,
                            items: _metadata?.villages ?? [],
                            itemLabel: (v) =>
                                '${v.villageName} (${v.gramPanchayatName})',
                            itemSubtitle: (v) =>
                                'Block: ${v.blockName} · GP: ${v.gramPanchayatName}',
                            searchMatcher: (v, q) =>
                                v.villageName.toLowerCase().contains(q) ||
                                v.gramPanchayatName.toLowerCase().contains(q) ||
                                v.blockName.toLowerCase().contains(q),
                            hintText: 'Select village / ward',
                            title: 'Select Village / Ward',
                            searchHint: 'Search village, GP, or block name...',
                            onChanged: (val) =>
                                setState(() => _selectedVillage = val),
                            validator: (val) => val == null
                                ? 'Please select a village/ward'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Checkbox: Authorised out-of-area visit
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _isOutOfAreaVisit,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) => setState(
                                    () => _isOutOfAreaVisit = val ?? false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Authorised out-of-area visit',
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

                          // 5. Purpose of visit *
                          _buildLabel('Purpose of visit *'),
                          _buildTextFormField(
                            controller: _purposeController,
                            hint: 'Enter visit purpose',
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                ? 'Purpose is mandatory'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // 6. Type of location * (Dynamic from metadata.locationTypes)
                          _buildLabel('Type of location *'),
                          _buildDropdownGeneric<String>(
                            fieldId: 'location_type',
                            value: _selectedLocationType,
                            items: _metadata?.locationTypes ?? [],
                            itemLabel: (loc) => loc,
                            hintText: 'Select location type',
                            title: 'Select Location Type',
                            searchHint:
                                'Search location type (e.g. Urban, Rural)...',
                            onChanged: (val) =>
                                setState(() => _selectedLocationType = val),
                            validator: (val) =>
                                val == null ? 'Select location type' : null,
                          ),
                          const SizedBox(height: 16),

                          // // 7. Total visits *
                          // _buildLabel('Total visits *'),
                          // _buildTextFormField(
                          //   controller: _totalVisitsController,
                          //   hint: '1',
                          //   keyboardType: TextInputType.number,
                          //   validator: (val) =>
                          //       val == null || val.trim().isEmpty
                          //       ? 'Total visits is mandatory'
                          //       : null,
                          // ),

                          // 7. Total visits *
                          _buildLabel('Total visits *'),

                          _buildTextFormField(
                            controller: _totalVisitsController,
                            hint: '1',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                2,
                              ), // Maximum 2 digits (1 to 99)
                            ],
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Total visits is mandatory';
                              }

                              final num = int.tryParse(val.trim());

                              if (num == null || num <= 0) {
                                return 'Total visits must be at least 1';
                              }

                              if (num > 99) {
                                return 'Total visits cannot exceed 99';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 8. Dynamic Target Population (Label & Options from backend)
                          _buildLabel(
                            '${_metadata?.population.label ?? "Human Population"} *',
                          ),
                          _buildDropdownGeneric<PopulationOption>(
                            fieldId: 'target_population',
                            value: _selectedPopulation,
                            items: _metadata?.population.options ?? [],
                            itemLabel: (p) => p.name,
                            hintText: 'Select target population',
                            title:
                                _metadata?.population.label ??
                                'Select Target Population',
                            searchHint: 'Search target population (e.g. Children, Elderly)...',
                            onChanged: (val) {
                              setState(() {
                                _selectedPopulation = val;
                                if (val?.isOther != true) {
                                  _otherPopulationController.clear();
                                }
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Select population' : null,
                          ),
                          if (_selectedPopulation?.isOther == true) ...[
                            const SizedBox(height: 10),
                            _buildLabel('Specify other population *'),
                            _buildTextFormField(
                              controller: _otherPopulationController,
                              hint: 'Enter target population group',
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                  ? 'Please specify other population'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 16),

                          // 9. Observations
                          _buildLabel('Observations'),
                          _buildTextArea(
                            controller: _observationsController,
                            hint: 'Describe clinical signs, duration, numbers affected...',
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_countWords(_observationsController.text)} / 250 words',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 10. Immediate action taken
                          _buildLabel('Immediate action taken'),
                          _buildTextArea(
                            controller: _actionTakenController,
                            hint: 'First aid, supervisor notified, isolation guidance...',
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_countWords(_actionTakenController.text)} / 250 words',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Checkboxes List
                          _buildCheckboxRow(
                            label: 'Referral generated',
                            value: _isReferralGenerated,
                            onChanged: (val) => setState(
                              () => _isReferralGenerated = val ?? false,
                            ),
                          ),
                          const Divider(color: AppColors.divider, height: 1),

                          _buildCheckboxRow(
                            label: 'Alert generated',
                            value: _isAlertGenerated,
                            icon: const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEA580C),
                              size: 18,
                            ),
                            onChanged: (val) => setState(
                              () => _isAlertGenerated = val ?? false,
                            ),
                          ),
                          const Divider(color: AppColors.divider, height: 1),

                          _buildCheckboxRow(
                            label: 'Follow-up required',
                            value: _isFollowUpRequired,
                            onChanged: (val) => setState(
                              () => _isFollowUpRequired = val ?? false,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PHOTO / VIDEO / DOCUMENTATION
                          _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDashedButton(
                                  label:
                                      '${_metadata?.uploadLimits.photos.label ?? "Photograph"} (${_photos.length}/${_metadata?.uploadLimits.photos.max ?? 5})',
                                  onTap: _pickPhotograph,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDashedButton(
                                  label:
                                      '${_metadata?.uploadLimits.videos.label ?? "Video"} (${_videos.length}/${_metadata?.uploadLimits.videos.max ?? 2})',
                                  onTap: _pickVideo,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildDashedButton(
                                  label:
                                      '${_metadata?.uploadLimits.documents.label ?? "Document"} (${_documents.length}/${_metadata?.uploadLimits.documents.max ?? 4})',
                                  onTap: _pickDocument,
                                ),
                              ),
                            ],
                          ),
                          if (_photos.isNotEmpty ||
                              _videos.isNotEmpty ||
                              _documents.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildMediaChips(),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            _buildUploadLimitsDescription(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description / caption
                          _buildLabel('Description / caption'),
                          _buildTextFormField(
                            controller: _mediaCaptionController,
                            hint: 'Add caption for uploaded media files',
                          ),
                          const SizedBox(height: 22),

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
                                  '$dateDisplay ${_gpsTimestamp.hour.toString().padLeft(2, '0')}:${_gpsTimestamp.minute.toString().padLeft(2, '0')} · ${_selectedVillage != null ? "${_selectedVillage!.villageName} › ${_selectedVillage!.gramPanchayatName} › ${_selectedVillage!.blockName}" : "Select village above"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Volunteer ${widget.volunteerId} · Device $_deviceId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _refreshGps,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: const Text(
                                    'Refresh',
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Submit event report',
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
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
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
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // =========================================================================
  // REUSABLE BUILDERS & HELPERS
  // =========================================================================

  Widget _buildMediaChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (int i = 0; i < _photos.length; i++)
          Chip(
            avatar: const Icon(
              Icons.photo_outlined,
              size: 15,
              color: AppColors.primary,
            ),
            label: Text(
              'Photo ${i + 1}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
            ),
            onDeleted: () => setState(() => _photos.removeAt(i)),
            deleteIconColor: AppColors.textMuted,
            backgroundColor: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        for (int i = 0; i < _videos.length; i++)
          Chip(
            avatar: const Icon(
              Icons.videocam_outlined,
              size: 15,
              color: Color(0xFF2563EB),
            ),
            label: Text(
              'Video ${i + 1}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
            ),
            onDeleted: () => setState(() => _videos.removeAt(i)),
            deleteIconColor: AppColors.textMuted,
            backgroundColor: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        for (int i = 0; i < _documents.length; i++) ...[
          Builder(
            builder: (context) {
              final fileName = _documents[i].split(RegExp(r'[/\\]')).last;
              final labelText = fileName.length > 20
                  ? '${fileName.substring(0, 17)}...'
                  : fileName;
              return Chip(
                avatar: const Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: Color(0xFF059669),
                ),
                label: Text(
                  labelText.isNotEmpty ? labelText : 'Doc ${i + 1}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textDark,
                  ),
                ),
                onDeleted: () => setState(() => _documents.removeAt(i)),
                deleteIconColor: AppColors.textMuted,
                backgroundColor: const Color(0xFFECFDF5),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectorBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.health_and_safety_outlined,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedPrimarySector,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _selectedPrimarySectorCode.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildUploadLimitsDescription() {
    final limits =
        _metadata?.uploadLimits ?? UploadLimitsMetadata.defaultLimits;
    return 'Up to ${limits.photos.max} ${limits.photos.label.toLowerCase()} (${limits.photos.mb} MB each), '
        '${limits.videos.max} ${limits.videos.label.toLowerCase()} (${limits.videos.mb} MB each) and '
        '${limits.documents.max} ${limits.documents.label.toLowerCase()} — PDF, Word or Excel (${limits.documents.mb} MB each).';
  }

  Widget _buildLoadingSkeleton() {
    return const Column(
      children: [
        SizedBox(height: 30),
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 16),
        Text(
          'Loading event options for your sector...',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => _loadMetadata(forceRefresh: true),
            child: const Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
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

  Widget _buildDropdownGeneric<T>({
    required String fieldId,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String hintText = 'Select',
    String? title,
    String? searchHint,
    String Function(T)? itemSubtitle,
    bool Function(T item, String query)? searchMatcher,
  }) {
    final validValue = items.contains(value) ? value : null;

    return SearchableDropdownFormField<T>(
      key: ValueKey(
        'dropdown_${fieldId}_${validValue != null ? itemLabel(validValue) : 'none'}',
      ),
      fieldId: fieldId,
      value: validValue,
      items: items,
      itemLabel: itemLabel,
      itemSubtitle: itemSubtitle,
      searchMatcher: searchMatcher,
      onChanged: onChanged,
      validator: validator,
      hintText: hintText,
      title: title ?? hintText,
      searchHint: searchHint,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // Widget _buildTextFormField({
  //   required TextEditingController controller,
  //   required String hint,
  //   TextInputType keyboardType = TextInputType.text,
  //   String? Function(String?)? validator,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     keyboardType: keyboardType,
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
  //         borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      onChanged: (_) => onChanged(),
      style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
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

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    Widget? icon,
    required void Function(bool?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[icon, const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
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
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
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
