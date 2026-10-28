import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../utils/app_logger.dart';
import 'database_seeder.dart';

class CourseService {
  final FirebaseFirestore _firestore;

  CourseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');

  /// Lấy toàn bộ danh sách môn học từ Firestore (có fallback dữ liệu mẫu nếu mất mạng)
  Future<List<CourseModel>> getCourses() async {
    try {
      final snapshot = await _coursesRef.get();
      if (snapshot.docs.isEmpty) {
        AppLogger.warning('Collection courses trên Firestore đang trống, nạp dữ liệu mẫu...');
        await DatabaseSeeder.seedDatabaseIfEmpty();
        return DatabaseSeeder.sampleCourses;
      }

      return snapshot.docs.map((doc) {
        return CourseModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e, st) {
      AppLogger.warning('Lỗi khi tải môn học từ Firestore, sử dụng dữ liệu cục bộ: $e');
      AppLogger.error('Lỗi getCourses', e, st);
      return DatabaseSeeder.sampleCourses;
    }
  }

  /// Lấy chi tiết một môn học theo Mã môn (ID)
  Future<CourseModel?> getCourseById(String courseId) async {
    try {
      final doc = await _coursesRef.doc(courseId).get();
      if (doc.exists && doc.data() != null) {
        return CourseModel.fromMap(doc.data()!, doc.id);
      }
      return DatabaseSeeder.sampleCourses.cast<CourseModel?>().firstWhere(
            (c) => c?.id == courseId || c?.code == courseId,
            orElse: () => null,
          );
    } catch (e) {
      AppLogger.warning('Lỗi getCourseById($courseId): $e');
      return DatabaseSeeder.sampleCourses.cast<CourseModel?>().firstWhere(
            (c) => c?.id == courseId || c?.code == courseId,
            orElse: () => null,
          );
    }
  }

  /// Tìm kiếm và lọc môn học theo từ khóa và danh mục
  Future<List<CourseModel>> searchCourses({
    String query = '',
    String category = 'Tất cả',
  }) async {
    final allCourses = await getCourses();
    final cleanQuery = query.trim().toLowerCase();

    return allCourses.where((c) {
      final matchesQuery = cleanQuery.isEmpty ||
          c.code.toLowerCase().contains(cleanQuery) ||
          c.name.toLowerCase().contains(cleanQuery);

      final matchesCategory = category == 'Tất cả' ||
          (category == 'Chuyên ngành SE' && c.category.contains('SE')) ||
          (category == 'Cơ sở' && (c.category.contains('Cơ sở') || c.category.contains('Toán')));

      return matchesQuery && matchesCategory;
    }).toList();
  }
}
