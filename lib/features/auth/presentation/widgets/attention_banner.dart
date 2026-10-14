import 'package:flutter/material.dart';

class AttentionBanner extends StatelessWidget {
  final List<String> errors;

  const AttentionBanner({
    super.key,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();

    final countText = '${errors.length} item(s) need attention';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F1), // Warm pale amber/cream background
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFEDD5), // Subtle outer border
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Left Amber/Orange solid accent strip (Section 8 Amber-to-Orange ramp)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4.5,
              decoration: const BoxDecoration(
                color: Color(0xFFEA580C), // Spec Amber-to-Orange ramp
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
          ),
          // Banner Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                ...errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(top: 2, left: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                            height: 1.3,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
