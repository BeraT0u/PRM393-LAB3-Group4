import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/course_model.dart';
import '../utils/app_logger.dart';
import '../utils/course_filter.dart';
import 'database_seeder.dart';

class CourseService {
  final FirebaseFirestore? _firestore;
  final Set<String> _favoriteCourseCodes = {};

  bool isFavorite(String courseCode) => _favoriteCourseCodes.contains(courseCode);

  bool toggleFavorite(String courseCode) {
    if (_favoriteCourseCodes.contains(courseCode)) {
      _favoriteCourseCodes.remove(courseCode);
      return false;
    } else {
      _favoriteCourseCodes.add(courseCode);
      return true;
    }
  }

  CourseService({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  CollectionReference<Map<String, dynamic>>? get _coursesRef =>
      _firestore?.collection('courses');

  /// Chuẩn hóa dữ liệu môn học từ Firestore theo danh mục mẫu nếu thiếu hoặc lệch trường category/tips
  CourseModel _normalizeCourse(CourseModel remote) {
    final sample = DatabaseSeeder.sampleCourses
        .cast<CourseModel?>()
        .firstWhere((c) => c?.code == remote.code, orElse: () => null);
    if (sample == null) return remote;

    final hasValidCategory = remote.category.contains('SE') ||
        remote.category.contains('Cơ sở') ||
        remote.category.contains('Toán');
    return remote.copyWith(
      name: remote.name.trim().isEmpty ? sample.name : remote.name,
      category: hasValidCategory ? remote.category : sample.category,
      assessmentBreakdown: remote.assessmentBreakdown.isEmpty
          ? sample.assessmentBreakdown
          : remote.assessmentBreakdown,
      studyTips: remote.studyTips.isEmpty ? sample.studyTips : remote.studyTips,
    );
  }

  /// Lấy toàn bộ danh sách môn học từ Firestore (có fallback dữ liệu mẫu nếu mất mạng)
  Future<List<CourseModel>> getCourses() async {
    final ref = _coursesRef;
    if (ref == null) {
      return DatabaseSeeder.sampleCourses;
    }
    try {
      final snapshot = await ref.get();
      if (snapshot.docs.isEmpty) {
        AppLogger.warning('Collection courses trên Firestore đang trống, nạp dữ liệu mẫu...');
        await DatabaseSeeder.seedDatabaseIfEmpty();
        return DatabaseSeeder.sampleCourses;
      }

      final remoteCourses = snapshot.docs.map((doc) {
        return _normalizeCourse(CourseModel.fromMap(doc.data(), doc.id));
      }).toList();

      // Đảm bảo có đầy đủ cả các môn cơ sở trong danh mục nếu trên Firestore chưa có
      final existingCodes = remoteCourses.map((c) => c.code).toSet();
      final missingCourses = DatabaseSeeder.sampleCourses
          .where((c) => !existingCodes.contains(c.code))
          .toList();

      if (missingCourses.isNotEmpty) {
        for (final course in missingCourses) {
          remoteCourses.add(course);
          ref.doc(course.id).set(course.toMap()).ignore();
        }
      }

      return remoteCourses;
    } catch (e, st) {
      AppLogger.warning('Lỗi khi tải môn học từ Firestore, sử dụng dữ liệu cục bộ: $e');
      AppLogger.error('Lỗi getCourses', e, st);
      return DatabaseSeeder.sampleCourses;
    }
  }

  /// Lấy chi tiết một môn học theo Mã môn (ID)
  Future<CourseModel?> getCourseById(String courseId) async {
    final ref = _coursesRef;
    if (ref != null) {
      try {
        final doc = await ref.doc(courseId).get();
        if (doc.exists && doc.data() != null) {
          return _normalizeCourse(CourseModel.fromMap(doc.data()!, doc.id));
        }
      } catch (e) {
        AppLogger.warning('Lỗi getCourseById($courseId): $e');
      }
    }
    return DatabaseSeeder.sampleCourses.cast<CourseModel?>().firstWhere(
          (c) => c?.id == courseId || c?.code == courseId,
          orElse: () => null,
        );
  }

  /// Tìm kiếm và lọc môn học theo từ khóa và danh mục
  Future<List<CourseModel>> searchCourses({
    String query = '',
    String category = 'Tất cả',
  }) async {
    final allCourses = await getCourses();
    return CourseFilter.apply(allCourses, query: query, category: category);
  }
}
