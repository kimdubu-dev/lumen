import 'package:flutter/material.dart';

class DiaryWriteScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialContent;
  final String? initialMood;
  final bool? initialIsPublic;

  const DiaryWriteScreen({
    super.key,
    this.initialTitle,
    this.initialContent,
    this.initialMood,
    this.initialIsPublic,
  });

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  late final TextEditingController titleController;
  late final TextEditingController contentController;

  late String selectedMood;
  late bool isPublic;

  final List<String> moods = ['😊', '😆', '😐', '🥲', '😡'];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.initialTitle ?? '');
    contentController = TextEditingController(text: widget.initialContent ?? '');
    selectedMood = widget.initialMood ?? '😊';
    isPublic = widget.initialIsPublic ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void saveDiary() {
    Navigator.pop(context, {
      'title': titleController.text,
      'content': contentController.text,
      'mood': selectedMood,
      'isPublic': isPublic ? 'true' : 'false',
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.initialTitle != null ||
        widget.initialContent != null ||
        widget.initialMood != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '일기 수정' : '일기 작성'),
        actions: [
          TextButton(
            onPressed: saveDiary,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 감정', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Row(
              children: moods.map((mood) {
                final isSelected = mood == selectedMood;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMood = mood;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isPublic ? '친구에게 공개' : '나만 보기'),
              subtitle: Text(
                isPublic ? '친구들이 이 일기를 볼 수 있어요' : '이 일기는 나만 볼 수 있어요',
              ),
              value: isPublic,
              onChanged: (value) {
                setState(() {
                  isPublic = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '오늘 하루를 기록해보세요...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}