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
  String get myEmail => FirebaseAuth.instance.currentUser?.email ?? '알 수 없음';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
      appBar: AppBar(title: const Text('댓글')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(18),
                    child: _CommentsEmptyCard(),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = comments[index].data();
                    final scheme = Theme.of(context).colorScheme;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.person_rounded,
                            color: scheme.primary,
                          ),
                        ),
                        title: Text(data['email'] ?? '사용자'),
                        subtitle: Text(data['content'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: '댓글을 입력하세요',
                          prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '댓글 보내기',
                      onPressed: addComment,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsEmptyCard extends StatelessWidget {
  const _CommentsEmptyCard();

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
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '첫 댓글을 남겨보세요',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
