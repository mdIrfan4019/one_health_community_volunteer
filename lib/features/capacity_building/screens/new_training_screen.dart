import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const Color newTrainingGreen = Color(0xFF176B57);
const Color newTrainingBackground = Color(0xFFF3F8F6);
const Color newTrainingBorder = Color(0xFFDCE7E2);
const Color newTrainingMuted = Color(0xFF80918B);
const Color newTrainingText = Color(0xFF243832);
const Color newTrainingred = Color(0xFFF80418);
const Color newTrainingPhotoBackground = Color(0xFFE2EDFF); // Soft blue
const Color newTrainingDocumentBackground = Color(0xFFFFF4DF); // Warm cream

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

class NewTrainingScreen extends StatefulWidget {
  final String? volunteerId;

  const NewTrainingScreen({super.key, this.volunteerId});

  @override
  State<NewTrainingScreen> createState() => _NewTrainingScreenState();
}

class _NewTrainingScreenState extends State<NewTrainingScreen> {
  final _formKey = GlobalKey<FormState>();

  // GPS Location parameters
  double? _lat;
  double? _lng;
  int? _accuracy;
  DateTime _gpsTimestamp = DateTime.now();
  GeoLocationData? _locationData;
  bool _isFetchingLocation = false;

  final TextEditingController _organisedByController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingMasterModel> _trainingMasters = [];
  TrainingMasterModel? _selectedMaster;
  bool _isLoadingMasters = true;

  DateTime _selectedDate = DateTime.now();

  final List<PickedAttachment> _photographs = [];
  final List<PlatformFile> _documents = [];

  bool _isSaving = false;

  int get _wordCount {
    final text = _remarksController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

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
    _organisedByController.dispose();
    _durationController.dispose();
    _remarksController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: newTrainingGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: newTrainingText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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
                      color: newTrainingText,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: newTrainingGreen,
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
  }

