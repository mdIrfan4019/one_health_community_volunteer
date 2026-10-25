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
    _loadStories();
    _loadSessionMetadata();
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
    if (!isRefresh) {
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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NewSuccessStoryScreen(
          apiService: _apiService,
          initialVolunteerId: _volunteerId,
        ),
      ),
    );

    if (!mounted || result == null) return;

    // Refresh live list from server
    await _loadStories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Success story submitted successfully.'),
        ),
      );
    }
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
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          Container(
            height: 185,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: storyBorder,
                width: 1.5,
              ),
            ),
            child: const Text(
              'No success stories documented yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: storyMuted,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: _stories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final story = _stories[index];
        return SuccessStoryCard(
          story: story,
          onTap: () => _openDetails(story),
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
              // Left pink vertical accent strip matching Screenshot 1
              Container(
                width: 3.5,
                height: 50,
                decoration: BoxDecoration(
                  color: storyPink,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Record info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Title + 'pending' / status pill badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            story.title,
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
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 7,
                        //     vertical: 2,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFFF1EEF3),
                        //     borderRadius: BorderRadius.circular(4),
                        //   ),
                        //   child: Text(
                        //     story.statusBadge,
                        //     style: const TextStyle(
                        //       fontSize: 9.5,
                        //       fontWeight: FontWeight.w600,
                        //       color: storyMuted,
                        //     ),
                        //   ),
                        // ),
                        Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 7,
    vertical: 2,
  ),
  decoration: BoxDecoration(
    color: const Color(0xFFE6F4EB), // Soft green background
    borderRadius: BorderRadius.circular(4),
  ),
  child: const Text(
    'synced',
    style: TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w600,
      color: Color(0xFF39845A), // Green text
    ),
  ),
),

                      ],
                    ),
                    const SizedBox(height: 4),

                    // Middle line: STY-26-0003 · 24 Oct 2026
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: story.storyCode,
                            style: const TextStyle(
                              color: storyPink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: Color(0xFFAAA3AE)),
                          ),
                          TextSpan(
                            text: story.formattedDate,
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

                    // Third line: Location · innovation / best practice
                    Text(
                      story.locationText.isNotEmpty
                          ? '${story.locationText} · ${story.formattedCategory}'
                          : story.formattedCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
