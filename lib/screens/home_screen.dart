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
      appBar: AppBar(
        title: const Text('Lumen'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: _loadDiaries,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDiaries,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택한 날',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.12),
                    ),
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
                        style: textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$diaryCount',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '기록',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          rowHeight: 48,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: scheme.onSurface,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurface,
            ),
            titleTextStyle:
                textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900) ??
                const TextStyle(fontWeight: FontWeight.w900),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle:
                textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ) ??
                TextStyle(color: scheme.onSurfaceVariant),
            weekendStyle:
                textTheme.labelMedium?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w800,
                ) ??
                TextStyle(color: scheme.secondary),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(4),
            defaultTextStyle:
                textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700) ??
                const TextStyle(fontWeight: FontWeight.w700),
            weekendTextStyle:
                textTheme.bodyMedium?.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w700,
                ) ??
                TextStyle(color: scheme.secondary),
            todayDecoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.secondary.withValues(alpha: 0.3),
              ),
            ),
            todayTextStyle: TextStyle(
              color: scheme.secondary,
              fontWeight: FontWeight.w900,
            ),
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w900,
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
                child: Text(diary.mood, style: const TextStyle(fontSize: 13)),
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
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        diary.mood,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diary.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                diary.isPublic
                                    ? Icons.public_rounded
                                    : Icons.lock_outline_rounded,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                diary.visibilityLabel,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '삭제',
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: scheme.onSurfaceVariant,
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                diary.displayContent,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '자세히 보기',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: scheme.primary,
                  ),
                ],
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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.edit_note_rounded,
                color: scheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${selectedDay.month}월 ${selectedDay.day}일의 일기가 없어요.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '짧게라도 남겨두면 캘린더에 감정이 표시돼요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
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
