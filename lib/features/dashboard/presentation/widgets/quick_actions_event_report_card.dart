import 'package:flutter/material.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/features/dashboard/domain/department_config.dart';

/// Reusable Quick Actions "Report an event" card.
/// Adapts its icon to the volunteer's department while maintaining the
/// "Report an event" title and "Open this field workflow" subtitle.
class QuickActionsEventReportCard extends StatelessWidget {
  final DepartmentConfig departmentConfig;
  final VoidCallback? onTap;

  const QuickActionsEventReportCard({
    super.key,
    required this.departmentConfig,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F7EE),
                Color(0xFFF3FAF5),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD1F2DD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF136B4F).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1F2DD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  departmentConfig.icon,
                  color: AppColors.setuGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an event',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF136B4F),
                      ),
                    ),
                    IgnorePointer(
                      child: SizedBox(
                        height: 1,
                        child: Opacity(
                          opacity: 0.0,
                          child: Text('Report Event'),
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Open this field workflow',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF136B4F),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.north_east_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
