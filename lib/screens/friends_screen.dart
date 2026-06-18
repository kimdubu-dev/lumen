import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  String get myUid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final friendsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends');

    return Scaffold(
      appBar: AppBar(title: const Text('친구 목록')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: friendsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data!.docs;

          if (friends.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: _FriendsEmptyCard(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
            itemCount: friends.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final friendUid = friends[index].id;

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendUid)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final userData = userSnapshot.data!.data();

                  final nickname = userData?['nickname'] ?? '사용자';
                  final email = userData?['email'] ?? '알 수 없음';
                  final photoUrl = userData?['photoUrl'];
                  final scheme = Theme.of(context).colorScheme;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Icon(Icons.person_rounded, color: scheme.primary)
                            : null,
                      ),
                      title: Text(
                        nickname,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(email),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FriendsEmptyCard extends StatelessWidget {
  const _FriendsEmptyCard();

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
                Icons.people_outline_rounded,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '아직 친구가 없어요',
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
