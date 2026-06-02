import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'friend_feed_screen.dart';
import 'friend_requests_screen.dart';
import 'friend_search_screen.dart';
import 'friends_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int diaryCount;

  const ProfileScreen({
    super.key,
    required this.diaryCount,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isUploading = false;

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedImage == null || user == null) {
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final file = File(pickedImage.path);

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');

      await ref.putFile(file);

      final photoUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'uid': user!.uid,
        'email': user!.email,
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필 사진이 변경됐어요')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업로드 실패: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }

  Future<void> changeNickname() async {
    final controller = TextEditingController();

    final newNickname = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('닉네임 변경'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '새 닉네임',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (newNickname == null || newNickname.isEmpty || user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'nickname': newNickname,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임이 변경됐어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요해요'),
        ),
      );
    }

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final photoUrl = data?['photoUrl'];
          final nickname = data?['nickname'] ?? user!.email?.split('@')[0];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 56)
                              : null,
                        ),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: isUploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nickname ?? '사용자',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: changeNickname,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '이메일',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user!.email ?? '알 수 없음',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                const Text(
                  '작성한 일기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.diaryCount}개',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendSearchScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('친구 추가'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendRequestsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    label: const Text('친구 요청'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people_outline),
                    label: const Text('친구 목록'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendFeedScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dynamic_feed_outlined),
                    label: const Text('친구 피드'),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('로그아웃'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}