import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/diary.dart';

class DiaryRepository {
  const DiaryRepository();

  String get _userId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _collection {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('diaries');
  }

  Future<List<Diary>> fetchDiaries() async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(Diary.fromSnapshot).toList();
  }

  Future<int> countDiaries() async {
    final snapshot = await _collection.get();
    return snapshot.docs.length;
  }

  Future<void> createDiary({
    required String title,
    required String content,
    required String mood,
    required bool isPublic,
    required DateTime date,
  }) async {
    final diaryDate = DateTime(date.year, date.month, date.day);

    await _collection.add({
      'title': title,
      'content': content,
      'mood': mood,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(diaryDate),
    });
  }

  Future<void> updateDiary({
    required Diary diary,
    required String title,
    required String content,
    required String mood,
    required bool isPublic,
  }) async {
    await _collection.doc(diary.id).update({
      'title': title,
      'content': content,
      'mood': mood,
      'isPublic': isPublic,
    });
  }

  Future<void> deleteDiary(String diaryId) async {
    await _collection.doc(diaryId).delete();
  }
}
