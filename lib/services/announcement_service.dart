import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/announcement_model.dart';
import '../utils/app_logger.dart';

/// Dịch vụ lắng nghe và tải thông báo học vụ từ Firestore collection `announcements`
class AnnouncementService {
  final FirebaseFirestore? _firestore;

  AnnouncementService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Danh sách thông báo mẫu mặc định (dùng khi offline, test hoặc chưa có data Firestore)
  static final List<AnnouncementModel> defaultAnnouncements = [
    AnnouncementModel(
      id: 'ann_welcome',
      title: 'Chào mừng sinh viên đến với EduPlan Fall 2024',
      body:
          'Phòng Đào tạo thông báo: Hệ thống lập kế hoạch học tập EduPlan đã chính thức mở cho toàn bộ sinh viên. Hãy kiểm tra các môn tiên quyết và đặt mục tiêu điểm trước khi kỳ học bắt đầu.',
      category: 'Học vụ',
      targetSemester: 'Tất cả các kỳ',
      authorName: 'Phòng Đào Tạo',
      status: 'published',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AnnouncementModel(
      id: 'ann_workload_warning',
      title: 'Khuyến nghị giới hạn giờ tự học mỗi tuần',
      body:
          'Cố vấn học tập lưu ý: Sinh viên nên duy trì tổng thời gian tự học <= 25h/tuần. Nếu vượt ngưỡng, hệ thống Workload Analyzer sẽ cảnh báo để tránh kiệt sức học tập.',
      category: 'Cảnh báo tải',
      targetSemester: 'Học kỳ 3',
      authorName: 'Cố Vấn Học Tập',
      status: 'published',
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    AnnouncementModel(
      id: 'ann_exam_schedule',
      title: 'Nhắc lịch thi thực hành môn Mobile Programming (PRM392/393)',
      body:
          'Lịch thi kết thúc học phần môn PRM sẽ diễn ra vào tuần thứ 10. Sinh viên chú ý nộp bài Lab 3 và hoàn thiện tài liệu kiểm thử trước hạn chót.',
      category: 'Lịch thi',
      targetSemester: 'Học kỳ 3',
      authorName: 'Bộ môn SE',
      status: 'published',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// Lắng nghe luồng thông báo thời gian thực từ Firestore
  Stream<List<AnnouncementModel>> streamAnnouncements() {
    if (_firestore == null) {
      return Stream.value(defaultAnnouncements);
    }

    try {
      return _firestore
          .collection('announcements')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return defaultAnnouncements;
        }

        final items = snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
            .where((item) => item.status == 'published')
            .toList();

        // Sắp xếp thông báo mới nhất lên đầu
        items.sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

        return items.isEmpty ? defaultAnnouncements : items;
      }).handleError((error) {
        AppLogger.warning('Lỗi khi stream announcements: $error');
        return defaultAnnouncements;
      });
    } catch (e) {
      AppLogger.warning('Ngoại lệ khởi tạo stream announcements: $e');
      return Stream.value(defaultAnnouncements);
    }
  }

  /// Lấy danh sách thông báo một lần
  Future<List<AnnouncementModel>> getAnnouncements() async {
    if (_firestore == null) {
      return defaultAnnouncements;
    }

    try {
      final snapshot = await _firestore.collection('announcements').get();
      if (snapshot.docs.isEmpty) {
        return defaultAnnouncements;
      }

      final items = snapshot.docs
          .map((doc) => AnnouncementModel.fromMap(doc.data(), doc.id))
          .where((item) => item.status == 'published')
          .toList();

      items.sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      return items.isEmpty ? defaultAnnouncements : items;
    } catch (e) {
      AppLogger.warning('Lỗi getAnnouncements: $e');
      return defaultAnnouncements;
    }
  }
}
