import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduplan/models/announcement_model.dart';
import 'package:eduplan/screens/profile_screen.dart';
import 'package:eduplan/services/announcement_service.dart';
import 'package:eduplan/services/service_providers.dart';

void main() {
  group('AnnouncementModel & AnnouncementService Tests', () {
    test('AnnouncementModel serialization with Timestamp and Map', () {
      final now = DateTime.now();
      final model = AnnouncementModel(
        id: 'ann_test',
        title: 'Thông báo kiểm thử',
        body: 'Nội dung kiểm thử thông báo từ Web Admin',
        category: 'Học vụ',
        targetSemester: 'Học kỳ 3',
        authorName: 'Cố vấn kiểm thử',
        status: 'published',
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'ann_test');
      expect(map['title'], 'Thông báo kiểm thử');
      expect(map['category'], 'Học vụ');
      expect(map['status'], 'published');
      expect(map['createdAt'], isA<Timestamp>());

      final parsed = AnnouncementModel.fromMap(map, 'ann_test');
      expect(parsed.id, 'ann_test');
      expect(parsed.title, 'Thông báo kiểm thử');
      expect(parsed.body, 'Nội dung kiểm thử thông báo từ Web Admin');
      expect(parsed.category, 'Học vụ');
      expect(parsed.authorName, 'Cố vấn kiểm thử');
      expect(parsed.status, 'published');
    });

    test('AnnouncementService fallback default announcements when offline',
        () async {
      final service = AnnouncementService(firestore: null);
      final items = await service.getAnnouncements();
      expect(items, isNotEmpty);
      expect(items.any((a) => a.title.contains('EduPlan')), isTrue);
      expect(items.any((a) => a.category == 'Học vụ'), isTrue);

      final streamList = await service.streamAnnouncements().first;
      expect(streamList, isNotEmpty);
      expect(streamList.length, items.length);
    });
  });

  group('ProfileScreen Notification Bell Button & Popup Tests', () {
    setUp(() {
      AnnouncementService.clearCache();
    });
    testWidgets(
        'ProfileScreen displays notification bell in AppTopBar and opens popup on tap',
        (tester) async {
      final testAnnouncements = [
        AnnouncementModel(
          id: 'test_1',
          title: 'Thông báo khẩn từ Web Admin',
          body: 'Toàn bộ sinh viên chú ý nộp báo cáo Lab 3 đúng hạn.',
          category: 'Cảnh báo tải',
          targetSemester: 'Học kỳ 3',
          authorName: 'Admin Portal',
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsStreamProvider.overrideWithValue(
              AsyncValue.data(testAnnouncements),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra nút chuông thông báo xuất hiện thay thế nút bút
      final bellFinder = find.byTooltip('Hộp thư thông báo');
      expect(bellFinder, findsOneWidget);

      // Nút chỉnh sửa hồ sơ vẫn còn nguyên vẹn trong thân màn hình
      expect(
        find.textContaining('Chỉnh sửa hồ sơ & Mục tiêu GPA'),
        findsOneWidget,
      );

      // Bấm vào nút chuông
      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      // Kiểm tra Modal Popup Hộp thư thông báo hiển thị
      expect(find.text('Hộp Thư Thông Báo'), findsOneWidget);
      expect(find.text('Từ Ban Giảng Huấn & Cố Vấn Học Tập'), findsOneWidget);
      expect(find.text('Thông báo khẩn từ Web Admin'), findsOneWidget);
      expect(find.text('Cảnh báo tải'), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);

      // Bấm vào thẻ thông báo để mở hộp thoại chi tiết
      await tester.tap(find.text('Thông báo khẩn từ Web Admin'));
      await tester.pumpAndSettle();

      // Kiểm tra hộp thoại chi tiết mở ra
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Toàn bộ sinh viên chú ý nộp báo cáo Lab 3 đúng hạn.'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Đã hiểu'), findsOneWidget);

      // Đóng hộp thoại
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
    });
  
    testWidgets(
        'Mark individual announcement as read reduces unread count and updates bell badge',
        (tester) async {
      final testAnnouncements = [
        AnnouncementModel(
          id: 'test_ann_1',
          title: 'Thông báo số 1',
          body: 'Nội dung thông báo số 1',
          category: 'Học vụ',
          targetSemester: 'Học kỳ 3',
          authorName: 'Admin',
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AnnouncementModel(
          id: 'test_ann_2',
          title: 'Thông báo số 2',
          body: 'Nội dung thông báo số 2',
          category: 'Lịch thi',
          targetSemester: 'Học kỳ 3',
          authorName: 'Admin',
          status: 'published',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsStreamProvider.overrideWithValue(
              AsyncValue.data(testAnnouncements),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Lúc đầu có 2 thông báo chưa đọc -> Badge hiển thị 2
      expect(find.text('2'), findsOneWidget);

      // Mở modal
      await tester.tap(find.byTooltip('Hộp thư thông báo'));
      await tester.pumpAndSettle();

      expect(find.text('2 thông báo chưa đọc'), findsOneWidget);

      // Bấm nút "Đã đọc" của thông báo số 1
      final markReadBtn1 = find.byKey(const Key('mark_read_test_ann_1'));
      expect(markReadBtn1, findsOneWidget);
      await tester.tap(markReadBtn1);
      await tester.pumpAndSettle();

      // Còn 1 thông báo chưa đọc
      expect(find.text('1 thông báo chưa đọc'), findsOneWidget);

      // Đóng modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Chuông ngoài màn hình bây giờ hiển thị số 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets(
        'Mark all announcements as read removes red badge from notification bell completely',
        (tester) async {
      final testAnnouncements = [
        AnnouncementModel(
          id: 'test_ann_3',
          title: 'Thông báo số 3',
          body: 'Nội dung thông báo số 3',
          category: 'Học vụ',
          targetSemester: 'Học kỳ 3',
          authorName: 'Admin',
          status: 'published',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            announcementsStreamProvider.overrideWithValue(
              AsyncValue.data(testAnnouncements),
            ),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mở modal
      await tester.tap(find.byTooltip('Hộp thư thông báo'));
      await tester.pumpAndSettle();

      // Bấm "Đã đọc tất cả"
      final markAllBtn = find.byKey(const Key('mark_all_read_btn'));
      expect(markAllBtn, findsOneWidget);
      await tester.tap(markAllBtn);
      await tester.pumpAndSettle();

      // Trạng thái chuyển thành "Đã đọc toàn bộ thông báo"
      expect(find.text('Đã đọc toàn bộ thông báo'), findsOneWidget);
      expect(find.byKey(const Key('mark_all_read_btn')), findsNothing);

      // Đóng modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Chuông không còn Badge đỏ
      expect(find.byType(Badge), findsNothing);
    });
  });
}
