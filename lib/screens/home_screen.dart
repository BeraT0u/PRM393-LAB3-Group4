import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.primaryBlue, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text('EduPlan'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.bottomClearanceWithBar,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào sinh viên
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryBlueTonal,
                  child: Text('HL', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chào Hoàng Long 👋', style: theme.textTheme.titleMedium),
                    Text(
                      'Tích lũy: 90/145 TC • GPA mục tiêu: 3.60',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Hero Card Trọng tâm Tuần 8
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🔥 Trọng tâm Tuần 8',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successSurface,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Mục tiêu: Điểm A',
                          style: TextStyle(color: AppColors.successText, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Lập trình Di động (PRM393)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hoàn thiện Lab 2 UI/UX và chuẩn bị tích hợp Firebase cho Lab 3.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 6 / 8,
                      minHeight: 6,
                      backgroundColor: AppColors.borderStructural,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tiến độ tự học: 6 / 8 giờ',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section Tips học tập
            Text('💡 Tips học tập kỳ này', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _buildTipCard(
              context,
              subject: 'SWE302',
              tip: 'Nắm vững C4 Model trong kiến trúc phần mềm để làm tốt báo cáo Assignment.',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildTipCard(
              context,
              subject: 'DBI202',
              tip: 'Ôn tập kỹ Stored Procedure và Trigger trước buổi thực hành Lab cuối kỳ.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Đã học'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Tìm môn'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, {required String subject, required String tip}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.warningText),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            tip,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.warningText),
          ),
        ],
      ),
    );
  }
}
