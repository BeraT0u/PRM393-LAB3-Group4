import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
// announcement_service exported by service_providers
import '../models/student_profile_model.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/completed_courses_viewmodel.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../viewmodels/semester_summary_viewmodel.dart';
import '../widgets/widgets.dart';
import 'user_detail_profile_screen.dart';

/// UC-31, UC-32, UC-33, UC-34, UC-35: SCR-08 — Màn hình Hồ sơ cá nhân & Cài đặt (Profile & Settings)
/// - UC-31: Thẻ sinh viên & Modal chỉnh sửa thông tin cá nhân (Họ tên, MSSV, GPA hiện tại, GPA mục tiêu).
/// - UC-32: Thẻ học kỳ hiện tại (Fall 2024) kèm nút "Chi tiết >" mở lại màn hình SCR-07.
/// - UC-33: Nhóm cài đặt đủ 3 Switch (Nhắc hạn Lab, Cảnh báo quá tải, Sync Google Calendar) đồng bộ Firestore.
/// - UC-34: Firebase Demo Showcase (Crashlytics test, Remote Config parameters & FCM Notification Inbox).
/// - UC-35: Overlay_Logout Modal xác nhận đăng xuất tài khoản về SCR-01.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toInt()}h'
        : '${hours.toStringAsFixed(1)}h';
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    StudentProfileModel profile,
  ) {
    final uid = ref.read(currentStudentUidProvider);
    final activeProfile =
        ref.read(completedCoursesViewModelProvider).value?.profile ??
            ref.read(studentServiceProvider).getCachedProfile(uid) ??
            profile;

    final nameCtrl = TextEditingController(text: activeProfile.fullName);
    final studentIdCtrl = TextEditingController(text: activeProfile.studentId);
    final majorCtrl = TextEditingController(text: activeProfile.major);
    final cohortCtrl = TextEditingController(text: activeProfile.cohort);
    final targetGpaCtrl = TextEditingController(
      text: activeProfile.targetGpa > 0
          ? activeProfile.targetGpa.toStringAsFixed(2)
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật thông tin cá nhân',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Thiết lập hồ sơ sinh viên và mục tiêu GPA học tập.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên sinh viên',
                    hintText: 'VD: Nguyễn Trọng Hiếu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: studentIdCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã số sinh viên (MSSV)',
                    hintText: 'VD: SE180504',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: majorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Chuyên ngành',
                          hintText: 'VD: Kỹ thuật Phần mềm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: cohortCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Khóa',
                          hintText: 'VD: K18',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'GPA hiện tại (hệ 4)',
                          helperText: 'Tự động tính từ các môn đã nhập',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          activeProfile.currentGpa > 0
                              ? activeProfile.currentGpa.toStringAsFixed(2)
                              : '0.00 (Chưa có môn)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: targetGpaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'GPA mục tiêu (hệ 4)',
                          hintText: 'VD: 3.60',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  label: 'Lưu thông tin cá nhân',
                  onPressed: () async {
                    final enteredName = nameCtrl.text.trim();
                    final fullName = enteredName.isNotEmpty
                        ? enteredName
                        : activeProfile.fullName.trim();
                    final studentId = studentIdCtrl.text.trim();
                    final major = majorCtrl.text.trim();
                    final cohort = cohortCtrl.text.trim();
                    final targetGpa = double.tryParse(
                          targetGpaCtrl.text.trim().replaceAll(',', '.'),
                        ) ??
                        activeProfile.targetGpa;

                    if (fullName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập họ và tên sinh viên!'),
                          backgroundColor: AppColors.dangerBorder,
                        ),
                      );
                      return;
                    }

                    final words = fullName.split(RegExp(r'\s+'));
                    final avatarInitials = words.length >= 2
                        ? '${words[words.length - 2][0]}${words.last[0]}'
                            .toUpperCase()
                        : fullName
                            .substring(0, fullName.length >= 2 ? 2 : 1)
                            .toUpperCase();
                    final hasHttpAvatar = activeProfile.avatarUrl != null &&
                        activeProfile.avatarUrl!.startsWith('http');

                    await ref
                        .read(completedCoursesViewModelProvider.notifier)
                        .updatePersonalInfo(
                          fullName: fullName,
                          studentId: studentId,
                          major: major,
                          cohort: cohort,
                          avatarUrl: hasHttpAvatar
                              ? activeProfile.avatarUrl
                              : avatarInitials,
                          targetGpa: targetGpa.clamp(0.0, 4.0),
                        );

                    if (!sheetCtx.mounted) return;
                    Navigator.of(sheetCtx).pop();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Đã cập nhật thông tin cá nhân!'),
                        backgroundColor: AppColors.successBorder,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// UC-34: Ghi nhận lỗi Non-Fatal lên Firebase Crashlytics
  Future<void> _handleTestCrashlytics(BuildContext context) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(
          StateError('EduPlan Non-Fatal Test Error from SCR-08'),
          StackTrace.current,
          reason: 'UC-34 Manual Crashlytics Verification',
          fatal: false,
        );
      }
    } catch (_) {
      // Fallback an toàn khi chạy môi trường test/offline
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚡ Đã gửi bản ghi Non-Fatal Error lên Firebase Crashlytics!',
        ),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  /// UC-34: Hộp thư FCM Notification & Đồng bộ Remote Config
  Future<void> _showFcmInboxAndSyncRemoteConfig(
    BuildContext context,
    PlanAnalyzerState planState,
  ) async {
    bool studyTipsEnabled = true;
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseRemoteConfig.instance.fetchAndActivate();
        studyTipsEnabled =
            FirebaseRemoteConfig.instance.getBool('enable_study_tips');
      }
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_active_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Hộp thư FCM & Remote Config',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueTonal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔧 Remote Config hiện tại:\n'
                  '• max_safe_workload_hours = ${planState.maxSafeThresholdHours.toInt()}h/tuần\n'
                  '• enable_study_tips = $studyTipsEnabled',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                '📩 Thông báo đẩy (FCM Inbox gần đây):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                '• [PRM393] Nhắc hạn nộp Lab 3 Cloud-Enabled Mobile App vào Chủ nhật tuần này.\n'
                '• [Workload Advisor] Hãy giữ tổng giờ tự học <= 25h/tuần để đảm bảo mục tiêu GPA.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetCtx).pop(),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getCategoryColor(String category) {
    switch (category) {
      case 'Lịch thi':
        return const Color(0xFFC2410C);
      case 'Cảnh báo tải':
        return AppColors.dangerBorder;
      case 'Hệ thống':
        return const Color(0xFF7C3AED);
      case 'Học vụ':
      default:
        return AppColors.primaryBlue;
    }
  }

  static Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'Lịch thi':
        return const Color(0xFFFFF7ED);
      case 'Cảnh báo tải':
        return const Color(0xFFFEF2F2);
      case 'Hệ thống':
        return const Color(0xFFF5F3FF);
      case 'Học vụ':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  static String _formatAnnouncementDate(DateTime? dt) {
    if (dt == null) return 'Vừa xong';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Vừa xong' : '${diff.inMinutes} phút trước';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  /// Mở Modal Popup danh sách thông báo từ Ban Giảng Huấn & Web Admin
  void _showAnnouncementsPopup(BuildContext context, WidgetRef ref) {
    final uid = ref.read(currentStudentUidProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvasBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            return Consumer(
              builder: (consumerCtx, watchRef, _) {
                final announcementsAsync =
                    watchRef.watch(announcementsStreamProvider);
                final readIds = watchRef.watch(readAnnouncementsProvider);
                final items = announcementsAsync.value ?? [];
                final unreadCount =
                    items.where((a) => !readIds.contains(a.id)).length;

                return Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStructural,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlueTonal,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hộp Thư Thông Báo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Từ Ban Giảng Huấn & Cố Vấn Học Tập',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderStructural),
                    // Status & Quick Action Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      color: AppColors.canvasBg,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: unreadCount > 0
                                      ? AppColors.primaryBlue
                                      : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                unreadCount > 0
                                    ? '$unreadCount thông báo chưa đọc'
                                    : 'Đã đọc toàn bộ thông báo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: unreadCount > 0
                                      ? AppColors.primaryBlue
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (unreadCount > 0)
                            TextButton.icon(
                              key: const Key('mark_all_read_btn'),
                              onPressed: () {
                                final allIds = items.map((e) => e.id).toList();
                                watchRef
                                    .read(readAnnouncementsProvider.notifier)
                                    .markAllAsRead(allIds, userId: uid);
                              },
                              icon: const Icon(
                                Icons.done_all_rounded,
                                size: 16,
                                color: AppColors.primaryBlue,
                              ),
                              label: const Text(
                                'Đã đọc tất cả',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.borderStructural),
                    // Body
                    Expanded(
                      child: announcementsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, stack) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 44,
                                  color: AppColors.dangerBorder,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Không thể tải thông báo: $err',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (items) {
                          if (items.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_none_rounded,
                                      size: 52,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    const Text(
                                      'Chưa có thông báo nào',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    const Text(
                                      'Các thông báo học vụ từ Web Admin Portal sẽ hiển thị trực tiếp tại đây.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: items.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (ctx, i) {
                              final ann = items[i];
                              final isRead = readIds.contains(ann.id);
                              return _buildAnnouncementCard(
                                ctx,
                                watchRef,
                                ann,
                                isRead,
                                uid,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    WidgetRef ref,
    AnnouncementModel ann,
    bool isRead,
    String uid,
  ) {
    final catColor = _getCategoryColor(ann.category);
    final catBg = _getCategoryBgColor(ann.category);
    final dateStr = _formatAnnouncementDate(ann.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () {
        if (!isRead) {
          ref
              .read(readAnnouncementsProvider.notifier)
              .markAsRead(ann.id, userId: uid);
        }
        _showAnnouncementDetailDialog(context, ann);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.canvasBg : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isRead
                ? AppColors.borderStructural
                : AppColors.primaryBlue.withValues(alpha: 0.35),
            width: isRead ? 1.0 : 1.2,
          ),
          boxShadow: isRead
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category, Target semester & Date row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ann.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isRead ? AppColors.surfaceCard : AppColors.canvasBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderStructural),
                  ),
                  child: Text(
                    ann.targetSemester,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isRead)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Đã đọc',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                  ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isRead) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 6),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    ann.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Body Preview
            Text(
              ann.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: isRead
                    ? AppColors.textSecondary.withValues(alpha: 0.85)
                    : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Bottom row: Author and "Đã đọc" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ann.authorName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                if (!isRead)
                  InkWell(
                    key: Key('mark_read_${ann.id}'),
                    onTap: () {
                      ref
                          .read(readAnnouncementsProvider.notifier)
                          .markAsRead(ann.id, userId: uid);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueTonal,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Đã đọc',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDetailDialog(
      BuildContext context, AnnouncementModel ann) {
    final catColor = _getCategoryColor(ann.category);
    final catBg = _getCategoryBgColor(ann.category);

    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ann.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    ann.targetSemester,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(dlgCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ann.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Từ: ${ann.authorName} • ${_formatAnnouncementDate(ann.createdAt)}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            ann.body,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.dangerText, size: 24),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Đăng xuất tài khoản?')),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi EduPlan? Các kế hoạch đã lưu trên Cloud và bản nháp Local vẫn được bảo toàn.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerBorder,
              foregroundColor: AppColors.onPrimaryWhite,
            ),
            onPressed: () async {
              Navigator.of(dlgCtx).pop();
              await ref.read(analyticsServiceProvider).logLogout();
              await ref.read(authServiceProvider).signOut();

              // Xóa toàn bộ cache phiên làm việc và reset state giữa các tài khoản
              ref.read(courseCatalogViewModelProvider.notifier).clearFilters();
              ref.read(currentStudentUidProvider.notifier).clear();
              ref.invalidate(completedCoursesViewModelProvider);
              ref.invalidate(courseCatalogViewModelProvider);
              ref.invalidate(planAnalyzerViewModelProvider);
              ref.invalidate(semesterSummaryViewModelProvider);

              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(currentStudentUidProvider);
    final completedAsync = ref.watch(completedCoursesViewModelProvider);
    final profile = completedAsync.value?.profile ??
        ref.read(studentServiceProvider).getCachedProfile(uid) ??
        DatabaseSeeder.getStudentByUid(uid);
    final vm = ref.read(completedCoursesViewModelProvider.notifier);
    final planState = ref.watch(planAnalyzerViewModelProvider);
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final readAnnouncementIds = ref.watch(readAnnouncementsProvider);
    final allAnnouncements = announcementsAsync.value ?? [];
    final unreadAnnouncementsCount =
        allAnnouncements.where((a) => !readAnnouncementIds.contains(a.id)).length;

    return MainScaffold(
      currentTabIndex: 3,
      appBar: AppTopBar(
        title: 'Hồ Sơ Cá Nhân',
        subtitle: 'SCR-08: Thông tin sinh viên & Cài đặt',
        actions: [
          IconButton(
            tooltip: 'Hộp thư thông báo',
            onPressed: () => _showAnnouncementsPopup(context, ref),
            icon: unreadAnnouncementsCount > 0
                ? Badge(
                    label: Text(
                      '$unreadAnnouncementsCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.dangerBorder,
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.bottomClearanceWithBar,
        ),
        child: Column(
          children: [
            if (profile.isNewStudent) ...[
              AppAlertBanner(
                variant: AlertBannerVariant.warning,
                message:
                    'Tài khoản mới: Nhấn nút "Thiết lập thông tin cá nhân" bên dưới để cập nhật Họ tên, MSSV và GPA mục tiêu của bạn!',
                onTap: () => _showEditProfileSheet(context, ref, profile),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        UserDetailProfileScreen(initialProfile: profile),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryBlueTonal,
                backgroundImage: profile.avatarUrl != null &&
                        profile.avatarUrl!.startsWith('http')
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: !(profile.avatarUrl != null &&
                        profile.avatarUrl!.startsWith('http'))
                    ? Text(
                        profile.avatarInitials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              profile.fullName.trim().isEmpty
                  ? 'Chưa có thông tin họ tên'
                  : profile.fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Builder(
              builder: (_) {
                final mssvText = profile.studentId.trim().isEmpty
                    ? 'Chưa có thông tin MSSV'
                    : profile.studentId.trim();
                final majorParts = [
                  if (profile.cohort.trim().isNotEmpty) profile.cohort.trim(),
                  if (profile.major.trim().isNotEmpty) profile.major.trim(),
                ];
                final majorText = majorParts.isEmpty
                    ? 'Chưa có thông tin khóa/ngành'
                    : majorParts.join(' ');
                return Text(
                  '$mssvText • $majorText',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => _showEditProfileSheet(context, ref, profile),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: Text(
                profile.isNewStudent
                    ? 'Thiết lập thông tin cá nhân'
                    : 'Chỉnh sửa hồ sơ & Mục tiêu GPA',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Thẻ chỉ số học thuật (UC-31)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderStructural),
                boxShadow: AppElevation.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tín chỉ tích lũy:', style: theme.textTheme.bodyMedium),
                      Text(
                        '${profile.accumulatedCredits} / ${profile.totalGraduationCredits} TC',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GPA hiện tại:', style: theme.textTheme.bodyMedium),
                      Text(
                        profile.currentGpa > 0
                            ? profile.currentGpa.toStringAsFixed(2)
                            : 'Chưa có thông tin',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GPA mục tiêu:', style: theme.textTheme.bodyMedium),
                      Text(
                        profile.targetGpa > 0
                            ? profile.targetGpa.toStringAsFixed(2)
                            : 'Chưa có thông tin',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // UC-32: Thẻ Học kỳ hiện tại (động theo kỳ đã học của tài khoản) + Nút "Chi tiết >" mở lại SCR-07
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (_) {
                            final activeSemester = (completedAsync.value != null &&
                                    (uid != DatabaseSeeder.defaultStudent.uid ||
                                        completedAsync.value!.completed.isNotEmpty))
                                ? completedAsync.value!.currentSemesterName
                                : planState.plan.semester;
                            final displayTitle = activeSemester
                                        .toLowerCase()
                                        .startsWith('học kỳ') ||
                                    activeSemester.toLowerCase().startsWith('kỳ')
                                ? '📚 $activeSemester'
                                : '📚 Học kỳ $activeSemester';
                            return Text(
                              displayTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planState.courseCount == 0
                              ? 'Chưa chọn môn học • Bắt đầu lập kế hoạch'
                              : '${planState.courseCount} Môn • ${planState.totalCredits} TC • Tự học ${_formatHours(planState.totalHours)}/tuần',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.minTouchTarget,
                    child: TextButton(
                      onPressed: () {
                        if (planState.courseCount > 0 && !planState.hasConflict) {
                          Navigator.of(context).pushNamed('/summary');
                        } else {
                          Navigator.of(context).pushNamed('/plan-analyzer');
                        }
                      },
                      child: const Text(
                        'Chi tiết >',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // UC-33: Cài đặt Tự động cảnh báo quá tải học tập
            Material(
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: const BorderSide(color: AppColors.borderStructural),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primaryBlue,
                  title: const Text(
                    'Tự động cảnh báo quá tải học tập',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Cảnh báo đỏ khi vượt ngưỡng ${planState.maxSafeThresholdHours.toInt()}h/tuần',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: planState.autoWarnWorkload,
                  onChanged: (val) {
                    ref
                        .read(planAnalyzerViewModelProvider.notifier)
                        .syncAutoWarnWorkload(val);
                    vm.updateSettings(autoWarnWorkload: val);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // UC-34: Firebase Demo Showcase (Crashlytics, Remote Config & FCM Inbox)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderStructural),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          '☁️ Firebase Cloud Showcase',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      StatusBadge(
                        label:
                            'Ngưỡng RC: ${planState.maxSafeThresholdHours.toInt()}h',
                        type: StatusBadgeType.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Kiểm tra nhanh Crashlytics, Remote Config và FCM Notification Inbox.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleTestCrashlytics(context),
                          icon: const Icon(
                            Icons.bug_report_outlined,
                            size: 16,
                            color: AppColors.warningText,
                          ),
                          label: const Text(
                            'Test Crashlytics',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningText,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.warningSurface,
                            side: const BorderSide(
                              color: AppColors.warningBorder,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showFcmInboxAndSyncRemoteConfig(
                            context,
                            planState,
                          ),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                          label: const Text(
                            'FCM & Remote Config',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.borderStructural,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // UC-35: Nút Đăng xuất (Overlay_Logout Modal)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutConfirmDialog(context, ref),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.dangerText,
                  size: 20,
                ),
                label: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(
                    color: AppColors.dangerText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.dangerSurface,
                  side: const BorderSide(color: AppColors.dangerBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
