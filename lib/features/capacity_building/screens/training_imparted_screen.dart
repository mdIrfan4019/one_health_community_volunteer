import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'new_training_screen.dart';
import 'training_imparted_detail_screen.dart';

const Color capacityGreen = Color(0xFF176B57);
const Color capacityBackground = Color(0xFFF3F8F6);
const Color capacityBorder = Color(0xFFDCE8E2);
const Color capacityMuted = Color(0xFF80918B);
const Color capacityText = Color(0xFF243832);

class TrainingImpartedScreen extends StatefulWidget {
  final String? volunteerId;

  const TrainingImpartedScreen({super.key, this.volunteerId});

  @override
  State<TrainingImpartedScreen> createState() => _TrainingImpartedScreenState();
}

class _TrainingImpartedScreenState extends State<TrainingImpartedScreen> {
  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingImpartedRecordModel> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _apiService.fetchTrainingImpartedList();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load records: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: capacityBackground,
      appBar: AuthenticatedAppBar(
        title: 'Training Imparted',
        backgroundColor: capacityGreen,
        volunteerId: widget.volunteerId ?? '',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF16816A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Training',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => NewTrainingScreen(
                volunteerId: widget.volunteerId,
              ),
            ),
          );

          if (result == true) {
            _loadRecords();
          }
        },
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: capacityGreen),
      );
    }

    if (_errorMessage != null && _records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 54,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: capacityMuted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecords,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: capacityGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRecords,
        color: capacityGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: capacityMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No training imparted records yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: capacityText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "New Training" below to record a training.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: capacityMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      color: capacityGreen,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final record = _records[index];
          return _TrainingCard(
            record: record,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrainingImpartedDetailScreen(
                    record: record,
                    volunteerId: widget.volunteerId,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _bottomNavigation() {
    const items = [
      [Icons.home, 'Dashboard'],
      [Icons.grid_view_rounded, 'Actions'],
      [Icons.article, 'Reports'],
      [Icons.person, 'Profile'],
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item[0] as IconData,
                  color: const Color(0xFF80918B),
                  size: 24,
                ),
                const SizedBox(height: 5),
                Text(
                  item[1] as String,
                  style: const TextStyle(
                    color: Color(0xFF80918B),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  final TrainingImpartedRecordModel record;
  final VoidCallback onTap;

  const _TrainingCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final org = record.organisedBy?.isNotEmpty == true
        ? record.organisedBy!
        : 'Organizer N/A';
    final dur = record.duration?.isNotEmpty == true
        ? record.duration!
        : 'Duration N/A';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE8E2)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF6395B8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.trainingName,
                    style: const TextStyle(
                      color: Color(0xFF243832),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusChip(status: record.verificationStatus),
                  const SizedBox(height: 8),
                  Text(
                    '${record.trainingImpartedCode} · ${record.displayDate}',
                    style: const TextStyle(
                      color: Color(0xFF6D9185),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$org · $dur',
                    style: const TextStyle(
                      color: Color(0xFF80918B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF80918B)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final lower = status.toLowerCase();
    Color bg = const Color(0xFFF0EFF3);
    Color textColor = const Color(0xFF80918B);

    if (lower.contains('submitted') || lower.contains('pending')) {
      bg = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
    } else if (lower.contains('verified') || lower.contains('approved')) {
      bg = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else if (lower.contains('rejected')) {
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        status.toLowerCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
