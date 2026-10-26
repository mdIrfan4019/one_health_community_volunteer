import 'package:flutter/material.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/features/dashboard/domain/department_config.dart';

/// Reusable Dashboard "Report an event" card.
/// Adapts its icon to the volunteer's department while maintaining the
/// "Report an event" title and "Capture a field observation" subtitle.
class DashboardEventReportCard extends StatelessWidget {
  final DepartmentConfig departmentConfig;
  final VoidCallback? onTap;

  const DashboardEventReportCard({
    super.key,
    required this.departmentConfig,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  departmentConfig.icon,
                  color: AppColors.setuGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an event',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Capture a field observation',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.north_east_rounded,
                color: AppColors.setuGreen,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
