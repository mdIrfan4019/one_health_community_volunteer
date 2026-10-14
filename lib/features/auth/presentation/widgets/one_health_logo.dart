import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OneHealthLogo extends StatelessWidget {
  final double size;

  const OneHealthLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.48,
          height: size * 0.48,
          child: CustomPaint(painter: _OneHealthSymbolPainter()),
        ),
      ),
    );
  }
}

class _OneHealthSymbolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final radius = size.width * 0.28;
    // Top circle (Human)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.28),
      radius,
      paint,
    );
    // Bottom-left circle (Animal)
    canvas.drawCircle(
      Offset(size.width * 0.28, size.height * 0.72),
      radius,
      paint,
    );
    // Bottom-right circle (Environment)
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.72),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
