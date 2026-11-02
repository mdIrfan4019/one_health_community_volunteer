// Screen displaying the list of Success Stories fetched dynamically from GET /api/success-stories/all
// Cards match Sample Support layout exactly
// File: lib/features/success_stories/screens/success_stories_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cohv/core/storage/session_manager.dart';
import 'package:cohv/core/theme/app_colors.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';
import '../data/success_story_api_service.dart';
import '../domain/success_story_models.dart';
import 'success_story_detail_screen.dart';
import 'new_success_story_screen.dart';

const Color storyPink = Color(0xFF136B4F);
const Color storyBackground = Color(0xFFF2F7F4);
const Color storyMuted = Color(0xFF89838F);
const Color storyBorder = Color(0xFFE9E3EA);

class SuccessStoriesScreen extends StatefulWidget {
  final SuccessStoryApiService? apiService;
  final String? volunteerId;

  const SuccessStoriesScreen({
    super.key,
    this.apiService,
    this.volunteerId,
  });

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  late final SuccessStoryApiService _apiService;
  List<SuccessStoryRecordModel> _stories = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1; // Actions tab

  String _volunteerId = '';
  int? _numericVolunteerId;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? SuccessStoryApiService();
    _volunteerId = widget.volunteerId ?? '';
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadSessionMetadata();
    await _preloadStories();
    await _loadStories();
  }

  /// Instant offline preloader: populates screen immediately from SQLite
  Future<void> _preloadStories() async {
    try {
      final cached = await _apiService.getCachedSuccessStoriesList(
        volunteerId: widget.volunteerId ?? _volunteerId,
        numericVolunteerId: _numericVolunteerId,
      );
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _stories = cached;
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSessionMetadata() async {
    try {
      final session = await SessionManager.getUserSession();
      final storedVid = await SessionManager.getVolunteerId();
      final storedNumId = await SessionManager.getNumericVolunteerId();

      final vid = (widget.volunteerId != null && widget.volunteerId!.isNotEmpty)
          ? widget.volunteerId!
          : (storedVid ?? session?.volunteerId ?? '');

      final numId = storedNumId ?? session?.numericVolunteerId;

      if (mounted) {
        setState(() {
          _volunteerId = vid;
          _numericVolunteerId = numId;
        });
      }
    } catch (_) {}
  }

  /// Fetches success stories from GET /api/success-stories/all
  Future<void> _loadStories({bool isRefresh = false}) async {
    if (!isRefresh && _stories.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _apiService.fetchSuccessStoriesList(
        volunteerId: _volunteerId,
        numericVolunteerId: _numericVolunteerId,
      );
      if (mounted) {
        setState(() {
          _stories = items;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORIES_SCREEN] Error loading stories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_stories.isEmpty) {
            _errorMessage = 'Could not load success stories. Pull to try again.';
          }
        });
      }
    }
  }

  /// Opens the form to submit a new success story
  Future<void> _openNewStory() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => NewSuccessStoryScreen(
          apiService: _apiService,
          initialVolunteerId: _volunteerId,
        ),
      ),
    );

    if (!mounted || result == null) return;

    // Immediately display new story card
    try {
      final SuccessStoryRecordModel newModel = (result is SuccessStoryRecordModel)
          ? result
          : SuccessStoryRecordModel.fromJson(
              Map<String, dynamic>.from(result as Map),
            );
      if (mounted) {
        setState(() {
          _stories.removeWhere(
            (s) =>
                (s.storyId > 0 && s.storyId == newModel.storyId) ||
                (s.storyCode.isNotEmpty && s.storyCode == newModel.storyCode),
          );
          _stories.insert(0, newModel);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[SUCCESS_STORIES_SCREEN] Error displaying newly created story: $e');
    }

    // Refresh live list from server in background
    await _loadStories(isRefresh: true);

    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Success story submitted successfully.'),
    //     ),
    //   );
    // }
  }

  /// Opens detail screen for the selected success story record
  void _openDetails(SuccessStoryRecordModel story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessStoryDetailScreen(
          storyId: story.storyId,
          initialStory: story,
          apiService: _apiService,
          volunteerId: _volunteerId,
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
        backgroundColor: storyBackground,
        appBar: AuthenticatedAppBar(
          title: 'Success Stories',
          volunteerId: _volunteerId,
          onBackPressed: () => Navigator.pop(context),
          backgroundColor: const Color(0xFF136B4F),
          onSyncTap: () => _loadStories(isRefresh: true),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: () => _loadStories(isRefresh: true),
            color: storyPink,
            child: _buildBody(),
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: FloatingActionButton.extended(
            key: const ValueKey('add_success_story_fab'),
            onPressed: _openNewStory,
            backgroundColor: storyPink,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'New Story',
              style: TextStyle(
                fontSize: 14,
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
        child: CircularProgressIndicator(color: storyPink),
      );
    }

    if (_errorMessage != null && _stories.isEmpty) {
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
                    color: storyMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _loadStories(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: storyPink),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: storyPink),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_stories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        children: [
          _buildEmptyState(),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return SuccessStoryCard(
          story: story,
          onTap: () => _openDetails(story),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No success stories documented yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Use New Story to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
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
        selectedItemColor: storyPink,
        unselectedItemColor: storyMuted,
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

/// Card representing a Success Story record in the listing screen.
/// Matches Sample Support card layout exactly with Success Story pink accent styling.
class SuccessStoryCard extends StatelessWidget {
  final SuccessStoryRecordModel story;
  final VoidCallback onTap;

  const SuccessStoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = story.verificationStatus.trim().toLowerCase();
    final isFailed = status.contains('fail');
    final isPending = status.contains('pending') || status.contains('offline');

    final Color badgeBg;
    final Color badgeText;
    final String badgeLabel;

    if (isFailed) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
      badgeLabel = 'sync failed';
    } else if (isPending) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
      badgeLabel = 'pending';
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      badgeLabel = (status == 'submitted' ? 'synced' : status);
    }

    final dateStr = story.formattedDate.isNotEmpty ? story.formattedDate : story.storyDate;
    final locationPart = story.locationText.isNotEmpty ? ' · ${story.locationText}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vertical Blue Accent Bar matching Referrals Card
                Container(
                  width: 3.5,
                  height: 48,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              story.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                color: badgeText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(
                              text: story.storyCode,
                              style: const TextStyle(
                                color: Color(0xFF136B4F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' · $dateStr$locationPart',
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        story.departmentName != null && story.departmentName!.trim().isNotEmpty
                            ? '${story.departmentName} · ${story.formattedCategory}'
                            : story.formattedCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
