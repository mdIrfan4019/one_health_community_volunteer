import 'package:flutter/material.dart';
import 'package:cohv/features/capacity_building/screens/new_training_attended_screen.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'training_attended_detail_screen.dart';

const Color capacityGreen = Color(0xFF176B57);
const Color capacityBackground = Color(0xFFF3F8F6);
const Color capacityBorder = Color(0xFFDCE8E2);
const Color capacityMuted = Color(0xFF80918B);
const Color capacityText = Color(0xFF243832);

class TrainingAttendedScreen extends StatefulWidget {
  const TrainingAttendedScreen({super.key});

  @override
  State<TrainingAttendedScreen> createState() => _TrainingAttendedScreenState();
}

class _TrainingAttendedScreenState extends State<TrainingAttendedScreen> {
  final CapacityBuildingApiService _apiService = CapacityBuildingApiService();
  List<TrainingAttendedRecordModel> _records = [];
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
      final records = await _apiService.fetchTrainingAttendedList();
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

  void _openNewTraining(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewTrainingAttendedScreen()),
    );
    if (result == true) {
      _loadRecords();
    }
  }

  void _openDetails(BuildContext context, TrainingAttendedRecordModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingAttendedDetailScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: capacityBackground,
      appBar: AppBar(
        backgroundColor: capacityGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Training Attended',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          _headerButton(icon: Icons.notifications, badge: '5', onTap: () {}),
          _headerButton(icon: Icons.sync, badge: '1', onTap: () {}),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewTraining(context),
        backgroundColor: const Color(0xFF16836B),
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        icon: const Icon(Icons.add, size: 30),
        label: const Text(
          'New Training',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                    'No training attended recorded yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: capacityText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "New Training" below to record attendance.',
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
          return _TrainingAttendedCard(
            record: record,
            onTap: () => _openDetails(context, record),
          );
        },
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

  Widget _bottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: capacityBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavIcon(icon: Icons.home, label: 'Dashboard'),
              _NavIcon(icon: Icons.grid_view_rounded, label: 'Actions'),
              _NavIcon(icon: Icons.article_outlined, label: 'Reports'),
              _NavIcon(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingAttendedCard extends StatelessWidget {
  final TrainingAttendedRecordModel record;
  final VoidCallback onTap;

  const _TrainingAttendedCard({required this.record, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final venue = record.venue?.isNotEmpty == true
        ? record.venue!
        : 'Venue N/A';
    final chaired = record.chairedBy?.isNotEmpty == true
        ? record.chairedBy!
        : 'Chair N/A';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: capacityBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF6B9CB5),
                borderRadius: BorderRadius.circular(3),
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
                      color: capacityText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusChip(status: record.verificationStatus),
                  const SizedBox(height: 8),
                  Text(
                    '${record.trainingAttendedCode} · ${record.displayDate}',
                    style: const TextStyle(color: capacityGreen, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$venue · $chaired',
                    style: const TextStyle(color: capacityMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: capacityMuted),
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

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NavIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: capacityMuted, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: capacityMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
