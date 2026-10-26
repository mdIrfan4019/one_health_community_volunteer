import 'package:flutter/material.dart';
import 'package:cohv/features/dashboard/domain/department_config.dart';

/// Reusable Quick Actions "YOUR FIELD TOOLKIT" Hero Card featuring:
/// - Department-specific intro title (e.g. "People first", "Stronger villages", etc.)
/// - Department-specific description
/// - Dynamic department icon in badge container
/// - Field status indicators and toolkit aesthetic
class QuickActionsHeroCard extends StatelessWidget {
  final DepartmentConfig departmentConfig;
  final VoidCallback? onStarTap;

  const QuickActionsHeroCard({
    super.key,
    required this.departmentConfig,
    this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF136B4F),
            Color(0xFF197653),
            Color(0xFF0F563D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF136B4F).withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background organic curves and concentric arcs
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: const _ToolkitCardBackgroundPainter(),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top line: Label + Star/Sparkle icon button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'YOUR FIELD TOOLKIT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    GestureDetector(
                      onTap: onStarTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.flare_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Main Heading + Dynamic Department Icon Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            departmentConfig.quickActionsIntroTitle,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            departmentConfig.quickActionsDescription,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          departmentConfig.icon,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Bottom Line: Active Dot + "Ready when you are" + Arrow down
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ready when you are',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.south_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolkitCardBackgroundPainter extends CustomPainter {
  const _ToolkitCardBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 36;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, -20);
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width + 20,
      size.height * 0.25,
    );
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Bottom right concentric arcs
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 1.05),
      size.width * 0.24,
      paint2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 1.05),
      size.width * 0.42,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
