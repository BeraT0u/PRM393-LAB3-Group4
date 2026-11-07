import 'dart:typed_data';
import 'package:eduplan/models/completed_course_model.dart';
import 'package:eduplan/models/student_profile_model.dart';
import 'package:eduplan/models/study_plan_model.dart';
import 'package:eduplan/screens/semester_summary_screen.dart';
import 'package:eduplan/services/pdf_report_service.dart';
import 'package:eduplan/services/service_providers.dart';
import 'package:eduplan/services/storage_service.dart';
import 'package:eduplan/services/student_service.dart';
import 'package:eduplan/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePdfReportService extends PdfReportService {
  bool generatePdfCalled = false;
  bool previewCalled = false;

  @override
  Future<Uint8List> generatePlanPdf({
    required StudyPlanModel plan,
    required StudentProfileModel student,
  }) async {
    generatePdfCalled = true;
    return Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  Future<void> previewOrSharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    previewCalled = true;
  }
}

class _FakeStorageService extends StorageService {
  @override
  Stream<UploadProgressInfo> uploadReportPdf({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async* {
    yield const UploadProgressInfo(progress: 0.5);
    yield const UploadProgressInfo(
      progress: 1.0,
      isCompleted: true,
      downloadUrl: 'https://storage.googleapis.com/test-bucket/blueprint.pdf',
    );
  }
}

class _FakeStudentService extends StudentService {
  bool markCompletedCalled = false;

  @override
  Future<int> completeSemesterFromPlan({
    required String uid,
    required StudyPlanModel plan,
    List<CourseGradeItem>? courseGrades,
  }) async {
    markCompletedCalled = true;
    return 15;
  }

  @override
  Future<void> markSemesterPlanCompleted({
    required String uid,
    required String planId,
  }) async {
    markCompletedCalled = true;
  }
}

void main() {
  late _FakePdfReportService fakePdfService;
  late _FakeStorageService fakeStorageService;
  late _FakeStudentService fakeStudentService;

  setUp(() {
    fakePdfService = _FakePdfReportService();
    fakeStorageService = _FakeStorageService();
    fakeStudentService = _FakeStudentService();
  });

  Widget buildTestableScreen() {
    return ProviderScope(
      overrides: [
        pdfReportServiceProvider.overrideWithValue(fakePdfService),
        storageServiceProvider.overrideWithValue(fakeStorageService),
        studentServiceProvider.overrideWithValue(fakeStudentService),
      ],
      child: MaterialApp(
        theme: AppTheme.warmPaperTheme,
        home: const SemesterSummaryScreen(),
        routes: {
          '/completed-courses': (_) => const Scaffold(body: Text('SCR-03 Completed Courses')),
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      ),
    );
  }

  group('NHÓM 5: SCR-07 SemesterSummaryScreen Tests (UC-26 -> UC-30)', () {
    testWidgets('UC-26: Thẻ Hero KPI hiển thị đủ 4 chỉ số và Bottom Bar được khôi phục', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Tiêu đề AppTopBar
      expect(find.text('Tổng Kết Kế Hoạch'), findsOneWidget);

      // Thẻ Hero KPI: 4 chỉ số (UC-26)
      expect(find.text('Kỳ học: Fall 2024'), findsOneWidget);
      expect(find.text('Lộ trình hợp lệ ✅'), findsOneWidget);
      expect(find.text('5 Môn • 15 TC'), findsOneWidget);
      expect(find.text('3.65 / 4.0'), findsOneWidget);
      expect(find.text('26h • Cân bằng'), findsOneWidget);
      expect(find.textContaining('14.250.000'), findsOneWidget);

      // Khôi phục thanh điều hướng 4 tab (Navigation Bar destinations)
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Đã học'), findsOneWidget);
      expect(find.text('Tìm môn'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);
    });

    testWidgets('UC-27: Danh sách 5 môn học hiển thị đầy đủ kèm mục tiêu điểm và tích xanh', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Kiểm tra 5 mã môn học trong kỳ học chuẩn (UC-27)
      expect(find.text('PRM393'), findsOneWidget);
      expect(find.text('SWE302'), findsOneWidget);
      expect(find.text('AIE411'), findsOneWidget);
      expect(find.text('PRM323'), findsOneWidget);
      expect(find.text('OSG209'), findsOneWidget);

      // Tích xanh điều kiện tiên quyết
      expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
      expect(find.text('Đạt điều kiện tiên quyết ✅'), findsOneWidget);
    });

    testWidgets('UC-28, UC-29, UC-30: Xuất bản PDF Blueprint A4, upload Storage & xem trước in', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Nút xuất PDF Blueprint A4 (UC-28, UC-29, UC-30)
      final exportBtn = find.text('📄 Xuất PDF Kế Hoạch & Chiến Lược (A4)');
      expect(exportBtn, findsOneWidget);

      await tester.ensureVisible(exportBtn);
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Kiểm tra đã gọi service sinh PDF và preview
      expect(fakePdfService.generatePdfCalled, isTrue);
      expect(fakePdfService.previewCalled, isTrue);
    });

    testWidgets('Giao diện không còn nút Sync Calendar và Chia sẻ', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Đảm bảo không còn nút Sync Calendar và nút Chia sẻ
      expect(find.text('📅 Sync Calendar'), findsNothing);
      expect(find.text('🔗 Chia sẻ'), findsNothing);
    });

    testWidgets('UC-26B: Nghiệm thu kỳ học: Bấm nút mở Dialog và chuyển sang SCR-03', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Nút Đã hoàn thành kỳ học (UC-26B)
      final completeBtn = find.text('✅ Đã Hoàn Thành Kỳ Học');
      expect(completeBtn, findsOneWidget);

      await tester.ensureVisible(completeBtn);
      await tester.tap(completeBtn);
      await tester.pumpAndSettle();

      // Hộp thoại xác nhận nghiệm thu
      expect(find.text('Nghiệm Thu Kỳ Học'), findsOneWidget);
      expect(find.textContaining('chuyển 5 môn học (15 TC)'), findsOneWidget);

      // Xác nhận hoàn thành
      final confirmBtn = find.text('Xác nhận hoàn thành');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Đã gọi backend nghiệm thu kỳ học và điều hướng sang SCR-03
      expect(fakeStudentService.markCompletedCalled, isTrue);
      expect(find.text('SCR-03 Completed Courses'), findsOneWidget);
    });

    testWidgets(
        'Bấm nút Trang chủ trên thanh điều hướng từ SemesterSummaryScreen chuyển thẳng về Home',
        (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
