import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'package:cohv/core/widgets/attachments/attachments_section_widget.dart';

const Color trainingGreen = Color(0xFF176B57);
const Color trainingBackground = Color(0xFFF3F8F6);
const Color trainingBorder = Color(0xFFDDE7E2);
const Color trainingMuted = Color(0xFF82918C);
const Color trainingText = Color(0xFF203730);

class TrainingImpartedDetailScreen extends StatefulWidget {
  final TrainingImpartedRecordModel? record;
  final int? trainingImpartedId;
  final String? volunteerId;

  const TrainingImpartedDetailScreen({
    super.key,
    this.record,
    this.trainingImpartedId,
    this.volunteerId,
  });

  @override
  State<TrainingImpartedDetailScreen> createState() =>
      _TrainingImpartedDetailScreenState();
}

class _TrainingImpartedDetailScreenState
    extends State<TrainingImpartedDetailScreen> {
  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  TrainingImpartedRecordModel? _record;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    if (_record == null && widget.trainingImpartedId != null) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await _apiService.fetchTrainingImpartedDetail(
        widget.trainingImpartedId!,
      );
      if (!mounted) return;
      setState(() {
        _record = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load training details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: trainingBackground,
      appBar: AuthenticatedAppBar(
        title: 'Training Imparted',
        backgroundColor: trainingGreen,
        volunteerId: widget.volunteerId ?? '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: trainingGreen),
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
                style: const TextStyle(color: trainingMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: trainingGreen,
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
          style: TextStyle(color: trainingMuted, fontSize: 15),
        ),
      );
    }

    final org = record.organisedBy?.isNotEmpty == true
        ? record.organisedBy!
        : 'Not specified';
    final dur = record.duration?.isNotEmpty == true
        ? record.duration!
        : 'Not specified';
    final rem = record.remarks?.isNotEmpty == true ? record.remarks! : 'None';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: trainingBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Training title
                Text(
                  record.trainingName,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                    color: trainingText,
                  ),
                ),

                const SizedBox(height: 12),

                // Training ID
                Text(
                  record.trainingImpartedCode,
                  style: const TextStyle(
                    fontSize: 15,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: trainingGreen,
                  ),
                ),

                const SizedBox(height: 26),

                // Training details
                _detailRow(
                  label: 'Training',
                  value: record.trainingName,
                  isFirst: true,
                ),

                _detailRow(label: 'Date', value: record.displayDate),

                _detailRow(label: 'Organised by', value: org),

                _detailRow(label: 'Duration', value: dur),

                _detailRow(label: 'Remarks', value: rem),

                _detailRow(
                  label: 'Verification',
                  value: record.verificationStatus,
                ),

                _detailRow(
                  label: 'Synchronisation',
                  value: 'Synced',
                  isLast: true,
                ),

                const SizedBox(height: 16),
                const Divider(color: trainingBorder, height: 1, thickness: 1),
                const SizedBox(height: 16),

                AttachmentsSectionWidget(
                  attachments: record.appAttachments,
                  fallbackDate: DateTime.tryParse(record.capturedAt ?? record.trainingDate),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Back button
          SizedBox(
            height: 64,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: trainingGreen,
                side: const BorderSide(color: trainingBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Individual detail row
  static Widget _detailRow({
    required String label,
    required String value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: trainingBorder, width: isFirst ? 0 : 1.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: trainingMuted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: trainingText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom navigation bar
  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: trainingBorder)),
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
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 25, color: trainingMuted),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trainingMuted,
            ),
          ),
        ],
      ),
    );
  }
}
