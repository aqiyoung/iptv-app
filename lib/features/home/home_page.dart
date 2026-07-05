import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'poster_wall_page.dart';

/// 三页影视 主页 — 底部导航 + 海报墙
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PosterWallPage(),
          _PlaceholderPage(label: '短视频'),
          _PlaceholderPage(label: '会员'),
          _PlaceholderPage(label: '发现'),
          _PlaceholderPage(label: '我的'),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFF0B0F1A),
          selectedItemColor: const Color(0xFFE53935),
          unselectedItemColor: Colors.white38,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 22),
              activeIcon: Icon(Icons.home, size: 22),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline, size: 22),
              activeIcon: Icon(Icons.play_circle_filled, size: 22),
              label: '短视频',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard_outlined, size: 22),
              activeIcon: Icon(Icons.card_giftcard, size: 22),
              label: '会员',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 22),
              activeIcon: Icon(Icons.explore, size: 22),
              label: '发现',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 16,
        ),
      ),
    );
  }
}