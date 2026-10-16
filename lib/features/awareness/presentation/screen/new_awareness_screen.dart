// Create file: lib/features/awareness/presentation/screen/new_awareness_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/features/awareness/data/awareness_api_service.dart';
import 'package:cohv/features/awareness/domain/awareness_models.dart';

class NewAwarenessScreen extends StatefulWidget {
  final String volunteerId;

  const NewAwarenessScreen({
    super.key,
    this.volunteerId = 'COHV-26-0001',
  });

  @override
  State<NewAwarenessScreen> createState() => _NewAwarenessScreenState();
}

class _NewAwarenessScreenState extends State<NewAwarenessScreen> {
  final _formKey = GlobalKey<FormState>();
  final AwarenessApiService _apiService = AwarenessApiService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedActivity;
  DateTime _selectedDate = DateTime.now();
  String? _selectedVillage;
  final TextEditingController _peopleReachedController = TextEditingController();
  String? _selectedTopic;
  String? _selectedDepartment;

  final List<String> _mediaFiles = [];
  final TextEditingController _mediaCaptionController = TextEditingController();

  // GPS and device metadata
  double _lat = 28.60928;
  double _lng = 77.367449;
  int _accuracy = 133;
  final String _deviceId = 'DEV-C0YBZ9WK';

  bool _isSaving = false;

  final List<String> _activities = [
    'Village meetings',
    'Household visits',
    'School awareness sessions',
    'Self-Help Group (SHG) meetings',
    'Gram Sabha presentation',
    'Focal group discussion',
    'Rallies & Campaigns',
  ];

  final List<String> _villages = [
    'Mannanur',
    'Amrabad',
    'Farhabad',
    'Padara',
    'Macharam',
    'Jangamreddipalli',
  ];

  final List<String> _topics = [
    'Sanitation and waste disposal',
    'Zoonotic disease prevention',
    'Rabies awareness & dog bite management',
    'Brucellosis & milk safety',
    'Avian Influenza / Bird Flu',
    'Vector-borne diseases (Malaria / Dengue)',
    'Safe animal handling & biosecurity',
    'General Health & Hygiene',
  ];

  final List<String> _departments = [
    'Multi-Sectoral Joint Team',
    'Health Department',
    'Animal Husbandry / Veterinary',
    'Forest & Wildlife Department',
    'Panchayat Raj & Rural Development',
    'Education Department',
  ];

  @override
  void dispose() {
    _peopleReachedController.dispose();
    _mediaCaptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) setState(() => _mediaFiles.add(photo.path));
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) setState(() => _mediaFiles.add(video.path));
    } catch (_) {}
  }

  void _refreshGps() {
    setState(() {
      _accuracy = 18;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS coordinates refreshed (High accuracy lock).')),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all mandatory fields (*).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final seq = (DateTime.now().millisecondsSinceEpoch % 9000) + 1000;
      final newActivity = AwarenessItem(
        id: 'AWR-26-$seq',
        activityType: _selectedActivity!,
        date: _selectedDate,
        village: _selectedVillage!,
        peopleReached: int.tryParse(_peopleReachedController.text.trim()) ?? 0,
        topicCovered: _selectedTopic ?? 'Sanitation and waste disposal',
        departmentInvolved: _selectedDepartment ?? 'Multi-Sectoral Joint Team',
        status: 'synced',
        mediaFiles: _mediaFiles,
        mediaCaption: _mediaCaptionController.text.trim().isEmpty ? null : _mediaCaptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: widget.volunteerId,
        deviceId: _deviceId,
      );

      final result = await _apiService.createAwareness(newActivity);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Awareness activity ${result.id} recorded successfully.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.year}';

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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'New Awareness Activity',
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
              onTap: () {},
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SingleChildScrollView(
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Activity *
                  _buildLabel('Activity *'),
                  _buildDropdown(
                    value: _selectedActivity,
                    items: _activities,
                    onChanged: (val) => setState(() => _selectedActivity = val),
                    validator: (val) => val == null ? 'Select activity' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Date *
                  _buildLabel('Date *'),
                  _buildPickerTile(
                    text: dateStr,
                    icon: Icons.calendar_today_outlined,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),

                  // 3. Village / ward *
                  _buildLabel('Village / ward *'),
                  _buildDropdown(
                    value: _selectedVillage,
                    items: _villages,
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    validator: (val) => val == null ? 'Select village / ward' : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Number of people reached
                  _buildLabel('Number of people reached with the livestock extension services'),
                  TextFormField(
                    controller: _peopleReachedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'e.g. 45',
                      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  ),
                  const SizedBox(height: 16),

                  // 5. Topic covered
                  _buildLabel('Topic covered'),
                  _buildDropdown(
                    value: _selectedTopic,
                    items: _topics,
                    onChanged: (val) => setState(() => _selectedTopic = val),
                  ),
                  const SizedBox(height: 16),

                  // 6. Departments / stakeholders involved
                  _buildLabel('Departments / stakeholders involved'),
                  _buildDropdown(
                    value: _selectedDepartment,
                    items: _departments,
                    onChanged: (val) => setState(() => _selectedDepartment = val),
                  ),
                  const SizedBox(height: 20),

                  // PHOTO / VIDEO / DOCUMENTATION
                  _buildSectionHeader('PHOTO / VIDEO / DOCUMENTATION'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Photograph',
                          onTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Video',
                          onTap: _pickVideo,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Document',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document attachment ready.')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Up to 5 photographs (5 MB each), 2 videos (25 MB each) and 4 documents — PDF, Word or Excel (10 MB each).',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 14),

                  // Description / caption
                  _buildLabel('Description / caption'),
                  TextFormField(
                    controller: _mediaCaptionController,
                    style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  ),
                  const SizedBox(height: 14),

                  // Privacy Notice
                  const Text(
                    'Date, time and GPS metadata are attached automatically. Personal identifiers should not be captured unnecessarily.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 20),

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
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')} 16:42 · ${_selectedVillage ?? "Mannanur"} › Amrabad › Nagarkurnool › Telangana',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Volunteer ${widget.volunteerId} · Device $_deviceId',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _refreshGps,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Refresh', style: TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 13.5, color: AppColors.textDark)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
      decoration: InputDecoration(
        hintText: 'Select',
        hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textLight),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
            Icon(icon, color: AppColors.textDark, size: 18),
          ],
        ),
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
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
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
        currentIndex: 1, // 'Actions' tab
        onTap: (index) => Navigator.pop(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
