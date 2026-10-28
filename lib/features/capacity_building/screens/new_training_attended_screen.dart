import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cohv/core/models/geo_location_data.dart';
import 'package:cohv/core/services/location_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/services/media_geotag_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import 'package:cohv/core/theme/app_colors.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';

const Color trainingGreen = Color(
  0xFF19765E,
); // Primary green from the app palette
const Color trainingBackground = Color(0xFFF2F7F5);
const Color trainingBorder = Color(0xFFDCE6E2);
const Color trainingMuted = Color(0xFF64748B); // Slate
const Color trainingred = Color(0xFFFA0430);
const Color trainingPhotoBackground = Color(0xFFE2EDFF); // Soft blue
const Color trainingDocumentBackground = Color(0xFFFFF4DF); // Warm cream
const Color trainingText = Color(0xFF233B33);

class PickedAttachment {
  final String name;
  final String path;
  final int size;

  const PickedAttachment({
    required this.name,
    required this.path,
    required this.size,
  });
}

class NewTrainingAttendedScreen extends StatefulWidget {
  final String? volunteerId;

  const NewTrainingAttendedScreen({super.key, this.volunteerId});

  @override
  State<NewTrainingAttendedScreen> createState() =>
      _NewTrainingAttendedScreenState();
}

class _NewTrainingAttendedScreenState extends State<NewTrainingAttendedScreen> {
  final _formKey = GlobalKey<FormState>();

  // GPS Location parameters
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;

  final _venueController = TextEditingController();
  final _chairedByController = TextEditingController();
  final _keyPointsController = TextEditingController();
  final _captionController = TextEditingController();

  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingMasterModel> _trainingMasters = [];
  TrainingMasterModel? _selectedMaster;
  bool _isLoadingMasters = true;

  DateTime _selectedDate = DateTime.now();
  bool _certificateIssued = false;
  bool _isSaving = false;

  final List<PickedAttachment> _photographs = [];
  final List<PlatformFile> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadTrainingMasters();
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

