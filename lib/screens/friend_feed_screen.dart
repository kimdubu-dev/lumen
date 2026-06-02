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

      await diaryRef.update({
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({
        'uid': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await diaryRef.update({
        'likeCount': FieldValue.increment(1),
      });
    }

    await loadFriendFeed();
  }

  String formatDate(DateTime date) {
    return '${date.year}.${date.month}.${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 피드'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : feedDiaries.isEmpty
              ? const Center(
                  child: Text(
                    '친구가 공개한 일기가 아직 없어요',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadFriendFeed,
                  child: ListView.builder(
                    itemCount: feedDiaries.length,
                    itemBuilder: (context, index) {
                      final diary = feedDiaries[index];
                      final photoUrl = diary['friendPhotoUrl'];
                      final isLiked = diary['isLiked'] == true;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : null,
                                    child: photoUrl == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        diary['friendNickname'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        formatDate(diary['createdAt']),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${diary['mood']} ${diary['title'].isEmpty ? '제목 없음' : diary['title']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                diary['content'].isEmpty
                                    ? '내용 없음'
                                    : diary['content'],
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(height: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : null,
                                    ),
                                    onPressed: () {
                                      toggleLike(diary);
                                    },
                                  ),
                                  Text(
                                    '${diary['likeCount']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat_bubble_outline,
                                    ),
                                    onPressed: () {
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
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}