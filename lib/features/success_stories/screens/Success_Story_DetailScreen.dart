
import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

const Color storyPink = Color(0xFFB85C78);
const Color storyBackground = Color(0xFFF6F3F7);
const Color storyMuted = Color(0xFF8D8793);
const Color storyBorder = Color(0xFFE8E1E9);

class SuccessStoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> story;

  const SuccessStoryDetailScreen({
    super.key,
    required this.story,
  });

  String _value(String key) {
    final value = story[key];
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not provided';
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final status = _value('status');

    return Scaffold(
      backgroundColor: storyBackground,
      appBar: AuthenticatedAppBar(
        title: 'Success Story Details',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStoryHeader(),
              const SizedBox(height: 18),

              _buildSection(
                title: 'General Information',
                icon: Icons.info_outline,
                children: [
                  _buildDetailRow('Story ID', _value('id')),
                  _buildDetailRow('Story Title', _value('title')),
                  _buildDetailRow('Date', _value('date')),
                  _buildDetailRow('Location', _value('location')),
                  _buildDetailRow('Category', _value('category')),
                  _buildDetailRow(
                    'Innovation / Best Practice',
                    _value('innovation'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSection(
                title: 'Story Details',
                icon: Icons.article_outlined,
                children: [
                  _buildDetailRow(
                    'One Health Issue',
                    _value('issue'),
                  ),
                  _buildDetailRow(
                    'Problem Identified',
                    _value('problem'),
                  ),
                  _buildDetailRow(
                    'Action Taken',
                    _value('action'),
                  ),
                  _buildDetailRow(
                    'Department Involved',
                    _value('department'),
                  ),
                  _buildDetailRow(
                    'Outcome / Result',
                    _value('outcome'),
                  ),
                  _buildDetailRow(
                    'Community Benefit',
                    _value('benefit'),
                  ),
                  _buildDetailRow(
                    'Lessons Learned',
                    _value('lessons'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSection(
                title: 'Record Status',
                icon: Icons.verified_outlined,
                children: [
                  _buildStatusRow(
                    'Verification Status',
                    _value('verification'),
                  ),
                  _buildStatusRow(
                    'Sync Status',
                    _value('sync'),
                  ),
                  _buildStatusRow(
                    'Record Status',
                    status,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildSection(
                title: 'Location Information',
                icon: Icons.location_on_outlined,
                children: [
                  _buildDetailRow(
                    'GPS Coordinates',
                    _value('gps'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF6F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF0D9E1),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: storyPink,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Location details are displayed using the '
                                'coordinates saved with this story.',
                            style: TextStyle(
                              color: storyMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Success Stories'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: storyPink,
                    side: const BorderSide(color: storyPink),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFB85C78),
            Color(0xFFD58CA2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const Spacer(),
              _buildHeaderStatus(_value('status')),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _value('title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _value('id'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Colors.white70,
                size: 15,
              ),
              const SizedBox(width: 7),
              Text(
                _value('date'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _value('location'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatus(String status) {
    final normalized = status.toLowerCase();

    final label = normalized.isEmpty || normalized == 'not provided'
        ? 'Unknown'
        : normalized[0].toUpperCase() + normalized.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: storyBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: storyPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF302833),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: storyBorder),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: storyMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF302833),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    final normalized = value.toLowerCase();

    Color color = storyMuted;
    Color background = const Color(0xFFF2F0F3);

    if (normalized.contains('verified') ||
        normalized.contains('approved') ||
        normalized == 'completed' ||
        normalized == 'synced' ||
        normalized == 'active') {
      color = const Color(0xFF26845B);
      background = const Color(0xFFE8F6EF);
    } else if (normalized.contains('pending') ||
        normalized.contains('submitted')) {
      color = const Color(0xFFAA7415);
      background = const Color(0xFFFFF4D9);
    } else if (normalized.contains('rejected') ||
        normalized.contains('failed') ||
        normalized.contains('disabled')) {
      color = const Color(0xFFBF4050);
      background = const Color(0xFFFFE9EC);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: storyMuted,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
