// // Screen displaying full details of a specific Health Event Report
// // File: lib/features/events/presentation/screen/event_report_detail_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
//
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/widgets/authenticated_header.dart';
// import '../../../../core/widgets/attachments/attachments_section_widget.dart';
// import '../../data/event_api_service.dart';
// import '../../domain/event_models.dart';
//
// class EventReportDetailScreen extends StatefulWidget {
//   final EventReportItem event;
//   final String? volunteerId;
//   final VoidCallback? onBackToDashboard;
//
//   const EventReportDetailScreen({
//     super.key,
//     required this.event,
//     this.volunteerId,
//     this.onBackToDashboard,
//   });
//
//   @override
//   State<EventReportDetailScreen> createState() =>
//       _EventReportDetailScreenState();
// }
//
// class _EventReportDetailScreenState extends State<EventReportDetailScreen> {
//   late EventReportItem _event;
//   bool _isRefreshing = false;
//   final EventApiService _apiService = EventApiService();
//
//   final List<String> _months = const [
//     'Jan',
//     'Feb',
//     'Mar',
//     'Apr',
//     'May',
//     'Jun',
//     'Jul',
//     'Aug',
//     'Sep',
//     'Oct',
//     'Nov',
//     'Dec',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _event = widget.event;
//     _refreshIfPossible();
//   }
//
//   Future<void> _refreshIfPossible() async {
//     if (_event.numericId == null) return;
//     try {
//       final updated = await _apiService.fetchEventDetail(_event.numericId!);
//       if (updated != null && mounted) {
//         setState(() => _event = updated);
//       }
//     } catch (e) {
//       debugPrint('[EVENT_DETAIL] Error refreshing detail: $e');
//     }
//   }
//
//   Future<void> _manualRefresh() async {
//     setState(() => _isRefreshing = true);
//     await _refreshIfPossible();
//     if (mounted) {
//       setState(() => _isRefreshing = false);
//     }
//   }
//
//   String _formatDetailDateTime(DateTime dt) {
//     final monthStr = _months[dt.month - 1];
//     final hourStr = dt.hour.toString().padLeft(2, '0');
//     final minStr = dt.minute.toString().padLeft(2, '0');
//     return '${dt.day} $monthStr ${dt.year} · $hourStr:$minStr';
//   }
//
//   String _toTitleCase(String? val) {
//     if (val == null || val.trim().isEmpty) return '—';
//     final trimmed = val.trim();
//     if (trimmed.length == 1) return trimmed.toUpperCase();
//     return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
//   }
//
//   String _formatLocation() {
//     if (_event.latitude == null || _event.longitude == null) {
//       return '—';
//     }
//     final latStr = _event.latitude!.toStringAsFixed(6);
//     final lngStr = _event.longitude!.toStringAsFixed(6);
//     if (_event.gpsAccuracyM != null && _event.gpsAccuracyM! > 0) {
//       return '$latStr, $lngStr · ±${_event.gpsAccuracyM} m';
//     }
//     return '$latStr, $lngStr';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.light,
//         statusBarBrightness: Brightness.dark,
//       ),
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: AuthenticatedAppBar(
//           title: 'Event Report',
//           backgroundColor: const Color(0xFF136B4F),
//           volunteerId: widget.volunteerId ?? '',
//           onBackPressed: () {
//             if (widget.onBackToDashboard != null) {
//               widget.onBackToDashboard!();
//             } else {
//               Navigator.pop(context);
//             }
//           },
//         ),
//         body: _isRefreshing
//             ? const Center(
//                 child: CircularProgressIndicator(color: Color(0xFF136B4F)),
//               )
//             : RefreshIndicator(
//                 onRefresh: _manualRefresh,
//                 color: const Color(0xFF136B4F),
//                 child: SingleChildScrollView(
//                   physics: const AlwaysScrollableScrollPhysics(),
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // 1. Detail Card (Matches Prototype Exactly)
//                       _buildDetailCard(),
//
//                       const SizedBox(height: 16),
//
//                       // 2. Back Action Button
//                       _buildBackButton(),
//                     ],
//                   ),
//                 ),
//               ),
//         bottomNavigationBar: _buildBottomNavigationBar(),
//       ),
//     );
//   }
//
//   Widget _buildDetailCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.02),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Event Title
//           Text(
//             _event.eventType,
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textDark,
//               height: 1.25,
//             ),
//           ),
//           const SizedBox(height: 6),
//
//           // Code · Sector
//           RichText(
//             text: TextSpan(
//               style: const TextStyle(
//                 fontSize: 13.5,
//                 color: AppColors.textMuted,
//               ),
//               children: [
//                 TextSpan(
//                   text: _event.id,
//                   style: const TextStyle(
//                     color: Color(0xFF136B4F),
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 TextSpan(text: ' · ${_event.primarySector}'),
//               ],
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // 13 Detail Rows with Dividers
//           _buildRow('Date', _formatDetailDateTime(_event.eventDate)),
//           _buildRow('Village / ward', _event.village),
//           _buildRow(
//             'Purpose of visit',
//             _event.purposeOfVisit?.isNotEmpty == true
//                 ? _event.purposeOfVisit!
//                 : 'testing',
//           ),
//           _buildRow(
//             'Type of location',
//             _event.locationType?.isNotEmpty == true
//                 ? _toTitleCase(_event.locationType)
//                 : 'Urban',
//           ),
//           _buildRow('Total visits', '${_event.totalVisits}'),
//           _buildRow(
//             'Population',
//             _event.targetPopulation?.isNotEmpty == true
//                 ? _event.targetPopulation!
//                 : (_event.primarySector.toLowerCase().contains('animal')
//                       ? 'Livestock'
//                       : 'General population'),
//           ),
//           _buildRow(
//             'Description',
//             _event.description?.isNotEmpty == true
//                 ? _event.description!
//                 : 'testing',
//           ),
//           _buildRow(
//             'Observations',
//             _event.observations?.isNotEmpty == true
//                 ? _event.observations!
//                 : 'testing',
//           ),
//           _buildRow(
//             'Immediate action taken',
//             _event.actionTaken?.isNotEmpty == true
//                 ? _event.actionTaken!
//                 : 'testing',
//           ),
//           _buildRow(
//             'Referral generated',
//             _event.referralGenerated ? 'Yes' : 'No',
//           ),
//           _buildRow('Verification', _toTitleCase(_event.verificationStatus)),
//           _buildRow('Synchronisation', _toTitleCase(_event.status)),
//           _buildRow('Location', _formatLocation(), isLast: true),
//           const SizedBox(height: 14),
//           const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
//           const SizedBox(height: 14),
//           AttachmentsSectionWidget(
//             attachments: _event.attachments,
//             fallbackLatitude: _event.latitude,
//             fallbackLongitude: _event.longitude,
//             fallbackAccuracy: _event.gpsAccuracyM,
//             fallbackDate: _event.eventDate,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRow(String label, String value, {bool isLast = false}) {
//     return Column(
//       children: [
//         const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 13),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Label (Left Column)
//               Expanded(
//                 flex: 4,
//                 child: Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     color: Color(0xFF94A3B8),
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//
//               const SizedBox(width: 12),
//
//               // Value (Right Column)
//               Expanded(
//                 flex: 6,
//                 child: Text(
//                   value,
//                   textAlign: TextAlign.right,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: AppColors.textDark,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBackButton() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.02),
//             blurRadius: 6,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () => Navigator.pop(context),
//           child: const Padding(
//             padding: EdgeInsets.symmetric(vertical: 14),
//             child: Center(
//               child: Text(
//                 'Back',
//                 style: TextStyle(
//                   fontSize: 15.5,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFF136B4F),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: 1, // Highlight 'Actions'
//         onTap: (index) => Navigator.pop(context, index),
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: const Color(0xFF136B4F),
//         unselectedItemColor: AppColors.textLight,
//         selectedLabelStyle: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w600,
//         ),
//         unselectedLabelStyle: const TextStyle(fontSize: 11),
//         elevation: 0,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_rounded),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.grid_view_rounded),
//             label: 'Actions',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.article_outlined),
//             label: 'Reports',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline_rounded),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// Screen displaying full details of a specific Health Event Report
// File: lib/features/events/presentation/screen/event_report_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/authenticated_header.dart';
import '../../../../core/widgets/attachments/attachments_section_widget.dart';
import '../../data/event_api_service.dart';
import '../../domain/event_models.dart';

class EventReportDetailScreen extends StatefulWidget {
  final EventReportItem event;
  final String? volunteerId;
  final VoidCallback? onBackToDashboard;

  const EventReportDetailScreen({
    super.key,
    required this.event,
    this.volunteerId,
    this.onBackToDashboard,
  });

  @override
  State<EventReportDetailScreen> createState() =>
      _EventReportDetailScreenState();
}

class _EventReportDetailScreenState extends State<EventReportDetailScreen> {
  late EventReportItem _event;
  bool _isRefreshing = false;
  final EventApiService _apiService = EventApiService();

  final List<String> _months = const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _refreshIfPossible();
  }

  Future<void> _refreshIfPossible() async {
    if (_event.numericId == null) return;
    try {
      final updated = await _apiService.fetchEventDetail(_event.numericId!);
      if (updated != null && mounted) {
        setState(() => _event = updated);
      }
    } catch (e) {
      debugPrint('[EVENT_DETAIL] Error refreshing detail: $e');
    }
  }

  Future<void> _manualRefresh() async {
    setState(() => _isRefreshing = true);
    await _refreshIfPossible();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatDetailDateTime(DateTime dt) {
    final monthStr = _months[dt.month - 1];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $monthStr ${dt.year} · $hourStr:$minStr';
  }

  String _toTitleCase(String? val) {
    if (val == null || val.trim().isEmpty) return '—';
    final trimmed = val.trim();
    if (trimmed.length == 1) return trimmed.toUpperCase();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  String _formatLocation() {
    if (_event.latitude == null || _event.longitude == null) {
      return '—';
    }
    final latStr = _event.latitude!.toStringAsFixed(6);
    final lngStr = _event.longitude!.toStringAsFixed(6);
    if (_event.gpsAccuracyM != null && _event.gpsAccuracyM! > 0) {
      return '$latStr, $lngStr · ±${_event.gpsAccuracyM} m';
    }
    return '$latStr, $lngStr';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AuthenticatedAppBar(
          title: 'Event Report',
          backgroundColor: const Color(0xFF136B4F),
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        body: _isRefreshing
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF136B4F)),
              )
            : RefreshIndicator(
                onRefresh: _manualRefresh,
                color: const Color(0xFF136B4F),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Detail Card
                      _buildDetailCard(),

                      const SizedBox(height: 16),

                      // 2. Back Action Button
                      _buildBackButton(),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Title
          Text(
            _event.eventType,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Code · Sector
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textMuted,
              ),
              children: [
                TextSpan(
                  text: _event.id,
                  style: const TextStyle(
                    color: Color(0xFF136B4F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' · ${_event.primarySector}'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detail Rows with Dividers
          _buildRow('Date', _formatDetailDateTime(_event.eventDate)),
          _buildRow('Village / ward', _event.village),
          _buildRow(
            'Purpose of visit',
            _event.purposeOfVisit?.isNotEmpty == true
                ? _event.purposeOfVisit!
                : 'testing',
          ),
          _buildRow(
            'Type of location',
            _event.locationType?.isNotEmpty == true
                ? _toTitleCase(_event.locationType)
                : 'Urban',
          ),
          _buildRow('Total visits', '${_event.totalVisits}'),
          _buildRow(
            'Population',
            _event.targetPopulation?.isNotEmpty == true
                ? _event.targetPopulation!
                : (_event.primarySector.toLowerCase().contains('animal')
                      ? 'Livestock'
                      : 'General population'),
          ),
          _buildRow(
            'Description',
            _event.description?.isNotEmpty == true
                ? _event.description!
                : 'testing',
          ),
          _buildRow(
            'Observations',
            _event.observations?.isNotEmpty == true
                ? _event.observations!
                : 'testing',
          ),
          _buildRow(
            'Immediate action taken',
            _event.actionTaken?.isNotEmpty == true
                ? _event.actionTaken!
                : 'testing',
          ),
          _buildRow(
            'Referral generated',
            _event.referralGenerated ? 'Yes' : 'No',
          ),
          _buildRow('Alert generated', _event.isAlert ? 'Yes' : 'No'),
          _buildRow('Follow-up required', _event.isFollowUp ? 'Yes' : 'No'),
          _buildRow('Verification', _toTitleCase(_event.verificationStatus)),
          _buildRow('Synchronisation', _toTitleCase(_event.status)),
          _buildRow('Location', _formatLocation(), isLast: true),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Attachments
          AttachmentsSectionWidget(
            attachments: _event.attachments,
            fallbackLatitude: _event.latitude,
            fallbackLongitude: _event.longitude,
            fallbackAccuracy: _event.gpsAccuracyM,
            fallbackDate: _event.eventDate,
          ),

          // Render PROGRESS timeline if Alert was generated
          if (_event.isAlert) ...[_buildProgressSection()],
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final dateStr =
        '${_event.eventDate.day} ${_months[_event.eventDate.month - 1]} ${_event.eventDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 16),
        const Text(
          'PROGRESS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),

        // Timeline Container
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Node 1: COHV Step
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAB308), // Amber / Yellow
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COHV',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Vertical Connecting Amber Line
              Container(
                margin: const EdgeInsets.only(left: 5),
                width: 2,
                height: 22,
                color: const Color(0xFFEAB308),
              ),

              // Node 2: Supervisor & Relevant Department Branch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Supervisor Dot & Labels
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF136B4F), // Primary Green
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supervisor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF136B4F),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'alert raised',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Horizontal Branch line to Relevant Department
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 1.5,
                          color: const Color(0xFFCBD5E1),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Relevant Department',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                'not yet assigned',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Vertical Connecting Grey Line
              Container(
                margin: const EdgeInsets.only(left: 5),
                width: 2,
                height: 22,
                color: const Color(0xFFCBD5E1),
              ),

              // Node 3: Closed Step
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Closed',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label (Left Column)
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Value (Right Column)
              Expanded(
                flex: 6,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF136B4F),
                ),
              ),
            ),
          ),
        ),
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
        selectedItemColor: const Color(0xFF136B4F),
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
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
