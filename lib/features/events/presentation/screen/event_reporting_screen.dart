// Create file: lib/features/events/presentation/screen/event_reporting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:cohv/features/events/data/event_api_service.dart';
import 'package:cohv/features/events/domain/event_models.dart';


class EventReportingScreen extends StatefulWidget {
  final String volunteerId;

  const EventReportingScreen({
    super.key,
    this.volunteerId = 'COHV-26-0001',
  });

  @override
  State<EventReportingScreen> createState() => _EventReportingScreenState();
}

class _EventReportingScreenState extends State<EventReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventApiService _apiService = EventApiService();
  final ImagePicker _picker = ImagePicker();

  // Form Fields & Selections
  String? _selectedEvent;
  String _selectedPrimarySector = 'Human Health';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedVillage;
  bool _isOutOfAreaVisit = false;

  final TextEditingController _purposeController = TextEditingController();
  String? _selectedLocationType;
  final TextEditingController _totalVisitsController = TextEditingController(text: '1');
  String? _selectedHumanPopulation;

  final TextEditingController _observationsController = TextEditingController();
  final TextEditingController _actionTakenController = TextEditingController();

  bool _isReferralGenerated = false;
  bool _isAlertGenerated = false;
  bool _isFollowUpRequired = false;

  final List<String> _mediaFiles = [];
  final TextEditingController _mediaCaptionController = TextEditingController();

  // Location parameters
  double _lat = 28.60928;
  double _lng = 77.367449;
  int _accuracy = 133;
  DateTime _gpsTimestamp = DateTime.now();
  final String _deviceId = 'DEV-C0YBZ9WK';

  bool _isSubmitting = false;

  final List<String> _eventOptions = [
    'Syndromic Surveillance (Fever / Rash / Cough)',
    'Unusual Animal Morbidity / Mortality',
    'Water Contamination / Diarrhea Cluster',
    'Zoonotic Spillover Suspected',
    'Routine Household Surveillance',
    'Animal Bite Case (Rabies Exposure)',
    'Environmental Vector Breeding Observed',
  ];

  final List<String> _sectors = [
    'Human Health',
    'Animal Health',
    'Environmental Health',
  ];

  final List<String> _villages = [
    'Mannanur',
    'Amrabad',
    'Farhabad',
    'Padara',
    'Macharam',
    'Jangamreddipalli',
  ];

  final List<String> _locationTypes = [
    'Household / Residential',
    'Community Hall / Public Gathering',
    'Primary Health Sub-Center',
    'Veterinary Field / Livestock Shed',
    'Water Body / Stream',
    'Forest Border / Wildlife Corridor',
  ];

  final List<String> _populationTypes = [
    'General Community',
    'Children (< 5 years)',
    'Elderly (> 60 years)',
    'High Risk / Tribal Groups',
    'Farmers & Livestock Handlers',
  ];

  @override
  void dispose() {
    _purposeController.dispose();
    _totalVisitsController.dispose();
    _observationsController.dispose();
    _actionTakenController.dispose();
    _mediaCaptionController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
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
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        setState(() => _mediaFiles.add(photo.path));
      }
    } catch (_) {}
  }

  void _refreshGps() {
    setState(() {
      _gpsTimestamp = DateTime.now();
      _accuracy = 18;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GPS coordinates refreshed (High accuracy lock).')),
    );
  }

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

    setState(() => _isSubmitting = true);

    try {
      final timeFormatted =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final request = EventReportRequest(
        eventType: _selectedEvent!,
        primarySector: _selectedPrimarySector,
        date: _selectedDate,
        time: timeFormatted,
        village: _selectedVillage!,
        isOutOfAreaVisit: _isOutOfAreaVisit,
        purposeOfVisit: _purposeController.text.trim(),
        locationType: _selectedLocationType!,
        totalVisits: int.tryParse(_totalVisitsController.text.trim()) ?? 1,
        targetPopulation: _selectedHumanPopulation!,
        observations: _observationsController.text.trim(),
        actionTaken: _actionTakenController.text.trim(),
        isReferralGenerated: _isReferralGenerated,
        isAlertGenerated: _isAlertGenerated,
        isFollowUpRequired: _isFollowUpRequired,
        mediaFiles: _mediaFiles,
        mediaCaption: _mediaCaptionController.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        volunteerId: widget.volunteerId,
        deviceId: _deviceId,
      );

      final result = await _apiService.submitEventReport(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.message} (${result.reportId})'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
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
                  // Event *
                  _buildLabel('Event *'),
                  _buildDropdown(
                    value: _selectedEvent,
                    items: _eventOptions,
                    onChanged: (val) => setState(() => _selectedEvent = val),
                    validator: (val) => val == null ? 'Please select an event' : null,
                  ),
                  const SizedBox(height: 16),

                  // Primary sector *
                  _buildLabel('Primary sector *'),
                  _buildDropdown(
                    value: _selectedPrimarySector,
                    items: _sectors,
                    onChanged: (val) => setState(() => _selectedPrimarySector = val!),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Row
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

                  // Village / ward *
                  _buildLabel('Village / ward *'),
                  _buildDropdown(
                    value: _selectedVillage,
                    items: _villages,
                    onChanged: (val) => setState(() => _selectedVillage = val),
                    validator: (val) => val == null ? 'Please select a village/ward' : null,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _isOutOfAreaVisit = val ?? false),
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

                  // Purpose of visit *
                  _buildLabel('Purpose of visit *'),
                  _buildTextFormField(
                    controller: _purposeController,
                    hint: 'Enter visit purpose',
                    validator: (val) => val == null || val.trim().isEmpty ? 'Purpose is mandatory' : null,
                  ),
                  const SizedBox(height: 16),

                  // Type of location *
                  _buildLabel('Type of location *'),
                  _buildDropdown(
                    value: _selectedLocationType,
                    items: _locationTypes,
                    onChanged: (val) => setState(() => _selectedLocationType = val),
                    validator: (val) => val == null ? 'Select location type' : null,
                  ),
                  const SizedBox(height: 16),

                  // Total visits *
                  _buildLabel('Total visits *'),
                  _buildTextFormField(
                    controller: _totalVisitsController,
                    hint: '1',
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Total visits is mandatory' : null,
                  ),
                  const SizedBox(height: 16),

                  // Human Population *
                  _buildLabel('Human Population *'),
                  _buildDropdown(
                    value: _selectedHumanPopulation,
                    items: _populationTypes,
                    onChanged: (val) => setState(() => _selectedHumanPopulation = val),
                    validator: (val) => val == null ? 'Select human population' : null,
                  ),
                  const SizedBox(height: 16),

                  // Human observations
                  _buildLabel('Human observations'),
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
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Immediate action taken
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
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Checkboxes List
                  _buildCheckboxRow(
                    label: 'Referral generated',
                    value: _isReferralGenerated,
                    onChanged: (val) => setState(() => _isReferralGenerated = val ?? false),
                  ),
                  const Divider(color: AppColors.divider, height: 1),

                  _buildCheckboxRow(
                    label: 'Alert generated',
                    value: _isAlertGenerated,
                    icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 18),
                    onChanged: (val) => setState(() => _isAlertGenerated = val ?? false),
                  ),
                  const Divider(color: AppColors.divider, height: 1),

                  _buildCheckboxRow(
                    label: 'Follow-up required',
                    value: _isFollowUpRequired,
                    onChanged: (val) => setState(() => _isFollowUpRequired = val ?? false),
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
                          onTap: _pickPhotograph,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Video',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Video recorder ready.')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDashedButton(
                          label: 'Document',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document selector ready.')),
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
                  const SizedBox(height: 12),

                  // Description / caption
                  _buildLabel('Description / caption'),
                  _buildTextFormField(
                    controller: _mediaCaptionController,
                    hint: '',
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
                          '$dateDisplay $timeDisplay · ${_selectedVillage ?? "Mannanur"} › Amrabad › Nagarkurnool › Telangana',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Submit event report',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
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

  // =========================================================================
  // REUSABLE FIELD BUILDERS
  // =========================================================================

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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
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
            Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            icon,
            const SizedBox(width: 6),
          ],
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
        currentIndex: 1, // Highlight 'Actions'
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
