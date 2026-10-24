import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class SampleSupportFormScreen extends StatefulWidget {
  const SampleSupportFormScreen({super.key});

  @override
  State<SampleSupportFormScreen> createState() =>
      _SampleSupportFormScreenState();
}

class _SampleSupportFormScreenState extends State<SampleSupportFormScreen> {
  static const Color primary = Color(0xFFC26378);
  static const Color background = Color(0xFFF8F6F9);

  final _formKey = GlobalKey<FormState>();
  final _facilitatedController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();

  String? _sampleType;
  String? _village;
  DateTime _date = DateTime(2026, 10, 24);

  final List<XFile> _photos = [];
  final List<XFile> _videos = [];
  final List<PlatformFile> _documents = [];

  final String _location =
      '25.281198, 82.953928 · ±22 m\n'
      '2026-10-24 22:40 · Achampet › Achampet › '
      'Nagarkurnool › Telangana\n'
      'Volunteer COHV-26-0001 · Device DEV-WZU69XEL';

  final List<String> _sampleTypes = [
    'Companion animal samples',
    'Blood samples',
    'Water samples',
    'Soil samples',
    'Other',
  ];

  final List<String> _villages = [
    'Achampet',
    'Nagarkurnool',
    'Mannanur',
    'Other',
  ];

  @override
  void dispose() {
    _facilitatedController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickPhotos() async {
    final remaining = 5 - _photos.length;
    if (remaining <= 0) {
      _message('You can add up to 5 photographs.');
      return;
    }

    final picker = ImagePicker();
    final files = await picker.pickMultiImage(
      limit: remaining,
      imageQuality: 85,
    );

    if (!mounted) return;

    setState(() {
      _photos.addAll(files.take(remaining));
    });
  }

  Future<void> _pickVideo() async {
    if (_videos.length >= 2) {
      _message('You can add up to 2 videos.');
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);

    if (file == null || !mounted) return;

    setState(() => _videos.add(file));
  }

  Future<void> _pickDocuments() async {
    final remaining = 4 - _documents.length;

    if (remaining <= 0) {
      _message('You can add up to 4 documents.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result.isEmpty || !mounted) return;

      setState(() {
        _documents.addAll(result.take(remaining));
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error picking documents: $e');
        _message('Could not pick documents: $e');
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_sampleType == null || _village == null) {
      _message('Please select sample type and village / ward.');
      return;
    }

    // Dummy save: no backend API is connected yet.
    final report = <String, dynamic>{
      'sampleType': _sampleType,
      'date': _date.toIso8601String(),
      'numberFacilitated': int.tryParse(_facilitatedController.text) ?? 1,
      'village': _village,
      'photos': _photos.map((file) => file.path).toList(),
      'videos': _videos.map((file) => file.path).toList(),
      'documents': _documents.map((file) => file.name).toList(),
      'description': _descriptionController.text.trim(),
      'location': _location,
    };

    debugPrint('Sample Support report: $report');

    Navigator.pop(context, report);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'New Sample Support',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          _headerButton(Icons.notifications_none_rounded, '2'),
          _headerButton(Icons.sync_rounded, '1'),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            children: [
              _label('Sample type', required: true),
              _dropdown(
                value: _sampleType,
                hint: 'Select',
                items: _sampleTypes,
                onChanged: (value) => setState(() => _sampleType = value),
              ),
              const SizedBox(height: 16),

              _label('Date', required: true),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: _inputDecoration(),
                  child: Row(
                    children: [
                      Text(
                        _formatDate(_date),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today, size: 15),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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

              _label('Village / ward', required: true),
              _dropdown(
                value: _village,
                hint: 'Select',
                items: _villages,
                onChanged: (value) => setState(() => _village = value),
              ),
              const SizedBox(height: 22),

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
                  const SizedBox(width: 7),
                  Expanded(child: _uploadButton('Video', onTap: _pickVideo)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _uploadButton('Document', onTap: _pickDocuments),
                  ),
                ],
              ),

              if (_photos.isNotEmpty ||
                  _videos.isNotEmpty ||
                  _documents.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${_photos.length} photographs, '
                  '${_videos.length} videos, '
                  '${_documents.length} documents selected',
                  style: const TextStyle(fontSize: 11, color: primary),
                ),
              ],

              const SizedBox(height: 14),
              const Text(
                'Up to 5 photographs (5 MB each), 2 videos '
                '(25 MB each) and 4 documents – PDF, Word or Excel '
                '(10 MB each).',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Color(0xFF89838F),
                ),
              ),

              _label('Description / caption'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _fieldDecoration(),
              ),
              const SizedBox(height: 12),

              const Text(
                'Date, time and GPS metadata are attached '
                'automatically. Personal identifiers should not '
                'be captured unnecessarily.',
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: Color(0xFF89838F),
                ),
              ),
              const SizedBox(height: 22),

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9FB),
                  border: Border.all(color: const Color(0xFFE9E3EA)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _location,
                      style: const TextStyle(fontSize: 10, height: 1.6),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () =>
                          _message('Connect GPS to refresh the location.'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: Color(0xFFE9D8DE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 9),

              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: Color(0xFFE9D8DE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerButton(IconData icon, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(9),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 19,
              color: Colors.white,
              onPressed: () => _message('Demo action'),
              icon: Icon(icon),
            ),
          ),
          Positioned(
            right: -3,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA323),
                shape: BoxShape.circle,
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: RichText(
        text: TextSpan(
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
                style: TextStyle(color: primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _inputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFF77717C)),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF89838F),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _uploadButton(String title, {required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF39333E),
        side: const BorderSide(
          color: Color(0xFFE9E3EA),
          style: BorderStyle.solid,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(title, style: const TextStyle(fontSize: 10)),
    );
  }

  BoxDecoration _inputDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFFE9E3EA)),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
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
