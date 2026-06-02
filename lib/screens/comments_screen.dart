import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsScreen extends StatefulWidget {
  final String ownerUid;
  final String diaryId;

  const CommentsScreen({
    super.key,
    required this.ownerUid,
    required this.diaryId,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final controller = TextEditingController();

  String get myUid => FirebaseAuth.instance.currentUser!.uid;
  String get myEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '알 수 없음';

  Future<void> addComment() async {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ownerUid)
        .collection('diaries')
        .doc(widget.diaryId)
        .collection('comments')
        .add({
      'uid': myUid,
      'email': myEmail,
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final commentsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ownerUid)
        .collection('diaries')
        .doc(widget.diaryId)
        .collection('comments')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('댓글'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                    child: Text('첫 댓글을 남겨보세요 ✍️'),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data();

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(
                        data['email'] ?? '사용자',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        data['content'] ?? '',
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: addComment,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}