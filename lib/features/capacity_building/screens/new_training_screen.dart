import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cohv/core/services/media_picker_service.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';



const Color newTrainingGreen = Color(0xFF176B57);
const Color newTrainingBackground = Color(0xFFF3F8F6);
const Color newTrainingBorder = Color(0xFFDCE7E2);
const Color newTrainingMuted = Color(0xFF80918B);
const Color newTrainingText = Color(0xFF243832);
const Color newTrainingred = Color(0xFFF80418);
class NewTrainingScreen extends StatefulWidget {
  final String? volunteerId;

  const NewTrainingScreen({super.key, this.volunteerId});

  @override
  State<NewTrainingScreen> createState() => _NewTrainingScreenState();
}

class _NewTrainingScreenState extends State<NewTrainingScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _organisedByController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingMasterModel> _trainingMasters = [];
  TrainingMasterModel? _selectedMaster;
  bool _isLoadingMasters = true;

  DateTime _selectedDate = DateTime.now();

  final List<PlatformFile> _photographs = [];
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

  Future<void> _pickPhotographs() async {
    try {
      final selectedFiles = await MediaPickerService().pickImageFiles(
        context,
        allowMultiple: true,
      );

      if (selectedFiles.isEmpty || !mounted) return;

      if (_photographs.length + selectedFiles.length > 5) {
        _showMessage('You can select up to 5 photographs.');
        return;
      }

      bool hasOversized = false;
      for (final file in selectedFiles) {
        final size = (await file.length()) ?? _getFileSize(file);
        if (size > 5 * 1024 * 1024) {
          hasOversized = true;
          break;
        }
      }

      if (hasOversized) {
        _showMessage('Each photograph must be 5 MB or smaller.');
        return;
      }

      setState(() {
        _photographs.addAll(selectedFiles);
      });
    } catch (e) {
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
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: newTrainingBorder),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Training dropdown
                  _fieldLabel('Training', required: true),
                  const SizedBox(height: 12),

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
                              color: newTrainingGreen,
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down,
                            size: 30,
                            color: newTrainingMuted,
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
                      setState(() {
                        _selectedMaster = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a training' : null,
                  ),

                  const SizedBox(height: 30),

                  // Date
                  _fieldLabel('Date', required: true),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(16),
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
                          fontSize: 16,
                          color: newTrainingText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Organised by
                  _fieldLabel('Organised by'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _organisedByController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'e.g. District Health Department',
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Duration
                  _fieldLabel('Duration'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _durationController,
                    decoration: _inputDecoration(hint: 'e.g. 2 days'),
                  ),

                  const SizedBox(height: 30),

                  // Remarks
                  _fieldLabel('Remarks'),
                  const SizedBox(height: 12),

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

                  const SizedBox(height: 32),

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

                  const SizedBox(height: 18),

                  // Attachment buttons
                  Row(
                    children: [
                      Expanded(
                        child: _attachmentButton(
                          label: 'Photograph',
                          icon: Icons.camera_alt_outlined,
                          onTap: _pickPhotographs,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _attachmentButton(
                          label: 'Document',
                          icon: Icons.description_outlined,
                          onTap: _pickDocuments,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Up to 5 photographs (5 MB each) and 4 documents '
                    '— PDF, Word or Excel (10 MB each).',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 22),

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
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                  ],

                  // Description / caption
                  _fieldLabel('Description / caption'),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _captionController,
                    maxLines: 2,
                    decoration: _inputDecoration(),
                  ),

                  const SizedBox(height: 24),

                  // Metadata note
                  const Text(
                    'Date, time and GPS metadata are attached '
                    'automatically. Personal identifiers should not '
                    'be captured unnecessarily.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      color: newTrainingMuted,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
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
                          borderRadius: BorderRadius.circular(18),
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
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 19,
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

  Widget _fieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: newTrainingText,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: newTrainingred),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFCFDFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: newTrainingBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: newTrainingBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: newTrainingGreen, width: 1.7),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _attachmentButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
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
              Icon(icon, color: newTrainingMuted, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
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
              style: const TextStyle(fontSize: 13),
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
