import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho thông báo học vụ, lịch thi, cảnh báo tải từ Web Admin đến Mobile
class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String category;
  final String targetSemester;
  final String authorName;
  final String status; // 'published' | 'archived'
  final DateTime? createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'Học vụ',
    this.targetSemester = 'Tất cả các kỳ',
    this.authorName = 'Cố vấn học tập',
    this.status = 'published',
    this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? created;
    final rawDate = map['createdAt'];
    if (rawDate is Timestamp) {
      created = rawDate.toDate();
    } else if (rawDate is DateTime) {
      created = rawDate;
    } else if (rawDate is String) {
      created = DateTime.tryParse(rawDate);
    }

    return AnnouncementModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'Học vụ',
      targetSemester: map['targetSemester'] as String? ?? 'Tất cả các kỳ',
      authorName: map['authorName'] as String? ?? 'Cố vấn học tập',
      status: map['status'] as String? ?? 'published',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'targetSemester': targetSemester,
      'authorName': authorName,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
