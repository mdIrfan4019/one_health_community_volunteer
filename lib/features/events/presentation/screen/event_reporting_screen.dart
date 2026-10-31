// Dynamic Event Reporting Screen with POST /api/events Integration
// File: lib/features/events/presentation/screen/event_reporting_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:cohv/core/models/attachment_item.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/storage/session_manager.dart';

import 'package:cohv/core/storage/volunteer_ownership_filter.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';
import 'package:cohv/features/profile/data/profile_api_service.dart';
import 'package:cohv/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';

class EventReportingScreen extends StatefulWidget {
  final String volunteerId;
  final EventReportItem? editEvent;

  const EventReportingScreen({
    super.key,
    this.volunteerId = '',
    this.editEvent,
  });

  bool get isEditMode => editEvent != null;

  @override
  State<EventReportingScreen> createState() => _EventReportingScreenState();
}

class _EventReportingScreenState extends State<EventReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventApiService _apiService = EventApiService();

  // Dynamic Metadata State
  EventFormMetadata? _metadata;
  bool _isLoadingMetadata = true;
  String? _metadataError;

  // Form Fields & Selections (Dynamic from backend)
  EventTypeOption? _selectedEventType;
  final TextEditingController _otherEventController = TextEditingController();

  String _selectedPrimarySector = '';
  String _selectedPrimarySectorCode = '';

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
  String? _userSector;

  /// Returns true if the active volunteer is logged in from Animal Husbandry Department (Animal Health).
  bool get _isAnimalHusbandryVolunteer {
    final code = _selectedPrimarySectorCode.toLowerCase().trim();
    if (code == 'animal') return true;
    final name = _selectedPrimarySector.toLowerCase().trim();
    if (name.contains('animal') ||
        name.contains('veterinary') ||
        name.contains('husbandry')) {
      return true;
    }
    final userSec = _userSector?.toLowerCase().trim() ?? '';
    if (userSec.contains('animal') ||
        userSec.contains('veterinary') ||
        userSec.contains('husbandry')) {
      return true;
    }
    return false;
  }

  // Population Subcategory State
  PopulationSubcategoryOption? _selectedSubcategory;
  final TextEditingController _otherSubcategoryController =
      TextEditingController();
  List<PopulationSubcategoryOption> _subcategories = [];
  bool _isLoadingSubcategories = false;
  String? _subcategoriesError;
  int _subcategoriesRequestId = 0;
  final Map<int, List<PopulationSubcategoryOption>> _subcategoriesCache = {};

  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();

  bool _isReferralGenerated = false;
  bool _isAlertGenerated = false;
  bool _isFollowUpRequired = false;

  // Separate media attachment lists
  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<String> _documents = [];
  final List<int> _removedAttachmentIds = [];

  void _trackRemovedAttachment(String path) {
    if (widget.editEvent == null) return;
    for (final att in widget.editEvent!.attachments) {
      if (att.attachmentId > 0) {
        if (AppAttachmentItem.isSameMedia(path, att.storagePath) ||
            (att.fileUrl != null && AppAttachmentItem.isSameMedia(path, att.fileUrl!)) ||
            path == att.storagePath ||
            path == att.fileUrl ||
            (att.storagePath.isNotEmpty && path.endsWith(att.storagePath)) ||
            (att.fileName.isNotEmpty && path.endsWith(att.fileName))) {
          if (!_removedAttachmentIds.contains(att.attachmentId)) {
            _removedAttachmentIds.add(att.attachmentId);
          }
          break;
        }
      }
    }
  }
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Real GPS Location parameters
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;
  String _deviceId = 'DEV-COHV-ANDROID';

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editEvent != null) {
      final ev = widget.editEvent!;
      _selectedDate = ev.eventDate;
      _selectedTime = TimeOfDay(
        hour: ev.eventDate.hour,
        minute: ev.eventDate.minute,
      );
      _purposeController.text = ev.purposeOfVisit ?? '';
      _totalVisitsController.text = ev.totalVisits.toString();
      _observationsController.text = ev.observations ?? '';
      _actionTakenController.text = ev.actionTaken ?? '';
      _mediaCaptionController.text = ev.description ?? '';
      _isReferralGenerated = ev.referralGenerated;
      _isAlertGenerated = ev.isAlert;
      _isFollowUpRequired = ev.isFollowUp;

      if (ev.attachments.isNotEmpty) {
        for (final att in ev.attachments) {
          final path = att.storagePath.isNotEmpty
              ? att.storagePath
              : (att.fileUrl ?? '');
          if (path.isNotEmpty) {
            if (att.isImage) {
              if (!AppAttachmentItem.containsMedia(_photos, path)) {
                _photos.add(path);
              }
            } else if (att.isVideo) {
              if (!AppAttachmentItem.containsMedia(_videos, path)) {
                _videos.add(path);
              }
            } else if (att.isDocument) {
              if (!AppAttachmentItem.containsMedia(_documents, path)) {
                _documents.add(path);
              }
            }
          }
        }
      } else {
        // Fallback: only when attachments array is empty
        for (final p in ev.mediaFiles) {
          if (p.trim().isNotEmpty) {
            final dummy = AppAttachmentItem.fromPath(p);
            if (dummy.isImage) {
              if (!AppAttachmentItem.containsMedia(_photos, p)) {
                _photos.add(p);
              }
            } else if (dummy.isVideo) {
              if (!AppAttachmentItem.containsMedia(_videos, p)) {
                _videos.add(p);
              }
            } else if (dummy.isDocument) {
              if (!AppAttachmentItem.containsMedia(_documents, p)) {
                _documents.add(p);
              }
            }
          }
        }
      }
      if (ev.latitude != null && ev.longitude != null) {
        _lat = ev.latitude;
        _lng = ev.longitude;
        _accuracy = ev.gpsAccuracyM;
      }
    }
    _initDeviceId();
    _loadMetadata();
    _fetchDeviceLocation();
  }

  Future<void> _initDeviceId() async {
    final id = await SessionManager.getOrCreateDeviceId();
    if (mounted) setState(() => _deviceId = id);
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

  Future<ImageSource?> _showMediaSourcePicker({
    required String title,
    required String cameraLabel,
    required String galleryLabel,
    required IconData cameraIcon,
    required IconData galleryIcon,
  }) {
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
                // Header row with title and close button
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

                // Side-by-side camera and gallery cards
                Row(
                  children: [
                    // Camera / Record Video Card
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
                                  color: const Color(0xFF136B4F)
                                      .withValues(alpha: 0.1),
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

                    // Gallery Card
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
                                  color: const Color(0xFF136B4F)
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  galleryIcon,
                                  color: const Color(0xFF19765E),
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
              ],
            ),
          ),
        );
      },
    );
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
    _otherSubcategoryController.dispose();
    super.dispose();
  }

  /// Load dynamic metadata from GET /api/events/form-metadata (or cached storage)
  Future<void> _loadMetadata({bool forceRefresh = false}) async {
    // 0. Extract logged-in volunteer's sector from session or detailed profile
    String? userSector;
    try {
      final session = await SessionManager.getUserSession();
      if (session != null && session.sector.trim().isNotEmpty) {
        userSector = session.sector.trim();
      } else if (session?.departmentName != null &&
          session!.departmentName!.trim().isNotEmpty) {
        userSector = session!.departmentName!.trim();
      }
      if (userSector == null || userSector.isEmpty) {
        final detailed = await SessionManager.getDetailedProfile();
        userSector = detailed?.departmentName ?? detailed?.cohvType;
      }
      if (userSector == null || userSector.isEmpty) {
        try {
          final p = await ProfileApiService().getDetailedProfile();
          userSector = p.departmentName ?? p.cohvType;
        } catch (_) {}
      }
    } catch (_) {}

    _userSector = userSector;

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
  void _applyMetadata(EventFormMetadata metadata, {String? userSector}) {
    if (userSector != null && userSector.trim().isNotEmpty) {
      _userSector = userSector.trim();
    }
    final effectiveSector = (userSector != null && userSector.trim().isNotEmpty)
        ? userSector.trim()
        : _selectedPrimarySector;
    final lower = effectiveSector.toLowerCase();
    final bool isUserAnimal =
        lower.contains('animal') || lower.contains('veterinary');
    final bool isUserWildlife =
        lower.contains('wildlife') || lower.contains('forest');
    final bool isUserEnvironment =
        lower.contains('environment') || lower.contains('ulb');

    // If metadata returned a primarySector matching human, but volunteer belongs to animal/wildlife/environment:
    final bool metadataMatchesUser =
        (isUserAnimal &&
            metadata.primarySector.sectorCode.toLowerCase() == 'animal') ||
        (isUserWildlife &&
            metadata.primarySector.sectorCode.toLowerCase() == 'wildlife') ||
        (isUserEnvironment &&
            metadata.primarySector.sectorCode.toLowerCase() == 'environment') ||
        (!isUserAnimal &&
            !isUserWildlife &&
            !isUserEnvironment &&
            metadata.primarySector.sectorCode.toLowerCase() == 'human');

    final effectiveMetadata =
        (!metadataMatchesUser &&
            (isUserAnimal || isUserWildlife || isUserEnvironment))
        ? EventFormMetadata.fallback(sector: effectiveSector)
        : metadata;

    setState(() {
      _metadata = effectiveMetadata;
      _isLoadingMetadata = false;
      _metadataError = null;

      // 1. Primary Sector: Match volunteer identity
      _selectedPrimarySector = effectiveMetadata.primarySector.sectorName;
      _selectedPrimarySectorCode = effectiveMetadata.primarySector.sectorCode;

      // 2. Validate / pre-select selected Event Type
      if (widget.editEvent != null) {
        final evMatches = effectiveMetadata.eventTypes.where(
          (e) =>
              e.name.toLowerCase() == widget.editEvent!.eventType.toLowerCase(),
        );
        if (evMatches.isNotEmpty) {
          _selectedEventType = evMatches.first;
        }
      } else if (_selectedEventType != null &&
          !effectiveMetadata.eventTypes.any(
            (e) => e.id == _selectedEventType!.id,
          )) {
        _selectedEventType = null;
      }

      // 3. Validate / pre-select Location Type
      if (widget.editEvent != null && widget.editEvent!.locationType != null) {
        final locMatches = effectiveMetadata.locationTypes.where(
          (l) =>
              l.toLowerCase() == widget.editEvent!.locationType!.toLowerCase(),
        );
        if (locMatches.isNotEmpty) {
          _selectedLocationType = locMatches.first;
        }
      } else if (_selectedLocationType != null &&
          !effectiveMetadata.locationTypes.contains(_selectedLocationType)) {
        _selectedLocationType = null;
      }

      // 4. Validate / pre-select Village
      if (widget.editEvent != null) {
        final vilMatches = effectiveMetadata.villages.where(
          (v) =>
              v.villageName.toLowerCase() ==
              widget.editEvent!.village.toLowerCase(),
        );
        if (vilMatches.isNotEmpty) {
          _selectedVillage = vilMatches.first;
        }
      } else if (_selectedVillage != null &&
          !effectiveMetadata.villages.any(
            (v) => v.villageLgdCode == _selectedVillage!.villageLgdCode,
          )) {
        _selectedVillage = null;
      }

      // 5. Validate / pre-select Population
      if (widget.editEvent != null &&
          widget.editEvent!.targetPopulation != null) {
        final popMatches = effectiveMetadata.population.options.where(
          (p) =>
              p.name.toLowerCase() ==
              widget.editEvent!.targetPopulation!.toLowerCase(),
        );
        if (popMatches.isNotEmpty) {
          _selectedPopulation = popMatches.first;
          if (_isAnimalHusbandryVolunteer) {
            _fetchPopulationSubcategories(_selectedPopulation!.id);
          }
        }
      } else if (_selectedPopulation != null &&
          !effectiveMetadata.population.options.any(
            (p) => p.id == _selectedPopulation!.id,
          )) {
        _selectedPopulation = null;
        _selectedSubcategory = null;
        _otherSubcategoryController.clear();
        _subcategories = [];
        _subcategoriesError = null;
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

  /// Fetch population subcategories for the selected population.
  Future<void> _fetchPopulationSubcategories(
    int populationId, {
    bool forceRefresh = false,
  }) async {
    if (!_isAnimalHusbandryVolunteer) return;
    final requestId = ++_subcategoriesRequestId;

    // Check memory cache first
    if (!forceRefresh && _subcategoriesCache.containsKey(populationId)) {
      final cachedList = _subcategoriesCache[populationId]!;
      if (mounted &&
          _subcategoriesRequestId == requestId &&
          _selectedPopulation?.id == populationId) {
        setState(() {
          _subcategories = cachedList;
          _isLoadingSubcategories = false;
          _subcategoriesError = null;
          if (_selectedSubcategory != null &&
              !_subcategories.any((s) => s.id == _selectedSubcategory!.id)) {
            _selectedSubcategory = null;
            _otherSubcategoryController.clear();
          }
        });
      }
      return;
    }

    setState(() {
      _isLoadingSubcategories = true;
      _subcategoriesError = null;
    });

    try {
      final list = await _apiService.fetchPopulationSubcategories(populationId);
      _subcategoriesCache[populationId] = list;

      if (!mounted) return;
      if (_subcategoriesRequestId != requestId ||
          _selectedPopulation?.id != populationId) {
        return; // Stale request, ignore response
      }

      setState(() {
        _subcategories = list;
        _isLoadingSubcategories = false;
        _subcategoriesError = null;
        if (_selectedSubcategory != null &&
            !_subcategories.any((s) => s.id == _selectedSubcategory!.id)) {
          _selectedSubcategory = null;
          _otherSubcategoryController.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (_subcategoriesRequestId != requestId ||
          _selectedPopulation?.id != populationId) {
        return;
      }

      setState(() {
        _isLoadingSubcategories = false;
        _subcategoriesError = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
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
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
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

    // final source = await showModalBottomSheet<ImageSource>(
    //   context: context,
    //   backgroundColor: Colors.white,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //   ),
    //   builder: (ctx) => SafeArea(
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(vertical: 12),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Container(
    //             width: 40,
    //             height: 4,
    //             margin: const EdgeInsets.only(bottom: 12),
    //             decoration: BoxDecoration(
    //               color: Colors.grey.shade300,
    //               borderRadius: BorderRadius.circular(2),
    //             ),
    //           ),
    //           const Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    //             child: Align(
    //               alignment: Alignment.centerLeft,
    //               child: Text(
    //                 'Attach Photograph',
    //                 style: TextStyle(
    //                   fontSize: 16,
    //                   fontWeight: FontWeight.w700,
    //                   color: AppColors.textDark,
    //                 ),
    //               ),
    //             ),
    //           ),
    //           ListTile(
    //             leading: const CircleAvatar(
    //               backgroundColor: Color(0xFFEFF6FF),
    //               child: Icon(
    //                 Icons.camera_alt_outlined,
    //                 color: AppColors.primary,
    //               ),
    //             ),
    //             title: const Text('Take photo (Camera)'),
    //             subtitle: const Text('Capture new photo with camera'),
    //             onTap: () => Navigator.pop(ctx, ImageSource.camera),
    //           ),
    //           ListTile(
    //             leading: const CircleAvatar(
    //               backgroundColor: Color(0xFFF1F5F9),
    //               child: Icon(
    //                 Icons.photo_library_outlined,
    //                 color: Color(0xFF2563EB),
    //               ),
    //             ),
    //             title: const Text('Choose from gallery'),
    //             subtitle: const Text('Select an image from device gallery'),
    //             onTap: () => Navigator.pop(ctx, ImageSource.gallery),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );

    // 1. Photo Picker
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
        final galleryPhotos = await MediaPickerService().pickImagesFromGallery(
          context,
          allowMultiple: false,
        );
        photo = galleryPhotos.isNotEmpty ? galleryPhotos.first : null;
      }
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
        setState(() => _photos.add(photo!.path));
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

    // final source = await showModalBottomSheet<ImageSource>(
    //   context: context,
    //   backgroundColor: Colors.white,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    //   ),
    //   builder: (ctx) => SafeArea(
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(vertical: 12),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Container(
    //             width: 40,
    //             height: 4,
    //             margin: const EdgeInsets.only(bottom: 12),
    //             decoration: BoxDecoration(
    //               color: Colors.grey.shade300,
    //               borderRadius: BorderRadius.circular(2),
    //             ),
    //           ),
    //           const Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    //             child: Align(
    //               alignment: Alignment.centerLeft,
    //               child: Text(
    //                 'Attach Video',
    //                 style: TextStyle(
    //                   fontSize: 16,
    //                   fontWeight: FontWeight.w700,
    //                   color: AppColors.textDark,
    //                 ),
    //               ),
    //             ),
    //           ),
    //           ListTile(
    //             leading: const CircleAvatar(
    //               backgroundColor: Color(0xFFEFF6FF),
    //               child: Icon(
    //                 Icons.videocam_outlined,
    //                 color: Color(0xFF2563EB),
    //               ),
    //             ),
    //             title: const Text('Record video (Camera)'),
    //             subtitle: const Text('Record video up to 3 minutes'),
    //             onTap: () => Navigator.pop(ctx, ImageSource.camera),
    //           ),
    //           ListTile(
    //             leading: const CircleAvatar(
    //               backgroundColor: Color(0xFFF1F5F9),
    //               child: Icon(
    //                 Icons.video_library_outlined,
    //                 color: AppColors.primary,
    //               ),
    //             ),
    //             title: const Text('Choose from gallery'),
    //             subtitle: const Text('Select video from device gallery'),
    //             onTap: () => Navigator.pop(ctx, ImageSource.gallery),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );

    // 2. Video Picker
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
        setState(() => _videos.add(video!.path));
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
      final docs = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: false,
      );

      if (docs.isNotEmpty) {
        final doc = docs.first;
        final filePath = doc.path ?? '';
        if (filePath.isNotEmpty) {
          final maxMb = _metadata?.uploadLimits.documents.mb ?? 10;
          final sizeInBytes =
              (await doc.length()) ??
              doc.lengthSync() ??
              (File(filePath).existsSync() ? File(filePath).lengthSync() : 0);
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

    if (_isAnimalHusbandryVolunteer &&
        _subcategories.isNotEmpty &&
        _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a population subcategory.'),
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
        populationSubcategoryId: _isAnimalHusbandryVolunteer
            ? _selectedSubcategory?.id
            : null,
        populationSubcategory: _isAnimalHusbandryVolunteer
            ? _selectedSubcategory?.name
            : null,
        populationSubcategoryOther:
            (_isAnimalHusbandryVolunteer &&
                _selectedSubcategory?.isOther == true)
            ? _otherSubcategoryController.text.trim()
            : null,
        observations: _observationsController.text.trim(),
        actionTaken: _actionTakenController.text.trim(),
        description: _mediaCaptionController.text.trim(),
        isReferralGenerated: _isReferralGenerated,
        isAlertGenerated: _isAlertGenerated,
        isFollowUpRequired: _isFollowUpRequired,
        photos: _photos,
        videos: _videos,
        documents: _documents,
        removedAttachmentIds: _removedAttachmentIds,
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        accuracy: _accuracy,
        gpsUnavailableReason: _lat == null
            ? 'Location unavailable or permission denied'
            : null,
        volunteerId: effectiveVolunteerId,
        deviceId: _deviceId,
      );

      int? targetEventId;
      final EventReportResult result;
      if (widget.isEditMode) {
        targetEventId = widget.editEvent?.numericId;
        if (targetEventId == null && widget.editEvent != null) {
          final numericMatches = RegExp(r'\d+$')
              .firstMatch(widget.editEvent!.id);
          if (numericMatches != null) {
            targetEventId = int.tryParse(numericMatches.group(0)!);
          }
        }
        if (targetEventId != null) {
          result = await _apiService.updateEventReport(targetEventId, request);
        } else {
          result = await _apiService.submitEventReport(
            request,
            allowOfflineFallback: false,
          );
        }
      } else {
        result = await _apiService.submitEventReport(
          request,
          allowOfflineFallback: false,
        );
      }

      if (result.status != 'synced') {
        throw Exception(result.message);
      }

      final effectiveNumericId =
          userSession?.numericVolunteerId ??
          VolunteerOwnershipFilter.extractNumericSuffix(effectiveVolunteerId);

      // Resolve event code and numeric database ID, always preserving existing code in edit mode
      final effectiveReportCode = (result.reportId.isNotEmpty && result.reportId != 'EVT-26-0001')
          ? result.reportId
          : (widget.isEditMode && widget.editEvent != null
              ? widget.editEvent!.id
              : 'EVT-${DateTime.now().millisecondsSinceEpoch}');

      final effectiveEventReportId = result.eventReportId ?? widget.editEvent?.numericId ?? targetEventId;

      final newItem = EventReportItem(
        id: effectiveReportCode,
        numericId: effectiveEventReportId,
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
        verificationStatus: result.verificationStatus ?? (widget.editEvent?.verificationStatus ?? 'SUBMITTED'),
        totalVisits: request.totalVisits,
        targetPopulation: request.targetPopulation,
        observations: request.observations,
        actionTaken: request.actionTaken,
        description: request.description,
        mediaFiles: [..._photos, ..._videos, ..._documents],
        latitude: _lat,
        longitude: _lng,
        gpsAccuracyM: _accuracy,
        attachments: [
          ..._photos.map((p) => AppAttachmentItem.fromPath(p, fileKind: 'IMAGE', latitude: _lat, longitude: _lng, accuracy: _accuracy, capturedAt: _gpsTimestamp)),
          ..._videos.map((v) => AppAttachmentItem.fromPath(v, fileKind: 'VIDEO', latitude: _lat, longitude: _lng, accuracy: _accuracy, capturedAt: _gpsTimestamp)),
          ..._documents.map((d) => AppAttachmentItem.fromPath(d, fileKind: 'DOCUMENT', latitude: _lat, longitude: _lng, accuracy: _accuracy, capturedAt: _gpsTimestamp)),
        ],
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
        volunteerName: userSession?.fullName,
      );

      await SessionManager.saveSubmittedEvent(
        newItem,
        volunteerId: effectiveVolunteerId,
        numericVolunteerId: effectiveNumericId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message} ($effectiveReportCode)'),
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
        appBar: AuthenticatedAppBar(
          title: widget.isEditMode ? 'Edit Event Report' : 'Event Reporting',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: widget.volunteerId,
          onBackPressed: () => Navigator.pop(context),
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadMetadata(forceRefresh: true),
          color: const Color(0xFF136B4F),
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
                                  activeColor: AppColors.setuGreen,
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
                                _selectedSubcategory = null;
                                _otherSubcategoryController.clear();
                                _subcategories = [];
                                _subcategoriesError = null;
                              });
                              if (val != null && _isAnimalHusbandryVolunteer) {
                                _fetchPopulationSubcategories(val.id);
                              }
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
                          // Population Subcategory (Only for Animal Husbandry / Animal Health volunteers)
                          if (_isAnimalHusbandryVolunteer &&
                              _selectedPopulation != null) ...[
                            if (_isLoadingSubcategories)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Loading subcategories...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_subcategoriesError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _subcategoriesError!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            _fetchPopulationSubcategories(
                                              _selectedPopulation!.id,
                                              forceRefresh: true,
                                            ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Retry',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_subcategories.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildLabel('Population Subcategory *'),
                              _buildDropdownGeneric<
                                PopulationSubcategoryOption
                              >(
                                fieldId: 'population_subcategory',
                                value: _selectedSubcategory,
                                items: _subcategories,
                                itemLabel: (s) => s.name,
                                hintText: 'Select population subcategory',
                                title: 'Select Population Subcategory',
                                searchHint: 'Search subcategory (e.g. Cattle, Poultry)...',
                                onChanged: (val) {
                                  setState(() {
                                    _selectedSubcategory = val;
                                    if (val?.isOther != true) {
                                      _otherSubcategoryController.clear();
                                    }
                                  });
                                },
                                validator: (val) =>
                                    val == null ? 'Select subcategory' : null,
                              ),
                              if (_selectedSubcategory?.isOther == true) ...[
                                const SizedBox(height: 10),
                                _buildLabel('Specify other subcategory *'),
                                _buildTextFormField(
                                  controller: _otherSubcategoryController,
                                  hint: 'Enter subcategory name',
                                  validator: (val) =>
                                      val == null || val.trim().isEmpty
                                      ? 'Please specify other subcategory'
                                      : null,
                                ),
                              ],
                            ],
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

                          // // PHOTO / VIDEO / DOCUMENTATION
                          // _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),
                          // const SizedBox(height: 10),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: _buildDashedButton(
                          //         label:
                          //             '${_metadata?.uploadLimits.photos.label ?? "Photograph"} (${_photos.length}/${_metadata?.uploadLimits.photos.max ?? 5})',
                          //         onTap: _pickPhotograph,
                          //       ),
                          //     ),
                          //     const SizedBox(width: 10),
                          //     Expanded(
                          //       child: _buildDashedButton(
                          //         label:
                          //             '${_metadata?.uploadLimits.videos.label ?? "Video"} (${_videos.length}/${_metadata?.uploadLimits.videos.max ?? 2})',
                          //         onTap: _pickVideo,
                          //       ),
                          //     ),
                          //     const SizedBox(width: 10),
                          //     Expanded(
                          //       child: _buildDashedButton(
                          //         label:
                          //             '${_metadata?.uploadLimits.documents.label ?? "Document"} (${_documents.length}/${_metadata?.uploadLimits.documents.max ?? 4})',
                          //         onTap: _pickDocument,
                          //       ),
                          //     ),
                          //   ],
                          // ),

                          // PHOTO / VIDEO / DOCUMENTATION
                          _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              // 1. Photograph Card (Soft Blue Background)
                              Expanded(
                                child: _buildDashedButton(
                                  label: 'Photograph',
                                  backgroundColor: const Color(0xFFE2EDFF),
                                  icon: Icons.photo_camera_outlined,
                                  onTap: _pickPhotograph,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // 2. Video Card (Light Mint Green Background)
                              Expanded(
                                child: _buildDashedButton(
                                  label: 'Video',
                                  backgroundColor: const Color(0xFFDFF4E8),
                                  icon: Icons.videocam_outlined,
                                  onTap: _pickVideo,
                                ),
                              ),

                              const SizedBox(width: 10),

                              // 3. Document Card (Warm Cream Background)
                              Expanded(
                                child: _buildDashedButton(
                                  label: 'Document',
                                  backgroundColor: const Color(0xFFFFF4DF),
                                  icon: Icons.description_outlined,
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
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD1F2DD),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isFetchingLocation
                                      ? 'Acquiring GPS fix...'
                                      : (_lat != null && _lng != null
                                            ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)} · ±${_accuracy ?? 0} m'
                                            : (_locationData?.displayText ??
                                                  'Location unavailable (Tap Refresh GPS)')),
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
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFFD1F2DD),
                                    ),
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

                          // Action buttons
                          if (widget.isEditMode)
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : _handleSubmit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF136B4F,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                              'Save',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                        foregroundColor: const Color(
                                          0xFF136B4F,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
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
                                ),
                              ],
                            )
                          else ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF136B4F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
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
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
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
              color: Color(0xFF136B4F),
            ),
            label: Text(
              'Photo ${i + 1}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
            ),
            onDeleted: () {
              final path = _photos[i];
              _trackRemovedAttachment(path);
              setState(() => _photos.removeAt(i));
            },
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
            onDeleted: () {
              final path = _videos[i];
              _trackRemovedAttachment(path);
              setState(() => _videos.removeAt(i));
            },
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
                onDeleted: () {
                final path = _documents[i];
                _trackRemovedAttachment(path);
                setState(() => _documents.removeAt(i));
              },
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
            color: Color(0xFF136B4F),
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
              color: const Color(0xFF136B4F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _selectedPrimarySectorCode.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF136B4F),
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
        CircularProgressIndicator(color: Color(0xFF136B4F)),
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
    if (text.contains('*')) {
      final parts = text.split('*');
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text.rich(
          TextSpan(
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
                  color: Color(0xFFF5092B),
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
      primaryColor: const Color(0xFF136B4F),
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
          borderSide: const BorderSide(color: Color(0xFF136B4F), width: 1.5),
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
          borderSide: const BorderSide(color: Color(0xFF136B4F), width: 1.5),
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
              activeColor: const Color(0xFF136B4F),
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

  // Widget _buildDashedButton({
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return OutlinedButton(
  //     onPressed: onTap,
  //     style: OutlinedButton.styleFrom(
  //       side: const BorderSide(color: AppColors.border),
  //       padding: const EdgeInsets.symmetric(vertical: 12),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //     ),
  //     child: Text(
  //       label,
  //       style: const TextStyle(
  //         fontSize: 12.5,
  //         fontWeight: FontWeight.w600,
  //         color: AppColors.textDark,
  //       ),
  //     ),
  //   );
  // }

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
