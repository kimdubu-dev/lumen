import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/diary_detail_screen.dart';
import 'screens/diary_write_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('diaries');

  runApp(const LumenApp());
}

class LumenApp extends StatelessWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumen',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F5FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D5DF6),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.notoSansKrTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF8F5FF),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.notoSansKr(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF252238),
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF252238),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6D5DF6),
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6D5DF6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6D5DF6),
            side: const BorderSide(
              color: Color(0xFF6D5DF6),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class Diary {
  final String id;
  final String title;
  final String content;
  final String mood;
  final bool isPublic;
  final DateTime createdAt;

  Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.isPublic,
    required this.createdAt,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Diary> diaries = [];

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get diaryCollection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('diaries');
  }

  @override
  void initState() {
    super.initState();
    loadDiaries();
  }

  Future<void> loadDiaries() async {
    final snapshot =
        await diaryCollection.orderBy('createdAt', descending: true).get();

    setState(() {
      diaries.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        diaries.add(
          Diary(
            id: doc.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            mood: data['mood'] ?? '😊',
            isPublic: data['isPublic'] ?? false,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
          ),
        );
      }
    });
  }

  Diary? getDiaryByDay(DateTime day) {
    for (final diary in diaries) {
      if (isSameDay(diary.createdAt, day)) {
        return diary;
      }
    }
    return null;
  }

  Future<void> handleDayTap(DateTime day) async {
    final diary = getDiaryByDay(day);

    if (diary == null) {
      await goToWriteScreen(day);
    } else {
      await goToDetailScreen(diary);
    }
  }

  Future<void> goToWriteScreen(DateTime day) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiaryWriteScreen(),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final diaryDate = DateTime(day.year, day.month, day.day);

      await diaryCollection.add({
        'title': result['title'] ?? '',
        'content': result['content'] ?? '',
        'mood': result['mood'] ?? '😊',
        'isPublic': result['isPublic'] == 'true',
        'createdAt': Timestamp.fromDate(diaryDate),
      });

      await loadDiaries();
    }
  }

  Future<void> deleteDiary(Diary diary) async {
    await diaryCollection.doc(diary.id).delete();
    await loadDiaries();
  }

  Future<void> goToDetailScreen(Diary diary) async {
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
      await goToEditScreen(diary);
    }
  }

  Future<void> goToEditScreen(Diary diary) async {
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

    if (result != null && result is Map<String, String>) {
      await diaryCollection.doc(diary.id).update({
        'title': result['title'] ?? '',
        'content': result['content'] ?? '',
        'mood': result['mood'] ?? '😊',
        'isPublic': result['isPublic'] == 'true',
      });

      await loadDiaries();
    }
  }

  String getPublicText(Diary diary) {
    return diary.isPublic ? '친구 공개' : '나만 보기';
  }

  IconData getPublicIcon(Diary diary) {
    return diary.isPublic ? Icons.public : Icons.lock_outline;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDiary = getDiaryByDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    diaryCount: diaries.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            onDaySelected: (selected, focused) async {
              setState(() {
                selectedDay = selected;
                focusedDay = focused;
              });

              await handleDayTap(selected);
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final diary = getDiaryByDay(day);

                if (diary == null) {
                  return null;
                }

                return Positioned(
                  bottom: 4,
                  child: Text(
                    diary.mood,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: selectedDiary == null
                ? Center(
                    child: Text(
                      '${selectedDay.month}월 ${selectedDay.day}일의 일기가 없어요.\n날짜를 눌러 작성해보세요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: ListTile(
                        title: Text(
                          '${selectedDiary.mood} ${selectedDiary.title.isEmpty ? '제목 없음' : selectedDiary.title}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  getPublicIcon(selectedDiary),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(getPublicText(selectedDiary)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedDiary.content.isEmpty
                                  ? '내용 없음'
                                  : selectedDiary.content,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            deleteDiary(selectedDiary);
                          },
                        ),
                        onTap: () {
                          goToDetailScreen(selectedDiary);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          goToWriteScreen(selectedDay);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}