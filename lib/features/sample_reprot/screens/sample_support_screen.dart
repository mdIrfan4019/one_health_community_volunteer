import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import 'package:cohv/features/sample_reprot/data/sample_support_api_service.dart';
import 'package:cohv/features/sample_reprot/domain/sample_support_models.dart';
import 'package:cohv/features/sample_reprot/screens/sample_support_form_screen.dart';

/// Screen displaying the list of Sample Support reports fetched dynamically from the server.
/// File: lib/features/sample_reprot/screens/sample_support_screen.dart
class SampleSupportScreen extends StatefulWidget {
  final SampleSupportApiService? apiService;
  final String? volunteerId;

  const SampleSupportScreen({
    super.key,
    this.apiService,
    this.volunteerId,
  });

  @override
  State<SampleSupportScreen> createState() => _SampleSupportScreenState();
}

class _SampleSupportScreenState extends State<SampleSupportScreen> {
  static const Color primaryColor = Color(0xFF136B4F);
  static const Color backgroundColor = Color(0xFFF2F7F4);
  static const Color mutedColor = Color(0xFF89838F);

  late final SampleSupportApiService _apiService;
  List<SampleSupportRecordModel> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1; // Actions tab

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SampleSupportApiService();
    _loadRecords();
  }

  /// Fetches sample support reports from GET /api/sample-support
  Future<void> _loadRecords({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _apiService.fetchSampleSupportList();
      if (mounted) {
        setState(() {
          _records = items;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[SAMPLE_SUPPORT_SCREEN] Error loading records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_records.isEmpty) {
            _errorMessage = 'Could not load records. Pull to try again.';
          }
        });
      }
    }
  }

  /// Opens the form to submit a new sample support report
  Future<void> _openCreateReportForm() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SampleSupportFormScreen(),
      ),
    );

    if (!mounted || result == null) return;

    // Refresh live list from server
    await _loadRecords();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample report submitted successfully.'),
        ),
      );
    }
  }

  /// Opens detail screen for the selected sample support record
  void _openReport(SampleSupportRecordModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SampleReportDetailScreen(
          sampleId: record.sampleId,
          initialRecord: record,
          apiService: _apiService,
          volunteerId: widget.volunteerId,
        ),
      ),
    );
  }

  void _onBottomNavigationTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    Navigator.pop(context, index);
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
        backgroundColor: backgroundColor,
        appBar: AuthenticatedAppBar(
          title: 'Sample Support',
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () => Navigator.pop(context),
          backgroundColor: const Color(0xFF136B4F),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _loadRecords(isRefresh: true),
            color: primaryColor,
            child: _buildBody(),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: FloatingActionButton.extended(
            key: const ValueKey('add_sample_support_fab'),
            onPressed: _openCreateReportForm,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'Sample Support',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            shape: const StadiumBorder(),
          ),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null && _records.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 52,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: mutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _loadRecords(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_records.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 56,
                  color: Color(0xFFCBD5E1),
                ),
                SizedBox(height: 14),
                Text(
                  'No sample support records found',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap "+ Sample Support" below to record samples.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: _records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = _records[index];
        return SampleReportCard(
          record: record,
          onTap: () => _openReport(record),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavigationTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedColor,
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
}

/// Card representing a Sample Support record in the listing screen.
/// Matches Screenshot 1 exact design.
class SampleReportCard extends StatelessWidget {
  final SampleSupportRecordModel record;
  final VoidCallback onTap;

  const SampleReportCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE9E3EA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left green vertical accent strip
              Container(
                width: 3.5,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF80A995),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Record info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title + 'synced' pill badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            record.sampleTypeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF29252C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'synced',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF39845A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Middle line: SMP-26-0007 · 24 Oct 2026 · Mannanur
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: record.sampleCode,
                            style: const TextStyle(
                              color: Color(0xFF136B4F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFFAAA3AE)),
                          ),
                          TextSpan(
                            text: record.formattedDate,
                            style: const TextStyle(
                              color: Color(0xFF89838F),
                            ),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFFAAA3AE)),
                          ),
                          TextSpan(
                            text: record.villageName ?? 'Amrabad',
                            style: const TextStyle(
                              color: Color(0xFF89838F),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),

                    // Third line: 1 facilitated
                    Text(
                      '${record.sampleCount} facilitated',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF89838F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Trailing chevron icon
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF89838F),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen displaying full details of a specific Sample Support report.
/// Fetches dynamically from GET /api/sample-support/{sample_id}.
/// Matches Screenshot 2 exact design.
class SampleReportDetailScreen extends StatefulWidget {
  final int sampleId;
  final SampleSupportRecordModel? initialRecord;
  final SampleSupportApiService? apiService;
  final String? volunteerId;

  const SampleReportDetailScreen({
    super.key,
    required this.sampleId,
    this.initialRecord,
    this.apiService,
    this.volunteerId,
  });

  @override
  State<SampleReportDetailScreen> createState() =>
      _SampleReportDetailScreenState();
}

class _SampleReportDetailScreenState extends State<SampleReportDetailScreen> {
  static const Color primaryColor = Color(0xFF136B4F);
  static const Color backgroundColor = Color(0xFFF2F7F4);
  static const Color mutedColor = Color(0xFF89838F);

  late final SampleSupportApiService _apiService;
  SampleSupportRecordModel? _record;
  bool _isLoading = false;
  int _selectedIndex = 1; // Actions tab

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SampleSupportApiService();
    _record = widget.initialRecord;
    if (_record == null) {
      _isLoading = true;
    }
    _fetchDetail();
  }

  /// Fetches individual sample support record by id from GET /api/sample-support/{id}
  Future<void> _fetchDetail() async {
    try {
      final detail =
          await _apiService.fetchSampleSupportDetail(widget.sampleId);
      if (detail != null && mounted) {
        setState(() {
          _record = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[SAMPLE_DETAIL] Error fetching detail: $e');
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavigationTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    Navigator.pop(context, index);
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
        backgroundColor: backgroundColor,
        appBar: AuthenticatedAppBar(
          title: 'Sample Support',
          volunteerId: widget.volunteerId ?? '',
          onBackPressed: () => Navigator.pop(context),
          backgroundColor: const Color(0xFF136B4F),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : RefreshIndicator(
                onRefresh: _fetchDetail,
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Details Card
                      _buildDetailCard(),

                      const SizedBox(height: 18),

                      // 2. Outlined Back Button
                      _buildBackButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildDetailCard() {
    final record = _record ??
        SampleSupportRecordModel(
          sampleId: widget.sampleId,
          sampleCode:
              'SMP-26-${widget.sampleId.toString().padLeft(4, '0')}',
          sampleTypeId: 1,
          sampleTypeName: 'Human samples',
          sampleDate: '2026-10-24',
          sampleCount: 1,
          villageName: 'Mannanur',
        );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBF1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Sample Code
          Text(
            record.sampleTypeName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF29252C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record.sampleCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // 7 Key-value rows with dividers
          _buildDetailRow('Sample type', record.sampleTypeName),
          _buildDivider(),
          _buildDetailRow('Date', record.formattedDate),
          _buildDivider(),
          _buildDetailRow('Number facilitated', '${record.sampleCount}'),
          _buildDivider(),
          _buildDetailRow('Village / ward', record.villageName ?? '—'),
          _buildDivider(),
          _buildDetailRow('Verification', record.formattedVerificationStatus),
          _buildDivider(),
          _buildDetailRow('Synchronisation', record.formattedSyncStatus),
          _buildDivider(),
          _buildDetailRow('GPS location', record.formattedGpsLocation),

          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 14),

          // ATTACHMENTS Section
          const Text(
            'ATTACHMENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF89838F),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildAttachmentsRow(record),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(
        color: Color(0xFFF1F2F6),
        height: 1,
        thickness: 1,
      );

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF89838F),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF29252C),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Attachments row displaying 3 preview boxes side-by-side matching Screenshot 2
  Widget _buildAttachmentsRow(SampleSupportRecordModel record) {
    return Row(
      children: [
        // 1. Photo Thumbnail
        _buildPhotoThumbnail(record),
        const SizedBox(width: 12),

        // 2. Video Thumbnail
        _buildVideoThumbnail(record),
        const SizedBox(width: 12),

        // 3. Document Thumbnail
        _buildDocThumbnail(record),
      ],
    );
  }

  Widget _buildPhotoThumbnail(SampleSupportRecordModel record) {
    Widget content;
    final hasPhoto = record.photos.isNotEmpty;

    if (hasPhoto) {
      final photoPath = record.photos.first;
      if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
        content = Image.network(
          photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPhotoFallback(),
        );
      } else {
        final file = File(photoPath);
        if (file.existsSync()) {
          content = Image.file(file, fit: BoxFit.cover);
        } else {
          content = _buildPhotoFallback();
        }
      }
    } else {
      content = _buildPhotoFallback();
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E4E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: content,
          ),
        ),
        // Pink circular badge at bottom right
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      color: const Color(0xFF26262A),
      child: const Center(
        child: Icon(
          Icons.camera_alt_rounded,
          color: Colors.white70,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(SampleSupportRecordModel record) {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFD3D5DC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD0DC)),
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pill with VIDEO
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIDEO',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF136B4F),
                    ),
                  ),
                ),
                // Play triangle icon centered
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildDocThumbnail(SampleSupportRecordModel record) {
    return Stack(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBF1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5DFE8)),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'DOC',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF136B4F),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 3,
          right: 3,
          child: _buildCircularBadge(),
        ),
      ],
    );
  }

  Widget _buildCircularBadge() {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFF136B4F),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '*',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        key: const ValueKey('sample_detail_back_button'),
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: primaryColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Back',
          style: TextStyle(
            color: primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
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
        currentIndex: _selectedIndex,
        onTap: _onBottomNavigationTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedColor,
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
}
