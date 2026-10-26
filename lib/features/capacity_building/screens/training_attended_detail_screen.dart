import 'package:flutter/material.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';

const Color attendedGreen = Color(0xFF176B57);
const Color attendedBackground = Color(0xFFF2F7F5);
const Color attendedBorder = Color(0xFFDCE6E2);
const Color attendedMuted = Color(0xFF81918B);

class TrainingAttendedDetailScreen extends StatefulWidget {
  final TrainingAttendedRecordModel? record;
  final int? trainingAttendedId;

  const TrainingAttendedDetailScreen({
    super.key,
    this.record,
    this.trainingAttendedId,
  });

  @override
  State<TrainingAttendedDetailScreen> createState() =>
      _TrainingAttendedDetailScreenState();
}

class _TrainingAttendedDetailScreenState
    extends State<TrainingAttendedDetailScreen> {
  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  TrainingAttendedRecordModel? _record;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    if (_record == null && widget.trainingAttendedId != null) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _apiService.fetchTrainingAttendedDetail(
        widget.trainingAttendedId!,
      );
      if (!mounted) return;
      setState(() {
        _record = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: attendedBackground,
      appBar: AppBar(
        backgroundColor: attendedGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Training Attended',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _headerButton(icon: Icons.notifications, badge: '4', onTap: () {}),
          _headerButton(icon: Icons.sync, badge: '1', onTap: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: attendedGreen),
      );
    }

    if (_errorMessage != null && _record == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: attendedMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: attendedGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final record = _record;
    if (record == null) {
      return const Center(
        child: Text(
          'No record found.',
          style: TextStyle(color: attendedMuted, fontSize: 15),
        ),
      );
    }

    final venue = record.venue?.isNotEmpty == true ? record.venue! : '—';
    final chaired = record.chairedBy?.isNotEmpty == true
        ? record.chairedBy!
        : '—';
    final points = record.keyPoints?.isNotEmpty == true
        ? record.keyPoints!
        : '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: attendedBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.trainingName,
                  style: const TextStyle(
                    fontSize: 21,
                    height: 1.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF20372F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  record.trainingAttendedCode,
                  style: const TextStyle(
                    color: attendedGreen,
                    fontSize: 16,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 28),

                _detailRow('Training', record.trainingName),
                _detailRow('Date', record.displayDate),
                _detailRow('Venue', venue),
                _detailRow('Chaired by', chaired),
                _detailRow('Key points / action agreed', points),
                _detailRow(
                  'Certificate issued',
                  record.certificateIssued ? 'Yes' : 'No',
                ),
                _detailRow('Verification', record.verificationStatus),
                _detailRow(
                  'Synchronisation',
                  'Synced',
                  isLast: true,
                ),

                const SizedBox(height: 16),
                const Divider(color: attendedBorder, height: 1, thickness: 1),
                const SizedBox(height: 16),

                AttachmentsSectionWidget(
                  attachments: record.appAttachments,
                  fallbackDate: DateTime.tryParse(record.capturedAt ?? record.trainingDate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: attendedGreen,
                backgroundColor: Colors.white,
                side: const BorderSide(color: attendedBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 25),
              if (badge != null)
                Positioned(
                  top: -5,
                  right: -4,
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

  Widget _detailRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: attendedBorder, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(color: attendedMuted, fontSize: 15),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF20372F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