  Future<void> _pickPhotographs() async {
    if (_photographs.length >= 5) {
      _showMessage('You can select up to 5 photographs.');
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
        final selectedFiles = await MediaPickerService().pickImageFiles(
          context,
          allowMultiple: true,
        );

        if (selectedFiles.isEmpty || !mounted) return;

        final remaining = 5 - _photographs.length;
        if (selectedFiles.length > remaining) {
          _showMessage('You can select up to 5 photographs in total.');
        }

        final filesToAdd = selectedFiles.take(remaining).toList();
        final stampedList = <PickedAttachment>[];

        for (final file in filesToAdd) {
          final size = (await file.length()) ?? _getFileSize(file);
          if (size > 5 * 1024 * 1024) {
            _showMessage('Skipped photograph exceeding 5 MB limit.');
            continue;
          }

          if (file.path != null && file.path!.isNotEmpty) {
            final stampedPath = await MediaGeoTagService().processPhoto(
              filePath: file.path!,
              isFromCamera: false,
              fallbackLocation: _locationData,
            );
            final stampedFile = File(stampedPath);
            final fileLength = await stampedFile.length();
            final fileName = stampedPath.split(Platform.pathSeparator).last;
            stampedList.add(
              PickedAttachment(
                path: stampedPath,
                name: fileName,
                size: fileLength,
              ),
            );
          }
        }

        if (stampedList.isNotEmpty && mounted) {
          setState(() {
            _photographs.addAll(stampedList);
          });
        }
      }
    } catch (e) {
      debugPrint('[TRAINING_IMPARTED] Error picking photographs: ');
      _showMessage('Unable to select photographs.');
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final selectedFiles = await MediaPickerService().pickDocuments(
        context,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
        allowMultiple: true,
      );

      if (selectedFiles.isEmpty || !mounted) return;

      if (_documents.length + selectedFiles.length > 4) {
        _showMessage('You can select up to 4 documents.');
        return;
      }

      bool hasOversized = false;
      for (final file in selectedFiles) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size > 10 * 1024 * 1024) {
          hasOversized = true;
          break;
        }
      }

      if (hasOversized) {
        _showMessage('Each document must be 10 MB or smaller.');
        return;
      }

      setState(() {
        _documents.addAll(selectedFiles);
      });
    } catch (e) {
      _showMessage('Unable to select documents.');
    }
  }

  void _removePhotograph(int index) {
    setState(() {
      _photographs.removeAt(index);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _documents.removeAt(index);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _saveTraining() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMaster == null) {
      _showMessage('Please select a training.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final session = await SessionManager.getUserSession();
      final dateStr =
          '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      final request = TrainingImpartedCreateRequest(
        trainingId: _selectedMaster!.trainingId,
        trainingDate: dateStr,
        organisedBy: _organisedByController.text.trim(),
        duration: _durationController.text.trim(),
        remarks: _remarksController.text.trim(),
        clientRef: 'TRI-${DateTime.now().millisecondsSinceEpoch}',
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

      final response = await _apiService.submitTrainingImparted(request);

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      if (response.success) {
        final code = response.record?.trainingImpartedCode ?? '';
        final msg = code.isNotEmpty
            ? 'Training imparted $code created successfully.'
            : response.message;
        _showMessage(msg);
        Navigator.pop(context, true);
      } else {
        _showMessage(response.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      _showMessage('Unable to submit training: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: newTrainingBackground,
      appBar: AuthenticatedAppBar(
        title: 'New Training Imparted',
        backgroundColor: newTrainingGreen,
        volunteerId: widget.volunteerId ?? '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 16),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: newTrainingBorder),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Training dropdown
                  _fieldLabel('Training', required: true),
                  const SizedBox(height: 6),

                  SearchableDropdownFormField<TrainingMasterModel>(
                    key: ValueKey(
                      'training_imparted_${_selectedMaster?.trainingId ?? 'none'}_${_trainingMasters.length}',
                    ),
                    fieldId: 'training_imparted',
                    primaryColor: newTrainingGreen,
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

                  // Date
                  _fieldLabel('Date', required: true),
                  const SizedBox(height: 6),

                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.black,
                          size: 23,
                        ),
                      ),
                      child: Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: newTrainingText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Organised by
                  _fieldLabel('Organised by'),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _organisedByController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'e.g. District Health Department',
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Duration
                  _fieldLabel('Duration'),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _durationController,
                    decoration: _inputDecoration(hint: 'e.g. 2 days'),
                  ),

                  const SizedBox(height: 10),

                  // Remarks
                  _fieldLabel('Remarks'),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    maxLength: 250,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: _inputDecoration().copyWith(
                      counterText: '',
                      alignLabelWithHint: true,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_wordCount / 250 words',
                      style: const TextStyle(
                        fontSize: 14,
                        color: newTrainingMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Photo / documentation heading
                  const Text(
                    'PHOTO / DOCUMENTATION',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Attachment buttons
                  Row(
                    children: [
                      Expanded(
                        child: _attachmentButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          backgroundColor: newTrainingPhotoBackground,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _attachmentButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
                          backgroundColor: newTrainingDocumentBackground,
                          onTap: _pickDocuments,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Up to 5 photographs (5 MB each) and 4 documents '
                    '— PDF, Word or Excel (10 MB each).',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Selected photographs
                  if (_photographs.isNotEmpty) ...[
                    _fieldLabel('Selected photographs'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _photographs.length,
                      (index) => _selectedFileTile(
                        name: _photographs[index].name,
                        onRemove: () => _removePhotograph(index),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Selected documents
                  if (_documents.isNotEmpty) ...[
                    _fieldLabel('Selected documents'),
                    const SizedBox(height: 8),
                    ...List.generate(
                      _documents.length,
                      (index) => _selectedFileTile(
                        name: _documents[index].name,
                        onRemove: () => _removeDocument(index),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Description / caption
                  _fieldLabel('Description / caption'),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _captionController,
                    maxLines: 2,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 6),

                  // Metadata note
                  const Text(
                    'Date, time and GPS metadata are attached '
                    'automatically. Personal identifiers should not '
                    'be captured unnecessarily.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveTraining,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: newTrainingGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: newTrainingGreen.withValues(
                          alpha: 0.6,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
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

                  const SizedBox(height: 10),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: newTrainingGreen,
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: newTrainingBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Widget _fieldLabel(String label, {bool required = false}) {
  // return RichText(
  // text: TextSpan(
  // style: const TextStyle(
  // fontSize: 14,
  // fontWeight: FontWeight.w700,
  // color: newTrainingText,
  // ),
  // children: [
  // TextSpan(text: label),
  // if (required)
  // const TextSpan(
  // text: ' *',
  // style: TextStyle(color: newTrainingred),
  // ),
  // ],
  // ),
  // );
  // }

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          // Same dark slate text color as Referral form
        ),
        children: [
          TextSpan(text: label),
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

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: newTrainingBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: newTrainingBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: newTrainingGreen, width: 1.7),
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

  Widget _attachmentButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: newTrainingBorder,
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: newTrainingGreen, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: newTrainingText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedFileTile({
    required String name,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: newTrainingBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: newTrainingGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: newTrainingText),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: newTrainingBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _BottomNavItem(icon: Icons.home, label: 'Dashboard'),
              _BottomNavItem(icon: Icons.grid_view_rounded, label: 'Actions'),
              _BottomNavItem(icon: Icons.article, label: 'Reports'),
              _BottomNavItem(icon: Icons.person, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomNavItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Connect to the existing app navigation if needed.
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 25, color: newTrainingMuted),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: newTrainingMuted,
            ),
          ),
        ],
      ),
    );
  }
}
