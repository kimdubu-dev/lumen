import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final emailController = TextEditingController();

  Map<String, dynamic>? foundUser;
  String? foundUserId;
  bool isLoading = false;

  String get myUid => FirebaseAuth.instance.currentUser!.uid;
  String get myEmail => FirebaseAuth.instance.currentUser!.email ?? '';

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> searchUser() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      foundUser = null;
      foundUserId = null;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (!mounted) {
      return;
    }

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;

      if (doc.id == myUid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('자기 자신은 친구로 추가할 수 없어요')));
      } else {
        foundUser = doc.data();
        foundUserId = doc.id;
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('해당 이메일의 사용자를 찾을 수 없어요')));
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendFriendRequest() async {
    if (foundUser == null || foundUserId == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('friendRequests').add({
      'fromUid': myUid,
      'fromEmail': myEmail,
      'toUid': foundUserId,
      'toEmail': foundUser!['email'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈어요')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구 추가')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '친구 이메일',
                hintText: 'example@gmail.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: searchUser,
                child: const Text('검색'),
              ),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator()
            else if (foundUser != null)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(foundUser!['nickname'] ?? '이름 없음'),
                  subtitle: Text(foundUser!['email'] ?? ''),
                  trailing: FilledButton(
                    onPressed: sendFriendRequest,
                    child: const Text('요청'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
