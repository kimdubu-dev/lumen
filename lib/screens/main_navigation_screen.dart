import 'package:flutter/material.dart';

import '../services/diary_repository.dart';
import 'diary_write_screen.dart';
import 'friend_feed_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final DiaryRepository _diaryRepository = const DiaryRepository();

  int _selectedIndex = 0;
  int _homeRefreshKey = 0;

  Future<void> _openWriteScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryWriteScreen()),
    );

    if (result == null || result is! Map<String, String>) {
      return;
    }

    await _diaryRepository.createDiary(
      title: result['title'] ?? '',
      content: result['content'] ?? '',
      mood: result['mood'] ?? '😊',
      isPublic: result['isPublic'] == 'true',
      date: DateTime.now(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedIndex = 0;
      _homeRefreshKey++;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(key: ValueKey(_homeRefreshKey));
      case 1:
        return const FriendFeedScreen();
      case 3:
        return FutureBuilder<int>(
          future: _diaryRepository.countDiaries(),
          builder: (context, snapshot) {
            return ProfileScreen(diaryCount: snapshot.data ?? 0);
          },
        );
      default:
        return HomeScreen(key: ValueKey(_homeRefreshKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          height: 72,
          onDestinationSelected: (index) {
            if (index == 2) {
              _openWriteScreen();
              return;
            }

            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_2_outlined),
              selectedIcon: Icon(Icons.groups_2_rounded),
              label: '피드',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded),
              label: '작성',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
