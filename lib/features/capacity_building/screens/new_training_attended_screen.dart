import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cohv/core/storage/session_manager.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';

const Color trainingGreen = Color(0xFF176B57);
const Color trainingBackground = Color(0xFFF2F7F5);
const Color trainingBorder = Color(0xFFDCE6E2);
const Color trainingMuted = Color(0xFF81918B);

class NewTrainingAttendedScreen extends StatefulWidget {
  const NewTrainingAttendedScreen({super.key});

  @override
  State<NewTrainingAttendedScreen> createState() =>
      _NewTrainingAttendedScreenState();
}

class _NewTrainingAttendedScreenState extends State<NewTrainingAttendedScreen> {
  final _formKey = GlobalKey<FormState>();

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

  final List<PlatformFile> _photographs = [];
  final List<PlatformFile> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadTrainingMasters();
  }

  Future<void> _loadTrainingMasters() async {
    try {
      final masters = await _apiService.fetchTrainingMasters();
      if (!mounted) return;
      setState(() {
        _trainingMasters = masters;
        _isLoadingMasters = false;
        if (_trainingMasters.isNotEmpty && _selectedMaster == null) {
          _selectedMaster = _trainingMasters.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _trainingMasters = TrainingMasterModel.fallbackTypes();
        _isLoadingMasters = false;
        if (_selectedMaster == null && _trainingMasters.isNotEmpty) {
          _selectedMaster = _trainingMasters.first;
        }
      });
    }
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

  Future<void> _pickPhotographs() async {
    final remaining = 5 - _photographs.length;

    if (remaining <= 0) {
      _showMessage('You can attach up to 5 photographs.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(type: FileType.image);

      if (result.isEmpty || !mounted) return;

      final validFiles = <PlatformFile>[];
      for (final file in result) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size <= 5 * 1024 * 1024) {
          validFiles.add(file);
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
    } catch (e) {
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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
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
      appBar: AppBar(
        backgroundColor: trainingGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Training Attended',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _headerButton(icon: Icons.notifications, badge: '4', onTap: () {}),
          _headerButton(icon: Icons.sync, badge: '1', onTap: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: trainingBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Training', required: true),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<TrainingMasterModel>(
                    initialValue: _selectedMaster,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      hint: _isLoadingMasters
                          ? 'Loading training types...'
                          : 'Select',
                    ),
                    icon: _isLoadingMasters
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: trainingGreen,
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down,
                            size: 30,
                            color: trainingMuted,
                          ),
                    items: _trainingMasters.map((master) {
                      return DropdownMenuItem<TrainingMasterModel>(
                        value: master,
                        child: Text(
                          master.trainingName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedMaster = value);
                    },
                    validator: (value) =>
                        value == null ? 'Please select a training' : null,
                  ),

                  const SizedBox(height: 24),
                  _label('Date', required: true),
                  const SizedBox(height: 10),
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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _label('Venue'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _venueController,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 24),
                  _label('Chaired by'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _chairedByController,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 24),
                  _label('Key points / action agreed'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _keyPointsController,
                    maxLines: 4,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 24),
                  _label('Certificate issued'),
                  const SizedBox(height: 10),
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

                  const SizedBox(height: 24),
                  _sectionTitle('PHOTO / DOCUMENTATION'),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _uploadButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _uploadButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
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

                  const SizedBox(height: 24),
                  _label('Description / caption'),
                  const SizedBox(height: 10),
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
                    height: 64,
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
                          borderRadius: BorderRadius.circular(18),
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
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: trainingGreen,
                        side: const BorderSide(color: trainingBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 19,
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

  Widget _headerButton({
    required IconData icon,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 27),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF843B),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF233B33),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: trainingGreen),
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
        fontSize: 15,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: trainingBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: trainingBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: trainingGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _uploadButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF526B61),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        side: const BorderSide(color: trainingBorder, style: BorderStyle.solid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _fileTile(String fileName, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0ED),
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
              style: const TextStyle(fontSize: 14),
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
