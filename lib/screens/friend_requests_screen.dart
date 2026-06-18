import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  String get myUid => FirebaseAuth.instance.currentUser!.uid;
  String get myEmail => FirebaseAuth.instance.currentUser!.email ?? '';

  Future<void> acceptRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final fromUid = data['fromUid'];
    final fromEmail = data['fromEmail'];

    final batch = FirebaseFirestore.instance.batch();

    final myFriendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('friends')
        .doc(fromUid);

    final theirFriendRef = FirebaseFirestore.instance
        .collection('users')
        .doc(fromUid)
        .collection('friends')
        .doc(myUid);

    final requestRef = FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(requestId);

    batch.set(myFriendRef, {
      'uid': fromUid,
      'email': fromEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(theirFriendRef, {
      'uid': myUid,
      'email': myEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(requestRef, {'status': 'accepted'});

    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    final requestQuery = FirebaseFirestore.instance
        .collection('friendRequests')
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending');

    return Scaffold(
      appBar: AppBar(title: const Text('친구 요청')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: requestQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(18),
              child: _RequestEmptyCard(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data();
              final scheme = Theme.of(context).colorScheme;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.person_rounded, color: scheme.primary),
                  ),
                  title: Text(data['fromEmail'] ?? '알 수 없음'),
                  subtitle: const Text('친구 요청을 보냈어요'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: '수락',
                        color: scheme.primary,
                        icon: const Icon(Icons.check_rounded),
                        onPressed: () {
                          acceptRequest(doc.id, data);
                        },
                      ),
                      IconButton(
                        tooltip: '거절',
                        color: scheme.onSurfaceVariant,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          rejectRequest(doc.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestEmptyCard extends StatelessWidget {
  const _RequestEmptyCard();

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
                Icons.mark_email_read_outlined,
                color: scheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '받은 친구 요청이 없어요',
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
