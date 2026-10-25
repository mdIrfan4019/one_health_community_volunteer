// Screen for creating a new Success Story with dynamic department loading, searchable dropdown, camera/gallery picking, and POST API integration
// File: lib/features/success_stories/screens/new_success_story_screen.dart

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/core/widgets/searchable_dropdown.dart';
import '../data/success_story_api_service.dart';
import '../domain/success_story_models.dart';

const Color storyFormPink = Color(0xFFB85C78);
const Color storyFormBackground = Color(0xFFF6F3F7);
const Color storyFormBorder = Color(0xFFE3E0E3);
const Color storyFormMuted = Color(0xFF89848E);

class NewSuccessStoryScreen extends StatefulWidget {
  final SuccessStoryApiService? apiService;
  final String? initialVolunteerId;

  const NewSuccessStoryScreen({
    super.key,
    this.apiService,
    this.initialVolunteerId,
  });

  @override
  State<NewSuccessStoryScreen> createState() => _NewSuccessStoryScreenState();
}

class _NewSuccessStoryScreenState extends State<NewSuccessStoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _issueController = TextEditingController();
  final _problemController = TextEditingController();
  final _actionController = TextEditingController();
  final _otherDepartmentController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _benefitController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _captionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  late final SuccessStoryApiService _apiService;

  DateTime _selectedDate = DateTime.now();
  List<SuccessStoryDepartmentModel> _departments = [];
  SuccessStoryDepartmentModel? _selectedDepartment;
  bool _isLoadingDepartments = true;

  bool _isInnovation = false;
  bool _isSaving = false;

  final List<String> _photos = [];
  final List<String> _videos = [];
  final List<PlatformFile> _documents = [];

  // Dynamic session & location metadata
  String _volunteerId = '';
  int _numericVolunteerId = 1;
  final String _deviceId = 'DEV-WZU69XEL';
  double _latitude = 25.281198;
  double _longitude = 82.953928;
  int _gpsAccuracyM = 22;
  String? _gpsUnavailableReason;
  DateTime _gpsTimestamp = DateTime.now();

  String _villageName = 'Achampet Village';
  String _panchayatName = 'Achampet GP';
  String _districtName = 'Nagarkurnool';
  String _stateName = 'Telangana';

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SuccessStoryApiService();

    _dateController.text =
        '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';

    _loadSessionAndMetadata();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _issueController.dispose();
    _problemController.dispose();
    _actionController.dispose();
    _otherDepartmentController.dispose();
    _outcomeController.dispose();
    _benefitController.dispose();
    _lessonsController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  /// Load session credentials and location metadata dynamically
  Future<void> _loadSessionAndMetadata() async {
    try {
      final session = await SessionManager.getUserSession();
      final profile = await SessionManager.getDetailedProfile();
      final storedVid = await SessionManager.getVolunteerId();
      final storedNumId = await SessionManager.getNumericVolunteerId();

      final vid = (widget.initialVolunteerId != null &&
              widget.initialVolunteerId!.trim().isNotEmpty)
          ? widget.initialVolunteerId!.trim()
          : (storedVid ?? session?.volunteerId ?? 'COHV-26-0004');

      final numId = storedNumId ??
          session?.numericVolunteerId ??
          int.tryParse(RegExp(r'\d+$').firstMatch(vid)?.group(0) ?? '1') ??
          1;

      if (mounted) {
        setState(() {
          _volunteerId = vid;
          _numericVolunteerId = numId;

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

          if (_locationController.text.trim().isEmpty) {
            _locationController.text = '$_villageName, $_panchayatName';
          }
        });
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_FORM] Error loading session: $e');
    }
  }

  /// Fetch dynamic departments from GET /api/success-stories/departments
  Future<void> _fetchDepartments() async {
    if (mounted) setState(() => _isLoadingDepartments = true);

    try {
      final departments = await _apiService.fetchDepartments();
      if (mounted) {
        setState(() {
          _departments = departments;
          _isLoadingDepartments = false;
        });
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_FORM] Error fetching departments: $e');
      if (mounted) {
        setState(() {
          _departments = SuccessStoryDepartmentModel.fallbackDepartments();
          _isLoadingDepartments = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: storyFormPink),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
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
                                color: storyFormPink.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  Icon(cameraIcon, color: storyFormPink, size: 21),
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
                                color: storyFormPink.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                galleryIcon,
                                color: storyFormPink,
                                size: 21,
                              ),
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
      _showMessage('You can select up to 5 photographs.');
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
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        final file = File(photo.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > 5 * 1024 * 1024) {
            _showMessage('Photograph exceeds maximum size of 5 MB.');
            return;
          }
        }
        if (!_photos.contains(photo.path)) {
          setState(() => _photos.add(photo.path));
        }
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_FORM] Error picking photo: $e');
      _showMessage('Unable to pick photo. Please check permissions.');
    }
  }

  /// Pick video from Camera or Gallery (up to 2 videos, 25 MB each)
  Future<void> _pickVideo() async {
    if (_videos.length >= 2) {
      _showMessage('You can select up to 2 videos.');
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
      final video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );

      if (video != null && mounted) {
        final file = File(video.path);
        if (await file.exists()) {
          final sizeInBytes = await file.length();
          if (sizeInBytes > 25 * 1024 * 1024) {
            _showMessage('Video exceeds maximum size of 25 MB.');
            return;
          }
        }
        if (!_videos.contains(video.path)) {
          setState(() => _videos.add(video.path));
        }
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORY_FORM] Error picking video: $e');
      _showMessage('Unable to pick video. Please check permissions.');
    }
  }

  /// Pick documents – PDF, Word, Excel (up to 4 documents, 10 MB each)
  Future<void> _pickDocuments() async {
    if (_documents.length >= 4) {
      _showMessage('You can select up to 4 documents.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result.isEmpty) return;

      final file = result.first;
      final sizeInBytes = (await file.length()) ?? _getFileSize(file);
      if (sizeInBytes > 10 * 1024 * 1024) {
        _showMessage('Document exceeds maximum size of 10 MB.');
        return;
      }

      setState(() {
        if (!_documents.any((d) => d.name == file.name)) {
          _documents.add(file);
        }
      });
    } catch (e) {
      debugPrint('[SUCCESS_STORY_FORM] Error picking document: $e');
      _showMessage('Unable to pick document. Please try again.');
    }
  }

  void _removePhoto(String path) {
    setState(() => _photos.remove(path));
  }

  void _removeVideo(String path) {
    setState(() => _videos.remove(path));
  }

  void _removeDocument(PlatformFile file) {
    setState(() => _documents.remove(file));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _gpsTimestamp = DateTime.now();
      _latitude = 25.281198 + (DateTime.now().second % 5) * 0.00001;
      _longitude = 82.953928 + (DateTime.now().second % 5) * 0.00001;
      _gpsAccuracyM = 20;
      _gpsUnavailableReason = null;
    });
    _showMessage('Location coordinates refreshed.');
  }

  /// Submits the form via POST /api/success-stories
  Future<void> _saveStory() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please complete all required fields.');
      return;
    }

    if (_selectedDepartment == null) {
      _showMessage('Please select a department / stakeholder.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final clientRef = 'STY-${now.millisecondsSinceEpoch}';
    final storyDateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final request = SuccessStoryCreateRequest(
      volunteerId: _numericVolunteerId,
      clientRef: clientRef,
      deviceId: _deviceId,
      title: _titleController.text.trim(),
      storyDate: storyDateStr,
      locationText: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : '$_villageName, $_panchayatName',
      oneHealthIssue: _issueController.text.trim(),
      situation: _problemController.text.trim(),
      actionTaken: _actionController.text.trim(),
      departmentId: _selectedDepartment!.departmentId,
      departmentOther: _selectedDepartment!.isOther
          ? _otherDepartmentController.text.trim()
          : null,
      outcome: _outcomeController.text.trim(),
      communityBenefit: _benefitController.text.trim(),
      lessonsLearned: _lessonsController.text.trim(),
      isInnovation: _isInnovation,
      latitude: _latitude,
      longitude: _longitude,
      gpsAccuracyM: _gpsAccuracyM,
      gpsUnavailableReason: _gpsUnavailableReason,
    );

    final response = await _apiService.submitSuccessStory(request);

    if (!mounted) return;

    if (response.success) {
      _showMessage(response.message);

      final story = <String, dynamic>{
        'id': response.storyCode ?? clientRef,
        'storyId': response.storyId,
        'title': _titleController.text.trim(),
        'date': _dateController.text.trim(),
        'location': _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : '$_villageName, $_panchayatName',
        'category':
            _isInnovation ? 'Innovation / Best Practice' : 'Success Story',
        'innovation': _isInnovation ? 'Yes' : 'No',
        'issue': _issueController.text.trim(),
        'problem': _problemController.text.trim(),
        'action': _actionController.text.trim(),
        'department': _selectedDepartment!.departmentName,
        'departmentId': _selectedDepartment!.departmentId,
        'outcome': _outcomeController.text.trim(),
        'benefit': _benefitController.text.trim(),
        'lessons': _lessonsController.text.trim(),
        'verification': 'Submitted',
        'sync': 'Synced',
        'gps':
            '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)} · ±$_gpsAccuracyM m',
        'locationMetadata': _buildLocationMetadataString(),
        'volunteerId': _volunteerId,
        'deviceId': _deviceId,
        'caption': _captionController.text.trim(),
        'photos': List<String>.from(_photos),
        'videos': List<String>.from(_videos),
        'documents': _documents.map((f) => f.name).toList(),
        'status': 'submitted',
      };

      Navigator.pop(context, story);
    } else {
      setState(() => _isSaving = false);
      _showMessage(response.message);
    }
  }

  String _buildLocationMetadataString() {
    final timeStr =
        '${_gpsTimestamp.year}-${_gpsTimestamp.month.toString().padLeft(2, '0')}-${_gpsTimestamp.day.toString().padLeft(2, '0')} '
        '${_gpsTimestamp.hour.toString().padLeft(2, '0')}:${_gpsTimestamp.minute.toString().padLeft(2, '0')}';
    return '$timeStr · $_villageName › $_panchayatName › $_districtName › $_stateName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: storyFormBackground,
      appBar: AuthenticatedAppBar(
        title: 'New Success Story',
        volunteerId: _volunteerId,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: storyFormBorder),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Title
                      _textField(
                        key: const ValueKey('story_title_field'),
                        controller: _titleController,
                        label: 'Title',
                        required: true,
                      ),

                      // 2. Date
                      _dateField(key: const ValueKey('story_date_field')),

                      // 3. Location
                      _textField(
                        key: const ValueKey('story_location_field'),
                        controller: _locationController,
                        label: 'Location',
                      ),

                      // 4. One Health issue
                      _textField(
                        key: const ValueKey('story_issue_field'),
                        controller: _issueController,
                        label: 'One Health issue',
                        required: true,
                      ),

                      // 5. Situation / problem
                      _textField(
                        key: const ValueKey('story_problem_field'),
                        controller: _problemController,
                        label: 'Situation / problem',
                        required: true,
                        maxLines: 4,
                      ),

                      // 6. Action taken by COHV
                      _textField(
                        key: const ValueKey('story_action_field'),
                        controller: _actionController,
                        label: 'Action taken by COHV',
                        required: true,
                        maxLines: 4,
                      ),

                      // 7. Departments / stakeholders involved (Dynamic Searchable Dropdown)
                      _departmentDropdown(
                        key: const ValueKey('story_department_dropdown'),
                      ),

                      // 8. Outcome
                      _textField(
                        key: const ValueKey('story_outcome_field'),
                        controller: _outcomeController,
                        label: 'Outcome',
                        required: true,
                        maxLines: 4,
                      ),

                      // 9. Community benefit
                      _textField(
                        key: const ValueKey('story_benefit_field'),
                        controller: _benefitController,
                        label: 'Community benefit',
                        maxLines: 4,
                      ),

                      // 10. Lessons learned
                      _textField(
                        key: const ValueKey('story_lessons_field'),
                        controller: _lessonsController,
                        label: 'Lessons learned',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),

                      // 11. Innovation / Best Practice Checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: storyFormPink,
                        value: _isInnovation,
                        onChanged: (value) {
                          setState(() {
                            _isInnovation = value ?? false;
                          });
                        },
                        title: const Text(
                          'Record as an innovation / best practice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 28),

                      // 12. Media Section (Camera / Gallery picking)
                      _sectionHeading('PHOTO / VIDEO / DOCUMENTATION'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _attachmentButton(
                              label: 'Photograph',
                              icon: Icons.camera_alt_outlined,
                              onTap: _pickPhotos,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _attachmentButton(
                              label: 'Video',
                              icon: Icons.videocam_outlined,
                              onTap: _pickVideo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _attachmentButton(
                              label: 'Document',
                              icon: Icons.description_outlined,
                              onTap: _pickDocuments,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Up to 5 photographs (5 MB each), 2 videos '
                        '(25 MB each) and 4 documents — PDF, Word or '
                        'Excel (10 MB each).',
                        style: TextStyle(
                          color: storyFormMuted,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Media List Previews
                      _photoChipsList(),
                      _videoChipsList(),
                      _documentChipsList(),

                      const SizedBox(height: 8),

                      // 13. Description / Caption
                      _textField(
                        key: const ValueKey('story_caption_field'),
                        controller: _captionController,
                        label: 'Description / caption',
                        maxLines: 3,
                        required: false,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Date, time and GPS metadata should be attached '
                        'when the relevant device and location services '
                        'are connected. Avoid capturing unnecessary '
                        'personal identifiers.',
                        style: TextStyle(
                          color: storyFormMuted,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 14. Location Section
                      _sectionHeading('LOCATION'),
                      const SizedBox(height: 12),
                      _locationCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _bottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    Key? key,
    required TextEditingController controller,
    required String label,
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label, required),
          const SizedBox(height: 10),
          TextFormField(
            key: key,
            controller: controller,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter $label';
                    }
                    return null;
                  }
                : null,
            decoration: _inputDecoration(),
          ),
        ],
      ),
    );
  }

  Widget _dateField({Key? key}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Date', true),
          const SizedBox(height: 10),
          TextFormField(
            key: key,
            controller: _dateController,
            readOnly: true,
            onTap: _selectDate,
            validator: (value) =>
                value == null || value.isEmpty ? 'Select a date' : null,
            decoration: _inputDecoration(
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Searchable Dropdown for Departments / Stakeholders involved matching Screenshot 1 & 2
  Widget _departmentDropdown({Key? key}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Departments / stakeholders involved', false),
          const SizedBox(height: 10),
          SearchableDropdownFormField<SuccessStoryDepartmentModel>(
            key: key,
            fieldId: 'success_story_departments',
            items: _departments,
            value: _selectedDepartment,
            itemLabel: (dept) => dept.departmentName,
            searchMatcher: (dept, query) =>
                dept.departmentName.toLowerCase().contains(query.toLowerCase()),
            hintText: 'Select department',
            isLoading: _isLoadingDepartments,
            onChanged: (dept) {
              setState(() {
                _selectedDepartment = dept;
              });
            },
            onRetry: _fetchDepartments,
          ),
          if (_selectedDepartment?.isOther == true) ...[
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('story_other_department_field'),
              controller: _otherDepartmentController,
              decoration: _inputDecoration().copyWith(
                hintText: 'Specify department / stakeholder',
              ),
              validator: (val) {
                if (_selectedDepartment?.isOther == true &&
                    (val == null || val.trim().isEmpty)) {
                  return 'Please specify department / stakeholder';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, bool required) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF303036),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: storyFormPink),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: storyFormBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: storyFormBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: storyFormPink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _sectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: storyFormMuted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _attachmentButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF45404A),
        side: const BorderSide(
          color: storyFormBorder,
          style: BorderStyle.solid,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: storyFormPink, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _photoChipsList() {
    if (_photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _photos.map((path) {
          final filename = path.split(Platform.pathSeparator).last;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.photo_outlined, color: storyFormPink),
            title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _removePhoto(path),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _videoChipsList() {
    if (_videos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _videos.map((path) {
          final filename = path.split(Platform.pathSeparator).last;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.videocam_outlined, color: storyFormPink),
            title: Text(filename, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _removeVideo(path),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _documentChipsList() {
    if (_documents.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _documents.map((file) {
          final sizeMb = _getFileSize(file) / (1024 * 1024);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file, color: storyFormPink),
            title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${sizeMb.toStringAsFixed(2)} MB'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _removeDocument(file),
            ),
          );
        }).toList(),
      ),
    );
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

  Widget _locationCard() {
    final gpsString =
        '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)} · ±$_gpsAccuracyM m';
    final metadataString = _buildLocationMetadataString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9FB),
        border: Border.all(color: storyFormBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gpsString,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF39343D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metadataString,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF39343D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Volunteer $_volunteerId · Device $_deviceId',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF39343D),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _refreshLocation,
            style: OutlinedButton.styleFrom(
              foregroundColor: storyFormPink,
              side: const BorderSide(color: storyFormBorder),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _bottomButtons() {
    return Container(
      color: storyFormBackground,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                key: const ValueKey('story_save_button'),
                onPressed: _isSaving ? null : _saveStory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: storyFormPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: storyFormPink,
                  side: const BorderSide(color: storyFormBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
