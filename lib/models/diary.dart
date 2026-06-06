import 'package:cloud_firestore/cloud_firestore.dart';

class Diary {
  final String id;
  final String title;
  final String content;
  final String mood;
  final bool isPublic;
  final DateTime createdAt;

  const Diary({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.isPublic,
    required this.createdAt,
  });

  factory Diary.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    final createdAtValue = data['createdAt'];

    return Diary(
      id: snapshot.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      mood: data['mood'] ?? '😊',
      isPublic: data['isPublic'] ?? false,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }

  String get displayTitle => title.isEmpty ? '제목 없음' : title;
  String get displayContent => content.isEmpty ? '내용 없음' : content;
  String get visibilityLabel => isPublic ? '친구 공개' : '나만 보기';
}
