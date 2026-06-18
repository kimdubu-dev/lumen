import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'diary_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<_ExploreDiary> _diaries = [];
  String _query = '';

  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadExploreDiaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExploreDiaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collectionGroup('diaries')
          .where('isPublic', isEqualTo: true)
          .limit(40)
          .get();

      final loadedDiaries = <_ExploreDiary>[];

      for (final doc in snapshot.docs) {
        final ownerRef = doc.reference.parent.parent;

        if (ownerRef == null || ownerRef.id == _myUid) {
          continue;
        }

        final ownerSnapshot = await ownerRef.get();
        final ownerData = ownerSnapshot.data();
        final diaryData = doc.data();
        final email = ownerData?['email'] ?? '알 수 없음';
        final nickname =
            ownerData?['nickname'] ?? email.toString().split('@').first;
        final createdAtValue = diaryData['createdAt'];

        loadedDiaries.add(
          _ExploreDiary(
            ownerUid: ownerRef.id,
            diaryId: doc.id,
            nickname: nickname,
            email: email,
            photoUrl: ownerData?['photoUrl'],
            title: diaryData['title'] ?? '',
            content: diaryData['content'] ?? '',
            mood: diaryData['mood'] ?? '😊',
            likeCount: diaryData['likeCount'] ?? 0,
            createdAt: createdAtValue is Timestamp
                ? createdAtValue.toDate()
                : DateTime.now(),
          ),
        );
      }

      loadedDiaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) {
        return;
      }

      setState(() {
        _diaries = loadedDiaries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('탐색을 불러오지 못했어요: $error')));
    }
  }

  List<_ExploreDiary> get _visibleDiaries {
    final normalizedQuery = _query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return _diaries;
    }

    return _diaries.where((diary) {
      final searchable =
          '${diary.nickname} ${diary.email} ${diary.title} ${diary.content} ${diary.mood}'
              .toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  void _openDiary(_ExploreDiary diary) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          title: diary.title,
          content: diary.content,
          mood: diary.mood,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final visibleDiaries = _visibleDiaries;

    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: RefreshIndicator(
        onRefresh: _loadExploreDiaries,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _SearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              onClear: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _ExploreLoadingCard()
            else if (_diaries.isEmpty)
              const _ExploreEmptyCard(
                title: '공개된 일기가 아직 없어요',
                message: '친구들이 일기를 공개하면 탐색에서 볼 수 있어요.',
              )
            else if (visibleDiaries.isEmpty)
              const _ExploreEmptyCard(
                title: '검색 결과가 없어요',
                message: '다른 닉네임이나 문장을 검색해보세요.',
              )
            else ...[
              Text(
                _query.trim().isEmpty ? '요즘 공개 일기' : '검색 결과',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...visibleDiaries.map(
                (diary) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExploreDiaryCard(
                    diary: diary,
                    dateText: _formatDate(diary.createdAt),
                    onTap: () => _openDiary(diary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                tooltip: '검색어 지우기',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
        hintText: '닉네임, 제목, 문장 검색',
      ),
    );
  }
}

class _ExploreDiaryCard extends StatelessWidget {
  final _ExploreDiary diary;
  final String dateText;
  final VoidCallback onTap;

  const _ExploreDiaryCard({
    required this.diary,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: diary.photoUrl != null
                        ? NetworkImage(diary.photoUrl!)
                        : null,
                    child: diary.photoUrl == null
                        ? Icon(Icons.person_rounded, color: scheme.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diary.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          dateText,
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        diary.mood,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                diary.title.isEmpty ? '제목 없음' : diary.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                diary.content.isEmpty ? '내용 없음' : diary.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${diary.likeCount}',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreEmptyCard extends StatelessWidget {
  final String title;
  final String message;

  const _ExploreEmptyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.travel_explore_rounded, size: 38, color: scheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreLoadingCard extends StatelessWidget {
  const _ExploreLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ExploreDiary {
  final String ownerUid;
  final String diaryId;
  final String nickname;
  final String email;
  final String? photoUrl;
  final String title;
  final String content;
  final String mood;
  final int likeCount;
  final DateTime createdAt;

  const _ExploreDiary({
    required this.ownerUid,
    required this.diaryId,
    required this.nickname,
    required this.email,
    required this.photoUrl,
    required this.title,
    required this.content,
    required this.mood,
    required this.likeCount,
    required this.createdAt,
  });
}
