import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/completed_course_model.dart';
import 'package:eduplan/models/course_model.dart';
import 'package:eduplan/utils/completed_course_rules.dart';

CourseModel course(String code, {String? prereq}) => CourseModel(
      id: code,
      code: code,
      name: code,
      credits: 3,
      difficulty: 3,
      defaultSelfStudyHours: 5,
      prerequisiteCode: prereq,
      category: 'Chuyên ngành SE',
      assessmentBreakdown: const {},
      studyTips: const [],
      plannedSelfStudyHours: 5,
    );

CompletedCourseModel done(String code, int? semester) =>
    CompletedCourseModel(code: code, name: code, credits: 3, semesterIndex: semester);

void main() {
  group('CompletedCourseRules.validateAdd', () {
    test('Kỳ 1 không cần kỳ trước và hợp lệ', () {
      expect(
        CompletedCourseRules.validateAdd(
          semesterIndex: 1,
          course: course('PRO192'),
          completed: const [],
        ),
        isNull,
      );
    });

    test('Kỳ 2 bị chặn khi Kỳ 1 chưa có môn', () {
      final err = CompletedCourseRules.validateAdd(
        semesterIndex: 2,
        course: course('MAD101'),
        completed: const [],
      );
      expect(err, contains('Kỳ 1'));
    });

    test('Kỳ 3 bị chặn khi có Kỳ 1 nhưng thiếu Kỳ 2', () {
      final err = CompletedCourseRules.validateAdd(
        semesterIndex: 3,
        course: course('X'),
        completed: [done('PRO192', 1)],
      );
      expect(err, contains('Kỳ 2'));
    });

    test('Kỳ 2 hợp lệ khi Kỳ 1 đã có môn', () {
      expect(
        CompletedCourseRules.validateAdd(
          semesterIndex: 2,
          course: course('MAD101'),
          completed: [done('PRO192', 1)],
        ),
        isNull,
      );
    });

    test('Thiếu môn tiên quyết bị từ chối và báo mã môn', () {
      final err = CompletedCourseRules.validateAdd(
        semesterIndex: 2,
        course: course('PRM393', prereq: 'PRO192'),
        completed: [done('MAD101', 1)],
      );
      expect(err, contains('PRO192'));
    });

    test('Tiên quyết ở cùng kỳ không được chấp nhận', () {
      final err = CompletedCourseRules.validateAdd(
        semesterIndex: 2,
        course: course('PRM393', prereq: 'PRO192'),
        completed: [done('MAD101', 1), done('PRO192', 2)],
      );
      expect(err, contains('PRO192'));
    });

    test('Tiên quyết hoàn thành ở kỳ trước thì hợp lệ', () {
      expect(
        CompletedCourseRules.validateAdd(
          semesterIndex: 2,
          course: course('PRM393', prereq: 'PRO192'),
          completed: [done('PRO192', 1)],
        ),
        isNull,
      );
    });

    test('Mã môn có sẵn trong hồ sơ (chưa phân kỳ) thỏa tiên quyết', () {
      expect(
        CompletedCourseRules.validateAdd(
          semesterIndex: 1,
          course: course('PRM393', prereq: 'PRO192'),
          completed: const [],
          legacyPassedCodes: const {'PRO192'},
        ),
        isNull,
      );
    });

    test('Không cho thêm trùng môn đã học', () {
      final err = CompletedCourseRules.validateAdd(
        semesterIndex: 1,
        course: course('PRO192'),
        completed: [done('PRO192', 1)],
      );
      expect(err, contains('PRO192'));
    });
  });

  group('CompletedCourseRules.validateGrade', () {
    test('null, quá thấp và quá cao đều lỗi', () {
      expect(CompletedCourseRules.validateGrade(null), isNotNull);
      expect(CompletedCourseRules.validateGrade(3.9), isNotNull);
      expect(CompletedCourseRules.validateGrade(10.5), isNotNull);
    });

    test('4.0 đến 10 hợp lệ', () {
      expect(CompletedCourseRules.validateGrade(4.0), isNull);
      expect(CompletedCourseRules.validateGrade(10), isNull);
    });
  });
}
