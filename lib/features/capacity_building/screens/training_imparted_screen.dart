import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import '../domain/capacity_building_models.dart';
import '../data/capacity_building_api_service.dart';
import 'new_training_screen.dart';
import 'training_imparted_detail_screen.dart';

import 'package:cohv/core/theme/app_colors.dart';

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

      // Compact New Training button.
      // No unsupported constraints parameter is used.
      floatingActionButton: SizedBox(
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    NewTrainingScreen(volunteerId: widget.volunteerId),
              ),
            );

            if (result == true) {
              _loadRecords();
            }
          },
          backgroundColor: const Color(0xFF16816A),
          foregroundColor: Colors.white,
          elevation: 4,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'New Training',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
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
                style: const TextStyle(color: capacityMuted, fontSize: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: capacityText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "New Training" below to record a training.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: capacityMuted),
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
                    fontWeight: FontWeight.w500,
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

// class _TrainingCard extends StatelessWidget {
//   final TrainingImpartedRecordModel record;
//   final VoidCallback onTap;
//
//   const _TrainingCard({required this.record, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     final org = record.organisedBy?.isNotEmpty == true
//         ? record.organisedBy!
//         : 'Organizer N/A';
//
//     final dur = record.duration?.isNotEmpty == true
//         ? record.duration!
//         : 'Duration N/A';
//
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(18),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: capacityBorder),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Slimmer accent bar.
//             Container(
//               width: 4,
//               height: 82,
//               decoration: BoxDecoration(
//                 color: const Color(0xFF6395B8),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Smaller training title.
//                   Text(
//                     record.trainingName,
//                     style: const TextStyle(
//                       color: capacityText,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       height: 1.3,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Status and training code/date on the same row.
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       _StatusChip(status: record.verificationStatus),
//
//                       const SizedBox(width: 8),
//
//                       Expanded(
//                         child: Text(
//                           '${record.trainingImpartedCode} · ${record.displayDate}',
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                             color: Color(0xFF6D9185),
//                             fontSize: 12,
//                             fontWeight: FontWeight.w400,
//                             height: 1.3,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 6),
//
//                   // Organizer and duration in smaller text.
//                   Text(
//                     '$org · $dur',
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: const TextStyle(
//                       color: capacityMuted,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w400,
//                       height: 1.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 4),
//
//             const Icon(Icons.chevron_right, color: capacityMuted, size: 22),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical blue accent bar matching the Referrals card
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Title and status badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              record.trainingName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(record.verificationStatus),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Row 2: ID and date
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(
                              text: record.trainingImpartedCode,
                              style: const TextStyle(
                                color: Color(0xFF136B4F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' · ${record.displayDate}'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 3),

                      // Row 3: Organizer and duration
                      Text(
                        '$org · $dur',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class _StatusChip extends StatelessWidget {
// final String status;
//
// const _StatusChip({
// required this.status,
// });
//
// @override
// Widget build(BuildContext context) {
// final lower = status.toLowerCase();
//
// Color bg = const Color(0xFFF0EFF3);
// Color textColor = capacityMuted;
//
// if (lower.contains('submitted') || lower.contains('pending')) {
// bg = const Color(0xFFFFF3E0);
// textColor = const Color(0xFFE65100);
// } else if (lower.contains('verified') ||
// lower.contains('approved')) {
// bg = const Color(0xFFE8F5E9);
// textColor = const Color(0xFF2E7D32);
// } else if (lower.contains('rejected')) {
// bg = const Color(0xFFFFEBEE);
// textColor = const Color(0xFFC62828);
// }
//
// return Container(
// padding: const EdgeInsets.symmetric(
// horizontal: 8,
// vertical: 3,
// ),
// decoration: BoxDecoration(
// color: bg,
// borderRadius: BorderRadius.circular(7),
// ),
// child: Text(
// status.toLowerCase(),
// style: TextStyle(
// color: textColor,
// fontSize: 11,
// fontWeight: FontWeight.w600,
// ),
// ),
// );
// }
// }

Widget _buildStatusBadge(String status) {
  final lower = status.toLowerCase();

  final isPending = lower.contains('pending') || lower.contains('offline');

  final bg = isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7);

  final text = isPending ? const Color(0xFFD97706) : const Color(0xFF15803D);

  final label = isPending
      ? 'pending'
      : (lower == 'submitted' ? 'synced' : lower);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}
