import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'comments_screen.dart';

class FriendFeedScreen extends StatefulWidget {
  const FriendFeedScreen({super.key});

  @override
  State<FriendFeedScreen> createState() => _FriendFeedScreenState();
}

class _FriendFeedScreenState extends State<FriendFeedScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> feedDiaries = [];

  String get myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadFriendFeed();
  }

  Future<void> loadFriendFeed() async {
    setState(() {
      isLoading = true;
    });

    final friendsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .get();

    final List<Map<String, dynamic>> loadedDiaries = [];

    for (final friendDoc in friendsSnapshot.docs) {
      final friendUid = friendDoc.id;

      final friendUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();

      final friendData = friendUserDoc.data();

      final friendEmail = friendData?['email'] ?? '알 수 없음';
      final friendNickname =
          friendData?['nickname'] ?? friendEmail.toString().split('@')[0];
      final friendPhotoUrl = friendData?['photoUrl'];

      final diariesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .collection('diaries')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      for (final diaryDoc in diariesSnapshot.docs) {
        final data = diaryDoc.data();

        final likeDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(friendUid)
            .collection('diaries')
            .doc(diaryDoc.id)
            .collection('likes')
            .doc(myUid)
            .get();

        loadedDiaries.add({
          'friendUid': friendUid,
          'diaryId': diaryDoc.id,
          'friendEmail': friendEmail,
          'friendNickname': friendNickname,
          'friendPhotoUrl': friendPhotoUrl,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'mood': data['mood'] ?? '😊',
          'likeCount': data['likeCount'] ?? 0,
          'isLiked': likeDoc.exists,
          'createdAt': (data['createdAt'] as Timestamp).toDate(),
        });
      }
    }

    loadedDiaries.sort((a, b) {
      final aDate = a['createdAt'] as DateTime;
      final bDate = b['createdAt'] as DateTime;
      return bDate.compareTo(aDate);
    });

    if (mounted) {
      setState(() {
        feedDiaries = loadedDiaries;
        isLoading = false;
      });
    }
  }

  Future<void> toggleLike(Map<String, dynamic> diary) async {
    final friendUid = diary['friendUid'];
    final diaryId = diary['diaryId'];

    final diaryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .collection('diaries')
        .doc(diaryId);

    final likeRef = diaryRef.collection('likes').doc(myUid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();

      await diaryRef.update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likeRef.set({
        'uid': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await diaryRef.update({'likeCount': FieldValue.increment(1)});
    }

    await loadFriendFeed();
  }

  String formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구 피드')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : feedDiaries.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(18),
              child: _FeedEmptyCard(
                title: '친구가 공개한 일기가 아직 없어요',
                message: '친구의 공개 일기가 생기면 이곳에 표시돼요.',
                icon: Icons.groups_2_outlined,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadFriendFeed,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                itemCount: feedDiaries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final diary = feedDiaries[index];

                  return _FriendDiaryCard(
                    diary: diary,
                    dateText: formatDate(diary['createdAt']),
                    onLike: () => toggleLike(diary),
                    onComment: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(
                            ownerUid: diary['friendUid'],
                            diaryId: diary['diaryId'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _FriendDiaryCard extends StatelessWidget {
  final Map<String, dynamic> diary;
  final String dateText;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const _FriendDiaryCard({
    required this.diary,
    required this.dateText,
    required this.onLike,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = diary['friendPhotoUrl'];
    final isLiked = diary['isLiked'] == true;
    final title = diary['title'].isEmpty ? '제목 없음' : diary['title'];
    final content = diary['content'].isEmpty ? '내용 없음' : diary['content'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(Icons.person_rounded, color: scheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diary['friendNickname'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
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
                      diary['mood'],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  tooltip: isLiked ? '좋아요 취소' : '좋아요',
                  icon: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isLiked ? scheme.secondary : scheme.onSurfaceVariant,
                  ),
                  onPressed: onLike,
                ),
                Text(
                  '${diary['likeCount']}',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '댓글',
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  color: scheme.onSurfaceVariant,
                  onPressed: onComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedEmptyCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _FeedEmptyCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
