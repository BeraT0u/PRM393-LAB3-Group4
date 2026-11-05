import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/services/database_seeder.dart';
import 'package:eduplan/services/student_service.dart';
import 'package:eduplan/services/plan_service.dart';

void main() {
  group('Multi-Account Email Isolation & Account Switching Tests', () {
    late StudentService studentService;
    late PlanService planService;

    setUp(() {
      studentService = StudentService();
      planService = PlanService();
    });

    test('1. Tài khoản mới đăng nhập bắt đầu bằng dữ liệu trống (0 TC, Học kỳ 1)', () async {
      const uidB = 'uid_student_b';
      const emailB = 'studentB@fpt.edu.vn';

      final profileB = await studentService.getStudentProfile(
        uidB,
        email: emailB,
        displayName: 'Nguyễn Văn B',
      );

      // Tài khoản mới hoàn toàn: 0 TC, GPA 0.0, chưa có môn nào
      expect(profileB.uid, uidB);
      expect(profileB.email, emailB);
      expect(profileB.accumulatedCredits, 0);
      expect(profileB.currentGpa, 0.0);
      expect(profileB.passedCourseCodes, isEmpty);
      expect(profileB.isNewStudent, isTrue);

      final completedB = await studentService.getCompletedCourses(uidB);
      expect(completedB, isEmpty);

      // Học kỳ bắt đầu là Học kỳ 1
      final semesterName = StudentService.computeCurrentSemesterName(completedB);
      expect(semesterName, 'Học kỳ 1');

      final planB = planService.getLocalDraftPlan(userId: uidB);
      expect(planB.userId, uidB);
      expect(planB.selectedCourses, isEmpty);
    });

    test('2. Thao tác dữ liệu độc lập giữa 2 email, chuyển đổi qua lại không bị rò rỉ dữ liệu', () async {
      // === TÀI KHOẢN A ===
      const uidA = 'uid_student_a';
      const emailA = 'studentA@fpt.edu.vn';

      await studentService.getStudentProfile(uidA, email: emailA, displayName: 'User A');
      await studentService.updatePersonalInfo(
        uid: uidA,
        fullName: 'Nguyễn Trọng Hiếu',
        studentId: 'SE180504',
        major: 'Kỹ thuật Phần mềm',
        cohort: 'K18',
        targetGpa: 3.5,
      );

      final pro192 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'PRO192');
      await studentService.addCompletedCourse(
        uid: uidA,
        semesterIndex: 1,
        course: pro192,
        grade: 8.0,
      );

      // Kiểm tra tài khoản A có 3 TC
      final profileA = await studentService.getStudentProfile(uidA);
      expect(profileA.accumulatedCredits, 3);
      expect(profileA.studentId, 'SE180504');
      expect(profileA.currentGpa, 3.5);

      // === TÀI KHOẢN B ĐĂNG NHẬP ===
      const uidB = 'uid_student_b';
      const emailB = 'studentB@fpt.edu.vn';

      final freshProfileB = await studentService.getStudentProfile(
        uidB,
        email: emailB,
        displayName: 'Trần Thị B',
      );
      // Tài khoản B phải là dữ liệu trống, không dính bất kỳ dữ liệu nào của A
      expect(freshProfileB.accumulatedCredits, 0);
      expect(freshProfileB.studentId, isNot('SE180504'));
      expect(freshProfileB.passedCourseCodes, isEmpty);

      final completedB = await studentService.getCompletedCourses(uidB);
      expect(completedB, isEmpty);

      // Tài khoản B thêm môn riêng: MAD101
      final mad101 = DatabaseSeeder.sampleCourses.firstWhere((c) => c.code == 'MAD101');
      await studentService.addCompletedCourse(
        uid: uidB,
        semesterIndex: 1,
        course: mad101,
        grade: 6.0,
      );

      final updatedProfileB = await studentService.getStudentProfile(uidB);
      expect(updatedProfileB.accumulatedCredits, 3);
      expect(updatedProfileB.currentGpa, 2.0); // 6.0 quy đổi GPA 2.0
      expect(updatedProfileB.passedCourseCodes, ['MAD101']);

      // === ĐĂNG NHẬP LẠI TÀI KHOẢN A ===
      final reloadedA = await studentService.getStudentProfile(uidA);
      final reloadedCompletedA = await studentService.getCompletedCourses(uidA);

      // Toàn bộ dữ liệu của A vẫn được bảo toàn nguyên vẹn
      expect(reloadedA.studentId, 'SE180504');
      expect(reloadedA.accumulatedCredits, 3);
      expect(reloadedA.currentGpa, 3.5);
      expect(reloadedCompletedA.any((c) => c.code == 'PRO192'), isTrue);
      expect(reloadedCompletedA.any((c) => c.code == 'MAD101'), isFalse);

      // === ĐĂNG NHẬP LẠI TÀI KHOẢN B ===
      final reloadedB = await studentService.getStudentProfile(uidB);
      final reloadedCompletedB = await studentService.getCompletedCourses(uidB);

      // Toàn bộ dữ liệu của B vẫn được bảo toàn nguyên vẹn
      expect(reloadedB.accumulatedCredits, 3);
      expect(reloadedB.currentGpa, 2.0);
      expect(reloadedCompletedB.any((c) => c.code == 'MAD101'), isTrue);
      expect(reloadedCompletedB.any((c) => c.code == 'PRO192'), isFalse);
    });
  });
}
