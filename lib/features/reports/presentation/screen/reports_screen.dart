// Create file: lib/features/reports/presentation/screen/reports_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/storage/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reports_api_service.dart';
import '../../domain/report_models.dart';

class ReportsScreen extends StatefulWidget {
  final String userEmail;

  const ReportsScreen({
    super.key,
    this.userEmail = '',
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportsApiService _apiService = ReportsApiService();

  DateTime? _fromDate;
  DateTime _toDate = DateTime.now();
  bool _isLoading = false;

  List<ReportItem> _requestedReports = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final volunteerId = await SessionManager.getVolunteerId() ?? '';
      final history = await _apiService.getReportHistory(volunteerId);
      if (mounted) {
        setState(() => _requestedReports = history);
      }
    } catch (_) {}
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF136B4F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _handleSendReport() async {
    if (_fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please select "From date".'),
        ),
      );
      return;
    }

    if (_fromDate!.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('"From date" cannot be after "To date".'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = ReportRequest(
        fromDate: _fromDate!,
        toDate: _toDate,
        email: widget.userEmail,
      );

      final newItem = await _apiService.requestReport(request);

      if (!mounted) return;

      setState(() {
        _requestedReports.insert(0, newItem);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Report generated and sent to ${widget.userEmail}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Report Request Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date pickers row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: 'From date *',
                        displayValue: _fromDate == null
                            ? 'dd/mm/yyyy'
                            : '${_fromDate!.day.toString().padLeft(2, '0')}/${_fromDate!.month.toString().padLeft(2, '0')}/${_fromDate!.year}',
                        onTap: _pickFromDate,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildDateField(
                        label: 'To date *',
                        displayValue: '${_toDate.day.toString().padLeft(2, '0')}/${_toDate.month.toString().padLeft(2, '0')}/${_toDate.year}',
                        onTap: _pickToDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // "Send to" destination row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Send to',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        widget.userEmail,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.divider, height: 20),
                const SizedBox(height: 10),

                // "Send report on email" Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF136B4F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Send report on email',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Requested Reports History Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requested',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                if (_requestedReports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No reports requested yet.',
                      style: TextStyle(fontSize: 13, color: AppColors.textLight),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _requestedReports.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: AppColors.divider,
                      height: 24,
                    ),
                    itemBuilder: (context, index) {
                      final item = _requestedReports[index];
                      return _buildReportItem(item);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String displayValue,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: displayValue == 'dd/mm/yyyy' || displayValue == 'dd-mm-yyyy'
                        ? AppColors.textLight
                        : AppColors.textDark,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    if (text.contains('*')) {
      final parts = text.split('*');
      return Text.rich(
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
                color: Color(0xFF136B4F),
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildReportItem(ReportItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Date Range
            Text(
              '${_formatDate(item.fromDate)} – ${_formatDate(item.toDate)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),

            // Sent Status Pill Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EB), // Soft mint green
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  color: Color(0xFF39845A), // Forest green
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Identifier & Recipient
        Row(
          children: [
            Text(
              item.reportId,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF136B4F),
              ),
            ),
            const Text(
              ' · ',
              style: TextStyle(color: AppColors.textLight, fontSize: 12),
            ),
            Text(
              item.email,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
