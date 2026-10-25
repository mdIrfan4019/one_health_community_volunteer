
import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/sample_reprot/screens/sample_support_form_screen.dart';

class SampleSupportScreen extends StatefulWidget {
  const SampleSupportScreen({super.key});

  @override
  State<SampleSupportScreen> createState() =>
      _SampleSupportScreenState();
}

class _SampleSupportScreenState extends State<SampleSupportScreen> {
  static const Color primaryColor = Color(0xFFC26378);
  static const Color backgroundColor = Color(0xFFF7F5F8);
  static const Color mutedColor = Color(0xFF89838F);

  int _selectedIndex = 0;

  final List<SampleReport> _reports = [
    SampleReport(
      title: 'Companion animal samples',
      id: 'SMP-26-0002',
      date: '24 Oct 2026',
      location: 'Mannanur',
      facilitated: 1,
      status: 'pending',
    ),
    SampleReport(
      title: 'Water quality samples',
      id: 'SMP-26-0003',
      date: '23 Oct 2026',
      location: 'Noida',
      facilitated: 3,
      status: 'active',
    ),
    SampleReport(
      title: 'Soil testing samples',
      id: 'SMP-26-0004',
      date: '22 Oct 2026',
      location: 'Lucknow',
      facilitated: 2,
      status: 'pending',
    ),
  ];

  Future<void> _openCreateReportForm() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SampleSupportFormScreen(),
      ),
    );

    if (!mounted || result == null) return;

    final sampleType = result['sampleType'] as String? ?? 'Sample Support';
    final village = result['village'] as String? ?? 'Not specified';
    final rawDate = result['date'] as String? ?? '';
    final parsedDate = DateTime.tryParse(rawDate);
    final facilitated =
        result['numberFacilitated'] as int? ?? 1;

    final formattedDate = parsedDate == null
        ? '24 Oct 2026'
        : '${parsedDate.day.toString().padLeft(2, '0')} '
        '${_monthName(parsedDate.month)} ${parsedDate.year}';

    setState(() {
      _reports.insert(
        0,
        SampleReport(
          title: sampleType,
          id: 'SMP-26-${(_reports.length + 2).toString().padLeft(4, '0')}',
          date: formattedDate,
          location: village,
          facilitated: facilitated,
          status: 'pending',
        ),
      );
      _selectedIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample report added to the list (demo only).'),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  void _openReport(SampleReport report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SampleReportDetailScreen(report: report),
      ),
    );
  }

  void _onBottomNavigationTap(int index) {
    setState(() => _selectedIndex = index);

    if (index != 0) {
      final labels = ['Dashboard', 'Actions', 'Reports', 'Profile'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${labels[index]} screen coming soon'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AuthenticatedAppBar(
        title: 'Sample Support',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: _selectedIndex == 0
            ? _buildSampleReportList()
            : _buildPlaceholder(),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _openCreateReportForm,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add, size: 21),
        label: const Text(
          'Sample Support',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const StadiumBorder(),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavigationTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedColor,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        elevation: 8,
        iconSize: 20,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }


  Widget _buildSampleReportList() {
    if (_reports.isEmpty) {
      return const Center(
        child: Text(
          'No sample reports available',
          style: TextStyle(color: mutedColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: _reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final report = _reports[index];

        return SampleReportCard(
          report: report,
          onTap: () => _openReport(report),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    const labels = ['Dashboard', 'Actions', 'Reports', 'Profile'];

    return Center(
      child: Text(
        '${labels[_selectedIndex]} screen coming soon',
        style: const TextStyle(
          fontSize: 16,
          color: mutedColor,
        ),
      ),
    );
  }
}

class SampleReport {
  final String title;
  final String id;
  final String date;
  final String location;
  final int facilitated;
  final String status;

  const SampleReport({
    required this.title,
    required this.id,
    required this.date,
    required this.location,
    required this.facilitated,
    required this.status,
  });
}

class SampleReportCard extends StatelessWidget {
  final SampleReport report;
  final VoidCallback onTap;

  const SampleReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = report.status.toLowerCase() == 'pending';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE9E3EA)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF80A995),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF29252C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFF0EDF2)
                                : const Color(0xFFE6F4EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.status,
                            style: TextStyle(
                              fontSize: 9,
                              color: isPending
                                  ? const Color(0xFF827B88)
                                  : const Color(0xFF39845A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: report.id,
                            style: const TextStyle(
                              color: Color(0xFFC26378),
                            ),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFFAAA3AE)),
                          ),
                          TextSpan(
                            text: report.date,
                            style: const TextStyle(
                              color: Color(0xFF89838F),
                            ),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFFAAA3AE)),
                          ),
                          TextSpan(
                            text: report.location,
                            style: const TextStyle(
                              color: Color(0xFF89838F),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.facilitated} facilitated',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF89838F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF89838F),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SampleReportDetailScreen extends StatelessWidget {
  final SampleReport report;

  const SampleReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F8),
      appBar: AuthenticatedAppBar(
        title: 'Sample Report',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _detail('Sample ID', report.id),
                _detail('Status', report.status),
                _detail('Date', report.date),
                _detail('Location', report.location),
                _detail(
                  'Facilitated records',
                  report.facilitated.toString(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF89838F),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
