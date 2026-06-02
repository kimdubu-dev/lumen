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
      appBar: AppBar(
        title: const Text('친구 목록'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: friendsQuery.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final friends = snapshot.data!.docs;

          if (friends.isEmpty) {
            return const Center(
              child: Text('아직 친구가 없어요'),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
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

                  final nickname =
                      userData?['nickname'] ?? '사용자';
                  final email =
                      userData?['email'] ?? '알 수 없음';
                  final photoUrl =
                      userData?['photoUrl'];

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        nickname,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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