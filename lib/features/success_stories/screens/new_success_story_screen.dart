import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

const Color storyFormPink = Color(0xFFB85C78);
const Color storyFormBackground = Color(0xFFF6F3F7);
const Color storyFormBorder = Color(0xFFE3E0E3);
const Color storyFormMuted = Color(0xFF89848E);

class NewSuccessStoryScreen extends StatefulWidget {
  const NewSuccessStoryScreen({super.key});

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
  final _outcomeController = TextEditingController();
  final _benefitController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _captionController = TextEditingController();

  String? _department;
  bool _isInnovation = false;
  bool _isSaving = false;

  final List<PlatformFile> _photos = [];
  final List<PlatformFile> _videos = [];
  final List<PlatformFile> _documents = [];

  // Replace these placeholders with values from your location,
  // authentication and device services when available.
  final String _gps = 'GPS location not captured';
  final String _locationMetadata = 'Location metadata unavailable';
  final String _volunteerId = 'Not available';
  final String _deviceId = 'Not available';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController.text =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _issueController.dispose();
    _problemController.dispose();
    _actionController.dispose();
    _outcomeController.dispose();
    _benefitController.dispose();
    _lessonsController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final initial = _parseDate(_dateController.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;

    try {
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFiles({
    required String kind,
    required int maxCount,
    required int maxSizeMb,
  }) async {
    final List<PlatformFile> current;
    final FileType fileType;
    List<String>? extensions;

    switch (kind) {
      case 'photo':
        current = _photos;
        fileType = FileType.image;
        break;
      case 'video':
        current = _videos;
        fileType = FileType.video;
        break;
      default:
        current = _documents;
        fileType = FileType.custom;
        extensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx'];
    }

    final remaining = maxCount - current.length;

    if (remaining <= 0) {
      _showMessage('You can select up to $maxCount $kind files.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: fileType,
        allowedExtensions: extensions,
      );

      if (result.isEmpty) return;

      final accepted = <PlatformFile>[];
      final rejected = <String>[];

      for (final file in result) {
        if (accepted.length >= remaining) {
          rejected.add('${file.name}: file count limit reached');
          continue;
        }

        final sizeInBytes = (await file.length()) ?? _getFileSize(file);
        if (sizeInBytes > maxSizeMb * 1024 * 1024) {
          rejected.add('${file.name}: exceeds ${maxSizeMb}MB');
          continue;
        }

        accepted.add(file);
      }

      if (!mounted) return;

      setState(() {
        current.addAll(accepted);
      });

      if (rejected.isNotEmpty) {
        _showMessage(
          '${accepted.length} file(s) added. '
          '${rejected.length} file(s) skipped due to limits.',
        );
      } else if (accepted.isNotEmpty) {
        _showMessage('${accepted.length} file(s) added.');
      }
    } catch (e) {
      _showMessage('Unable to select files. Please try again.');
    }
  }

  void _removeFile(String kind, PlatformFile file) {
    setState(() {
      switch (kind) {
        case 'photo':
          _photos.remove(file);
          break;
        case 'video':
          _videos.remove(file);
          break;
        default:
          _documents.remove(file);
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshLocation() async {
    // TODO: Connect your actual GPS/location service here.
    _showMessage(
      'GPS refresh is not connected yet. '
      'Connect your location service to capture coordinates.',
    );
  }

  void _saveStory() {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please complete all required fields.');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final storyId = 'STY-${now.year}-${now.millisecondsSinceEpoch}';

    final story = <String, dynamic>{
      'id': storyId,
      'title': _titleController.text.trim(),
      'date': _dateController.text.trim(),
      'location': _locationController.text.trim(),
      'category': _isInnovation
          ? 'Innovation / Best Practice'
          : 'Success Story',
      'innovation': _isInnovation ? 'Yes' : 'No',
      'issue': _issueController.text.trim(),
      'problem': _problemController.text.trim(),
      'action': _actionController.text.trim(),
      'department': _department ?? 'Not selected',
      'outcome': _outcomeController.text.trim(),
      'benefit': _benefitController.text.trim(),
      'lessons': _lessonsController.text.trim(),
      'verification': 'Submitted',
      'sync': 'Pending',
      'gps': _gps,
      'locationMetadata': _locationMetadata,
      'volunteerId': _volunteerId,
      'deviceId': _deviceId,
      'caption': _captionController.text.trim(),
      'photos': _photos.map((f) => f.name).toList(),
      'videos': _videos.map((f) => f.name).toList(),
      'documents': _documents.map((f) => f.name).toList(),
      'status': 'pending',
    };

    Navigator.pop(context, story);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: storyFormBackground,
      appBar: AppBar(
        backgroundColor: storyFormPink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Success Story',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _refreshLocation,
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: storyFormBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textField(
                        controller: _titleController,
                        label: 'Title',
                        required: true,
                      ),
                      _dateField(),
                      _textField(
                        controller: _locationController,
                        label: 'Location',
                      ),
                      _textField(
                        controller: _issueController,
                        label: 'One Health issue',
                        required: true,
                      ),
                      _textField(
                        controller: _problemController,
                        label: 'Situation / problem',
                        required: true,
                        maxLines: 4,
                      ),
                      _textField(
                        controller: _actionController,
                        label: 'Action taken by COHV',
                        required: true,
                        maxLines: 4,
                      ),
                      _departmentDropdown(),
                      _textField(
                        controller: _outcomeController,
                        label: 'Outcome',
                        required: true,
                        maxLines: 4,
                      ),
                      _textField(
                        controller: _benefitController,
                        label: 'Community benefit',
                        maxLines: 4,
                      ),
                      _textField(
                        controller: _lessonsController,
                        label: 'Lessons learned',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8),
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
                      _sectionHeading('PHOTO / VIDEO / DOCUMENTATION'),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _attachmentButton(
                              label: 'Photograph',
                              icon: Icons.camera_alt_outlined,
                              onTap: () => _pickFiles(
                                kind: 'photo',
                                maxCount: 5,
                                maxSizeMb: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _attachmentButton(
                              label: 'Video',
                              icon: Icons.videocam_outlined,
                              onTap: () => _pickFiles(
                                kind: 'video',
                                maxCount: 2,
                                maxSizeMb: 25,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _attachmentButton(
                              label: 'Document',
                              icon: Icons.description_outlined,
                              onTap: () => _pickFiles(
                                kind: 'document',
                                maxCount: 4,
                                maxSizeMb: 10,
                              ),
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
                      _fileList('photo', _photos),
                      _fileList('video', _videos),
                      _fileList('document', _documents),
                      _textField(
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
                      _sectionHeading('LOCATION'),
                      const SizedBox(height: 12),
                      _locationCard(),
                    ],
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

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Date', true),
          const SizedBox(height: 10),
          TextFormField(
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

  Widget _departmentDropdown() {
    const departments = [
      'Health Department',
      'Animal Husbandry Department',
      'Forest Department',
      'Agriculture Department',
      'Rural Development Department',
      'Municipality / Panchayat',
      'Community / NGO',
      'Other',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Departments / stakeholders involved', false),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _department,
            isExpanded: true,
            hint: const Text('Select'),
            decoration: _inputDecoration(),
            items: departments
                .map(
                  (department) => DropdownMenuItem(
                    value: department,
                    child: Text(department, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _department = value);
            },
          ),
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

  Widget _fileList(String kind, List<PlatformFile> files) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Column(
      children: files.map((file) {
        final sizeMb = _getFileSize(file) / (1024 * 1024);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.attach_file, color: storyFormPink),
          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${sizeMb.toStringAsFixed(2)} MB'),
          trailing: IconButton(
            tooltip: 'Remove file',
            icon: const Icon(Icons.close),
            onPressed: () => _removeFile(kind, file),
          ),
        );
      }).toList(),
    );
  }

  Widget _locationCard() {
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
            _gps,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF39343D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _locationMetadata,
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