  Future<void> _loadTrainingMasters() async {
    try {
      final masters = await _apiService.fetchTrainingMasters();
      if (!mounted) return;
      setState(() {
        _trainingMasters = masters;
        _isLoadingMasters = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trainingMasters = TrainingMasterModel.fallbackTypes();
        _isLoadingMasters = false;
      });
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
    _venueController.dispose();
    _chairedByController.dispose();
    _keyPointsController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: trainingGreen),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  int _getFileSize(PlatformFile file) {
    final syncLength = file.lengthSync();
    if (syncLength != null && syncLength > 0) {
      return syncLength;
    }
    final path = file.path;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) {
          return f.lengthSync();
        }
      } catch (_) {}
    }
    return 0;
  }

  Future<ImageSource?> _showPhotoSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
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
                      color: trainingText,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_outlined, color: trainingGreen),
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
  }

  Future<void> _pickPhotographs() async {
    final remaining = 5 - _photographs.length;

    if (remaining <= 0) {
      _showMessage('You can attach up to 5 photographs.');
      return;
    }

    // final source = await _showPhotoSourcePicker();
    final source = await _showMediaSourcePicker(
      title: 'Select Photo Source',
      cameraLabel: 'Camera',
      galleryLabel: 'Gallery',
      cameraIcon: Icons.camera_alt_outlined,
      galleryIcon: Icons.photo_library_outlined,
    );
    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        final photo = await MediaPickerService().capturePhoto(context);
        if (photo == null || !mounted) return;

        final originalFile = File(photo.path);
        if (await originalFile.exists()) {
          final size = await originalFile.length();
          if (size > 5 * 1024 * 1024) {
            _showMessage('Each photograph must be 5 MB or smaller.');
            return;
          }
        }

        final stampedPath = await MediaGeoTagService().processPhoto(
          filePath: photo.path,
          isFromCamera: true,
          fallbackLocation: _locationData,
        );

        final stampedFile = File(stampedPath);
        final fileLength = await stampedFile.length();
        final fileName = stampedPath.split(Platform.pathSeparator).last;
        final pFile = PickedAttachment(
          path: stampedPath,
          name: fileName,
          size: fileLength,
        );

        if (mounted) {
          setState(() {
            _photographs.add(pFile);
          });
        }
      } else {
        final result = await MediaPickerService().pickImageFiles(
          context,
          allowMultiple: true,
        );

        if (result.isEmpty || !mounted) return;

        final validFiles = <PickedAttachment>[];
        for (final file in result) {
          final size = (await file.length()) ?? _getFileSize(file);
          if (size <= 5 * 1024 * 1024) {
            if (file.path != null && file.path!.isNotEmpty) {
              final stampedPath = await MediaGeoTagService().processPhoto(
                filePath: file.path!,
                isFromCamera: false,
                fallbackLocation: _locationData,
              );
              final stampedFile = File(stampedPath);
              final fileLength = await stampedFile.length();
              final fileName = stampedPath.split(Platform.pathSeparator).last;
              validFiles.add(
                PickedAttachment(
                  path: stampedPath,
                  name: fileName,
                  size: fileLength,
                ),
              );
            }
            if (validFiles.length >= remaining) break;
          }
        }

        if (!mounted) return;

        setState(() {
          _photographs.addAll(validFiles);
        });

        if (validFiles.length < result.length) {
          _showMessage(
            'Some files were skipped. Maximum 5 photographs, 5 MB each.',
          );
        }
      }
    } catch (e) {
      debugPrint('[TRAINING_ATTENDED] Error picking photographs: $e');
      _showMessage('Unable to select photographs.');
    }
  }

  Future<void> _pickDocuments() async {
    final remaining = 4 - _documents.length;

    if (remaining <= 0) {
      _showMessage('You can attach up to 4 documents.');
      return;
    }

    try {
      final result = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (result.isEmpty || !mounted) return;

      final validFiles = <PlatformFile>[];
      for (final file in result) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size <= 10 * 1024 * 1024) {
          validFiles.add(file);
          if (validFiles.length >= remaining) break;
        }
      }

      if (!mounted) return;

      setState(() {
        _documents.addAll(validFiles);
      });

      if (validFiles.length < result.length) {
        _showMessage(
          'Some files were skipped. Maximum 4 documents, 10 MB each.',
        );
      }
    } catch (e) {
      _showMessage('Unable to select documents.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _removePhotograph(int index) {
    setState(() => _photographs.removeAt(index));
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  Future<void> _saveTraining() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedMaster == null) {
      _showMessage('Please select a training.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await SessionManager.getUserSession();
      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final request = TrainingAttendedCreateRequest(
        trainingId: _selectedMaster!.trainingId,
        trainingDate: dateStr,
        venue: _venueController.text.trim(),
        chairedBy: _chairedByController.text.trim(),
        keyPoints: _keyPointsController.text.trim(),
        certificateIssued: _certificateIssued,
        clientRef: 'TRN-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: session?.volunteerId,
        latitude: GeoLocationData.formatCoordinate(_lat),
        longitude: GeoLocationData.formatCoordinate(_lng),
        gpsAccuracyM: _accuracy,
        capturedAt: _gpsTimestamp.toUtc().toIso8601String(),
        photos: _photographs
            .map((f) => f.path)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList(),
        documents: _documents
            .map((f) => f.path)
            .whereType<String>()
            .where((p) => p.isNotEmpty)
            .toList(),
      );

      final response = await _apiService.submitTrainingAttended(request);

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (response.success) {
        final code = response.record?.trainingAttendedCode ?? '';
        final msg = code.isNotEmpty
            ? 'Training attended $code recorded successfully.'
            : response.message;
        _showMessage(msg);
        Navigator.pop(context, true);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage('Unable to submit training attended: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: trainingBackground,
      appBar: AuthenticatedAppBar(
        title: 'New Training Attended',
        backgroundColor: trainingGreen,
        volunteerId: widget.volunteerId ?? '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 16),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: trainingBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Training', required: true),
                  const SizedBox(height: 5),

                  SearchableDropdownFormField<TrainingMasterModel>(
                    key: ValueKey(
                      'training_attended_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
                    ),
                    fieldId: 'training_attended',
                    primaryColor: trainingGreen,
                    items: _trainingMasters,
                    value: _selectedMaster,
                    itemLabel: (item) => item.trainingName,
                    hintText: 'Select',
                    isLoading: _isLoadingMasters,
                    onChanged: (val) {
                      setState(() => _selectedMaster = val);
                    },
                    validator: (val) =>
                        val == null ? 'Please select a training' : null,
                  ),

                  const SizedBox(height: 10),
                  _label('Date', required: true),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.black,
                        ),
                      ),
                      child: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: trainingText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  _label('Venue'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _venueController,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 10),
                  _label('Chaired by'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _chairedByController,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 10),
                  _label('Key points / action agreed'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _keyPointsController,
                    maxLines: 3,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 10),
                  _label('Certificate issued'),
                  const SizedBox(height: 5),
                  RadioGroup<bool>(
                    groupValue: _certificateIssued,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _certificateIssued = value);
                      }
                    },
                    child: Row(
                      children: [
                        Radio<bool>(value: true, activeColor: trainingGreen),
                        const Text('Yes', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 25),
                        Radio<bool>(value: false, activeColor: trainingGreen),
                        const Text('No', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  _sectionTitle('PHOTO / DOCUMENTATION'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _uploadButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          backgroundColor: trainingPhotoBackground,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _uploadButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
                          backgroundColor: trainingDocumentBackground,
                          onTap: _pickDocuments,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Up to 5 photographs (5 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(
                      color: Color(0xFF758781),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  if (_photographs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _label('Attached Photographs:'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _photographs.length,
                      (index) => _fileTile(
                        _photographs[index].name,
                        () => _removePhotograph(index),
                      ),
                    ),
                  ],

                  if (_documents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _label('Attached Documents:'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _documents.length,
                      (index) => _fileTile(
                        _documents[index].name,
                        () => _removeDocument(index),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  _label('Description / caption'),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _captionController,
                    maxLines: 3,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 14),
                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(
                      color: Color(0xFF758781),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 35),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTraining,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: trainingGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: trainingGreen.withValues(
                          alpha: 0.6,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: trainingGreen,
                        side: const BorderSide(color: trainingBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
      bottomNavigationBar: const _TrainingBottomNavigation(),
    );
  }

  // Widget _label(String text, {bool required = false}) {
  // return RichText(
  // text: TextSpan(
  // style: const TextStyle(
  // color: Color(0xFF233B33),
  // fontSize: 14,
  // fontWeight: FontWeight.w700,
  // ),
  // children: [
  // TextSpan(text: text),
  // if (required)
  // const TextSpan(
  // text: '*',
  // style: TextStyle(color: trainingred),
  // ),
  // ],
  // ),
  // );
  // }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          // Same dark slate text color as Referral form
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE11028),
                // Same red asterisk color as Referral form
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: trainingMuted,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: trainingBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: trainingBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: trainingGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _uploadButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: trainingGreen,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
        side: const BorderSide(color: trainingBorder, style: BorderStyle.solid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _fileTile(String fileName, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF4E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file, color: trainingGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _TrainingBottomNavigation extends StatelessWidget {
  const _TrainingBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: trainingBorder, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _BottomItem(icon: Icons.home, label: 'Dashboard'),
          _BottomItem(icon: Icons.grid_view_rounded, label: 'Actions'),
          _BottomItem(icon: Icons.article_outlined, label: 'Reports'),
          _BottomItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: trainingMuted, size: 27),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: trainingMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
