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
    contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
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
    final isEditMode =
        widget.initialTitle != null ||
        widget.initialContent != null ||
        widget.initialMood != null;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '일기 수정' : '일기 작성'),
        actions: [
          IconButton(
            tooltip: '저장',
            onPressed: saveDiary,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘의 감정',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: moods.map((mood) {
                        final isSelected = mood == selectedMood;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedMood = mood;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.primaryContainer
                                  : scheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? scheme.primary
                                    : scheme.outline,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mood,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: SwitchListTile(
                contentPadding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                secondary: Icon(
                  isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                  color: scheme.primary,
                ),
                title: Text(
                  isPublic ? '친구에게 공개' : '나만 보기',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '제목',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              minLines: 10,
              maxLines: 14,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: '내용',
                hintText: '오늘 하루를 기록해보세요...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
