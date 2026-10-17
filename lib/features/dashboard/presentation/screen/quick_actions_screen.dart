// // Create file: lib/features/dashboard/presentation/screen/quick_actions_screen.dart
//
// import 'package:flutter/material.dart';
// import '../../../../core/theme/app_colors.dart';
// import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';
// import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
// import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';
//
// class QuickActionsScreen extends StatelessWidget {
//   const QuickActionsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       child: GridView.count(
//         crossAxisCount: 2,
//         crossAxisSpacing: 14,
//         mainAxisSpacing: 14,
//         childAspectRatio: 0.88, // Tall card proportion matching prototype
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         children: [
//           // 1. Report Event (Warm Cream/Peach)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFFFF7ED),
//             icon: const Icon(
//               Icons.warning_amber_rounded,
//               color: Color(0xFFEA580C),
//               size: 52,
//             ),
//              title: 'Report Event',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const EventReportingScreen(volunteerId: 'COHV-26-0001'),
//                 ),
//               );
//             },
//
//           ),
//
//           // // 2. Referral (Soft Lavender/Rose)
//           // _buildActionCard(
//           //   context: context,
//           //   backgroundColor: const Color(0xFFFDF2F8),
//           //   icon: Row(
//           //     mainAxisSize: MainAxisSize.min,
//           //     mainAxisAlignment: MainAxisAlignment.center,
//           //     children: [
//           //       const Icon(
//           //         Icons.arrow_forward_rounded,
//           //         color: Color(0xFF9D174D), // Burgundy arrow
//           //         size: 26,
//           //       ),
//           //       const SizedBox(width: 4),
//           //       Container(
//           //         padding: const EdgeInsets.all(6),
//           //         decoration: BoxDecoration(
//           //           color: const Color(0xFF38BDF8), // Blue clinic badge
//           //           borderRadius: BorderRadius.circular(8),
//           //         ),
//           //         child: const Icon(
//           //           Icons.add,
//           //           color: Colors.white,
//           //           size: 22,
//           //         ),
//           //       ),
//           //     ],
//           //   ),
//           //   title: 'Referral',
//           //   onTap: () {
//           //     ScaffoldMessenger.of(context).showSnackBar(
//           //       const SnackBar(content: Text('Inter-Sectoral Referral Engine (REF) ready.')),
//           //     );
//           //   },
//           // ),
//
//                     // 2. Referral (Soft Lavender/Rose)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFFDF2F8),
//             icon: Row(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.arrow_forward_rounded,
//                   color: Color(0xFF9D174D), // Burgundy arrow
//                   size: 26,
//                 ),
//                 const SizedBox(width: 4),
//                 Container(
//                   padding: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF38BDF8), // Blue clinic badge
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: const Icon(
//                     Icons.add,
//                     color: Colors.white,
//                     size: 22,
//                   ),
//                 ),
//               ],
//             ),
//             title: 'Referral',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const ReferralsListScreen(volunteerId: 'COHV-26-0001'),
//                 ),
//               );
//             },
//           ),
//
//
//           // 3. Awareness Activity (Pale Yellow)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFFFFBEB),
//             icon: const Icon(
//               Icons.campaign_rounded,
//               color: Color(0xFFF59E0B),
//               size: 52,
//             ),
//             title: 'Awareness Activity',
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const AwarenessListScreen(volunteerId: 'COHV-26-0001'),
//                 ),
//               );
//             },
//           ),
//
//
//           // 4. Sample Support (Soft Ice Blue)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFF0F9FF),
//             icon: const Icon(
//               Icons.science_rounded,
//               color: Color(0xFF6366F1),
//               size: 50,
//             ),
//             title: 'Sample Support',
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Sample Collection Support (SMP) ready.')),
//               );
//             },
//           ),
//
//           // 5. Capacity Building (Soft Lavender)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFF5F3FF),
//             icon: const Icon(
//               Icons.school_rounded,
//               color: Color(0xFF8B5CF6),
//               size: 52,
//             ),
//             title: 'Capacity Building',
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Training Attended/Imparted (TRN/TRI) ready.')),
//               );
//             },
//           ),
//
//           // 6. Success Stories (Soft Blush Pink)
//           _buildActionCard(
//             context: context,
//             backgroundColor: const Color(0xFFFFF1F2),
//             icon: const Icon(
//               Icons.star_rounded,
//               color: Color(0xFFA3546B), // Brand Rose accent
//               size: 54,
//             ),
//             title: 'Success Stories',
//             onTap: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Success Stories & Innovation (STY) ready.')),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildActionCard({
//     required BuildContext context,
//     required Color backgroundColor,
//     required Widget icon,
//     required String title,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(22),
//       child: Container(
//         decoration: BoxDecoration(
//           color: backgroundColor,
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(
//             color: Colors.black.withValues(alpha: 0.04),
//             width: 1,
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Module Icon
//             Container(
//               height: 60,
//               alignment: Alignment.center,
//               child: icon,
//             ),
//             const SizedBox(height: 14),
//
//             // Module Title
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 14.5,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textDark,
//                   letterSpacing: -0.2,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

import 'package:cohv/features/events/presentation/screen/event_reporting_screen.dart';
import 'package:cohv/features/referrals/presentation/screen/referrals_list_screen.dart';
import 'package:cohv/features/awareness/presentation/screen/awareness_list_screen.dart';

class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.88,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 1. Report Event (Orange Warning Triangle)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFF7ED),
            icon: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFF97316),
              size: 54,
            ),
            title: 'Report Event',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const EventReportingScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },
          ),

          // 2. Referral (Burgundy Arrow + Blue Health Card)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFDF2F8),
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF9D174D),
                  size: 26,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 12,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            title: 'Referral',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ReferralsListScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },
          ),

          // 3. Awareness Activity (Megaphone + Sound Waves)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFF7ED),
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFF97316),
                  size: 48,
                ),
                Transform.translate(
                  offset: const Offset(-6, 0),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Color(0xFFF472B6),
                    size: 20,
                  ),
                ),
              ],
            ),
            title: 'Awareness Activity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AwarenessListScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },
          ),

          // 4. Sample Support (Test Tube)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFEFF6FF),
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Yellow Cap
                Container(
                  width: 18,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 1),

                // Tube Body
                Container(
                  width: 14,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF818CF8),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 3,
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 22,
                        right: 3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            title: 'Sample Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sample Collection Support (SMP) ready.'),
                ),
              );
            },
          ),

          // 5. Capacity Building (Graduation Cap)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFF5F3FF),
            icon: const Icon(
              Icons.school_rounded,
              color: Color(0xFF818CF8),
              size: 54,
            ),
            title: 'Capacity Building',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Training Attended/Imparted (TRN/TRI) ready.'),
                ),
              );
            },
          ),

          // 6. Success Stories (Pink Star)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFF1F2),
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF472B6),
                  size: 46,
                ),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDA4AF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            title: 'Success Stories',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Success Stories & Innovation (STY) ready.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required Color backgroundColor,
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Module Icon
            Container(height: 60, alignment: Alignment.center, child: icon),
            const SizedBox(height: 12),

            // Module Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
