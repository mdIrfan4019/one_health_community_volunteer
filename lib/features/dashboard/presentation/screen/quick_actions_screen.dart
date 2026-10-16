// Create file: lib/features/dashboard/presentation/screen/quick_actions_screen.dart

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
        childAspectRatio: 0.88, // Tall card proportion matching prototype
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 1. Report Event (Warm Cream/Peach)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFF7ED),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEA580C),
              size: 52,
            ),
             title: 'Report Event',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventReportingScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },

          ),

          // // 2. Referral (Soft Lavender/Rose)
          // _buildActionCard(
          //   context: context,
          //   backgroundColor: const Color(0xFFFDF2F8),
          //   icon: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Icon(
          //         Icons.arrow_forward_rounded,
          //         color: Color(0xFF9D174D), // Burgundy arrow
          //         size: 26,
          //       ),
          //       const SizedBox(width: 4),
          //       Container(
          //         padding: const EdgeInsets.all(6),
          //         decoration: BoxDecoration(
          //           color: const Color(0xFF38BDF8), // Blue clinic badge
          //           borderRadius: BorderRadius.circular(8),
          //         ),
          //         child: const Icon(
          //           Icons.add,
          //           color: Colors.white,
          //           size: 22,
          //         ),
          //       ),
          //     ],
          //   ),
          //   title: 'Referral',
          //   onTap: () {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       const SnackBar(content: Text('Inter-Sectoral Referral Engine (REF) ready.')),
          //     );
          //   },
          // ),

                    // 2. Referral (Soft Lavender/Rose)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFDF2F8),
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF9D174D), // Burgundy arrow
                  size: 26,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8), // Blue clinic badge
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
            title: 'Referral',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReferralsListScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },
          ),


          // 3. Awareness Activity (Pale Yellow)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFFBEB),
            icon: const Icon(
              Icons.campaign_rounded,
              color: Color(0xFFF59E0B),
              size: 52,
            ),
            title: 'Awareness Activity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AwarenessListScreen(volunteerId: 'COHV-26-0001'),
                ),
              );
            },
          ),


          // 4. Sample Support (Soft Ice Blue)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFF0F9FF),
            icon: const Icon(
              Icons.science_rounded,
              color: Color(0xFF6366F1),
              size: 50,
            ),
            title: 'Sample Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sample Collection Support (SMP) ready.')),
              );
            },
          ),

          // 5. Capacity Building (Soft Lavender)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFF5F3FF),
            icon: const Icon(
              Icons.school_rounded,
              color: Color(0xFF8B5CF6),
              size: 52,
            ),
            title: 'Capacity Building',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Training Attended/Imparted (TRN/TRI) ready.')),
              );
            },
          ),

          // 6. Success Stories (Soft Blush Pink)
          _buildActionCard(
            context: context,
            backgroundColor: const Color(0xFFFFF1F2),
            icon: const Icon(
              Icons.star_rounded,
              color: Color(0xFFA3546B), // Brand Rose accent
              size: 54,
            ),
            title: 'Success Stories',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Success Stories & Innovation (STY) ready.')),
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
            Container(
              height: 60,
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 14),

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
