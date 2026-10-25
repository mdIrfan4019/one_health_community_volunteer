
import 'package:flutter/material.dart';
import 'package:cohv/core/widgets/authenticated_header.dart';

import 'Success_Story_DetailScreen.dart';
import 'new_success_story_screen.dart';

const Color storyPink = Color(0xFFB85C78);
const Color storyBackground = Color(0xFFF6F3F7);
const Color storyMuted = Color(0xFF8D8793);
const Color storyBorder = Color(0xFFE8E1E9);

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() =>
      _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _stories = [
    {
      'id': 'STY-26-0003',
      'title': 'Kshg',
      'date': '24 Oct 2026',
      'location': 'Jsih',
      'issue': 'Jaj',
      'problem': 'Jshhk',
      'action': 'Jsjh',
      'department': 'Forest Department',
      'outcome': 'Hsheh',
      'benefit': 'Jishe',
      'lessons': 'Hsheh',
      'innovation': 'Yes',
      'category': 'innovation / best practice',
      'verification': 'Submitted',
      'sync': 'Pending',
      'gps': '25.281224, 82.953923 · ±20 m',
      'status': 'pending',
    },
  ];

  Future<void> _openNewStory() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const NewSuccessStoryScreen(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _stories.insert(0, {
        ...result,
        'id':
        'STY-26-${(_stories.length + 3).toString().padLeft(4, '0')}',
        'status': 'pending',
        'verification': result['verification'] ?? 'Submitted',
        'sync': 'Pending',
        'gps': 'Location not captured',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Success story added (demo only)'),
      ),
    );
  }

  void _openDetails(Map<String, dynamic> story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuccessStoryDetailScreen(story: story),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: storyBackground,
      appBar: AuthenticatedAppBar(
        title: 'Success Stories',
        onBackPressed: () => Navigator.pop(context),
      ),
      body: _selectedTab == 0
          ? _buildStoryList()
          : Center(
        child: Text(
          const [
            'Dashboard',
            'Actions',
            'Reports',
            'Profile',
          ][_selectedTab] +
              ' screen coming soon',
        ),
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton.extended(
        onPressed: _openNewStory,
        backgroundColor: storyPink,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add, size: 25),
        label: const Text(
          'New Story',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: const StadiumBorder(),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: storyMuted,
        unselectedItemColor: storyMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 23,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Actions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStoryList() {
    if (_stories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
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
                fontSize: 17,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 110),
      itemCount: _stories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final story = _stories[index];

        return _StoryCard(
          story: story,
          onTap: () => _openDetails(story),
        );
      },
    );
  }
}


class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;

  const _StoryCard({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(
              color: storyBorder,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 100,
                decoration: BoxDecoration(
                  color: storyPink,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 9,
                      runSpacing: 6,
                      children: [
                        Text(
                          story['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF302B33),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1EEF3),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            story['status'] ?? 'pending',
                            style: const TextStyle(
                              fontSize: 12,
                              color: storyMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: story['id'] ?? '',
                            style: const TextStyle(color: storyPink),
                          ),
                          const TextSpan(
                            text: ' · ',
                            style: TextStyle(color: storyMuted),
                          ),
                          TextSpan(
                            text: story['date'] ?? '',
                            style: const TextStyle(color: storyMuted),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story['location'] ?? ''} · '
                          '${story['category'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: storyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 24,
                color: storyMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
