import 'package:flutter/material.dart';

class DiaryDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String mood;

  const DiaryDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.pop(context, {
                'action': 'edit',
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mood, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title.isEmpty ? '제목 없음' : title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              content.isEmpty ? '내용 없음' : content,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}