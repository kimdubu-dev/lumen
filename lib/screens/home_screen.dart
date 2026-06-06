import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/diary.dart';
import '../services/diary_repository.dart';
import 'diary_detail_screen.dart';
import 'diary_write_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiaryRepository _diaryRepository = const DiaryRepository();
  final List<Diary> _diaries = [];

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diaries = await _diaryRepository.fetchDiaries();

      if (!mounted) {
        return;
      }

      setState(() {
        _diaries
          ..clear()
          ..addAll(diaries);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('일기를 불러오지 못했어요: $error')));
    }
  }

  Diary? _getDiaryByDay(DateTime day) {
    for (final diary in _diaries) {
      if (isSameDay(diary.createdAt, day)) {
        return diary;
      }
    }

    return null;
  }

  Future<void> _goToWriteScreen(DateTime day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DiaryWriteScreen()),
    );

    if (result == null || result is! Map<String, String>) {
      return;
    }

    await _diaryRepository.createDiary(
      title: result['title'] ?? '',
      content: result['content'] ?? '',
      mood: result['mood'] ?? '😊',
      isPublic: result['isPublic'] == 'true',
      date: day,
    );

    await _loadDiaries();
  }

  Future<void> _goToDetailScreen(Diary diary) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(
          title: diary.title,
          content: diary.content,
          mood: diary.mood,
        ),
      ),
    );

    if (result != null && result is Map && result['action'] == 'edit') {
      await _goToEditScreen(diary);
    }
  }

  Future<void> _goToEditScreen(Diary diary) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          initialTitle: diary.title,
          initialContent: diary.content,
          initialMood: diary.mood,
          initialIsPublic: diary.isPublic,
        ),
      ),
    );

    if (result == null || result is! Map<String, String>) {
      return;
    }

    await _diaryRepository.updateDiary(
      diary: diary,
      title: result['title'] ?? '',
      content: result['content'] ?? '',
      mood: result['mood'] ?? '😊',
      isPublic: result['isPublic'] == 'true',
    );

    await _loadDiaries();
  }

  Future<void> _deleteDiary(Diary diary) async {
    await _diaryRepository.deleteDiary(diary.id);
    await _loadDiaries();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDiary = _getDiaryByDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(title: const Text('Lumen')),
      body: RefreshIndicator(
        onRefresh: _loadDiaries,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _TodaySummaryCard(
              diaryCount: _diaries.length,
              selectedDay: _selectedDay,
              selectedDiary: selectedDiary,
            ),
            const SizedBox(height: 16),
            _CalendarCard(
              diaries: _diaries,
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              onDaySelected: (selected, focused) async {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _LoadingCard()
            else if (selectedDiary == null)
              _EmptyDayCard(
                selectedDay: _selectedDay,
                onWrite: () => _goToWriteScreen(_selectedDay),
              )
            else
              _SelectedDiaryCard(
                diary: selectedDiary,
                onTap: () => _goToDetailScreen(selectedDiary),
                onDelete: () => _deleteDiary(selectedDiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final int diaryCount;
  final DateTime selectedDay;
  final Diary? selectedDiary;

  const _TodaySummaryCard({
    required this.diaryCount,
    required this.selectedDay,
    required this.selectedDiary,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final selectedTitle = selectedDiary?.displayTitle ?? '아직 비어 있는 날이에요';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  selectedDiary?.mood ?? '✍️',
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedDay.month}월 ${selectedDay.day}일',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$diaryCount',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '기록',
                  style: textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final List<Diary> diaries;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Future<void> Function(DateTime selected, DateTime focused)
  onDaySelected;

  const _CalendarCard({
    required this.diaries,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  Diary? _getDiaryByDay(DateTime day) {
    for (final diary in diaries) {
      if (isSameDay(diary.createdAt, day)) {
        return diary;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          rowHeight: 48,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final diary = _getDiaryByDay(day);

              if (diary == null) {
                return null;
              }

              return Positioned(
                bottom: 2,
                child: Text(diary.mood, style: const TextStyle(fontSize: 14)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SelectedDiaryCard extends StatelessWidget {
  final Diary diary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SelectedDiaryCard({
    required this.diary,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(diary.mood, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      diary.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    diary.isPublic
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    diary.visibilityLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                diary.displayContent,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDayCard extends StatelessWidget {
  final DateTime selectedDay;
  final VoidCallback onWrite;

  const _EmptyDayCard({required this.selectedDay, required this.onWrite});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(Icons.edit_note_rounded, color: scheme.primary, size: 36),
            const SizedBox(height: 10),
            Text(
              '${selectedDay.month}월 ${selectedDay.day}일의 일기가 없어요.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '짧게라도 남겨두면 캘린더에 감정이 표시돼요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onWrite,
                icon: const Icon(Icons.add_rounded),
                label: const Text('이 날 일기 쓰기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
