import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../utils/course_filter.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-14 / UC-15: SCR-04 — Course Catalog (danh mục môn mở, tìm kiếm, độ khó tự học)
/// kèm SCR-04_Loading (shimmer) và SCR-04_Empty (không tìm thấy môn).
/// Hỗ trợ filter "Đã xong tiên quyết" (default: off) và chế độ đổi môn thay thế.
class CourseCatalogScreen extends ConsumerStatefulWidget {
  final bool? initialOnlyEligible;
  final String? initialReplacingCourseCode;

  const CourseCatalogScreen({
    super.key,
    this.initialOnlyEligible,
    this.initialReplacingCourseCode,
  });

  @override
  ConsumerState<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends ConsumerState<CourseCatalogScreen> {
  final _searchController = TextEditingController();
  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final bool onlyEligible = args['onlyEligible'] == true || (widget.initialOnlyEligible == true);
        final String? replacingCode = (args['replacingCourseCode'] as String?) ?? widget.initialReplacingCourseCode;
        if (onlyEligible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(courseCatalogViewModelProvider.notifier).setOnlyEligible(
                  true,
                  replacingCourseCode: replacingCode,
                );
          });
        }
      } else if (widget.initialOnlyEligible == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(courseCatalogViewModelProvider.notifier).setOnlyEligible(
                true,
                replacingCourseCode: widget.initialReplacingCourseCode,
              );
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCourse(CourseModel course, {String? replacingCourseCode}) {
    Navigator.of(context).pushNamed(
      '/course-detail',
      arguments: replacingCourseCode != null
          ? {
              'courseCode': course.code,
              'replacingCourseCode': replacingCourseCode,
            }
          : course.code,
    );
  }

  void _handleCourseTap(CourseModel course, String? replacingCourseCode) {
    if (replacingCourseCode != null) {
      _showConfirmReplaceDialog(course, replacingCourseCode);
    } else {
      _openCourse(course);
    }
  }

  void _showConfirmReplaceDialog(CourseModel course, String replacingCourseCode) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlue, size: 26),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Đổi sang môn này?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thay thế môn vi phạm $replacingCourseCode bằng:',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${course.name} (${course.code})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${course.credits} Tín chỉ • Tự học: ${course.plannedSelfStudyHours.toInt()}h/tuần • Tiên quyết: ${course.prerequisiteCode ?? "Không ✅"}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '💡 Kế hoạch học tập sẽ được cân bằng và mở khóa nút Lưu!',
              style: TextStyle(color: AppColors.successText, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              _openCourse(course, replacingCourseCode: replacingCourseCode);
            },
            child: const Text('Xem chiến lược >', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.onPrimaryWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dlgCtx).pop();
              ref.read(planAnalyzerViewModelProvider.notifier).replaceConflictCourse(replacement: course);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Đã đổi sang ${course.code} thành công! Khối lượng tự học đạt 26h Cân bằng.'),
                  backgroundColor: AppColors.primaryBlue,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pushReplacementNamed('/selected-courses');
            },
            child: Text('Đổi sang ${course.code}'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(courseCatalogViewModelProvider.notifier).clearFilters();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(courseCatalogViewModelProvider);
    final vm = ref.read(courseCatalogViewModelProvider.notifier);
    final state = async.value;

    return MainScaffold(
      currentTabIndex: 2,
      appBar: const AppTopBar(title: 'Tìm Môn'),
      body: Column(
        children: [
          // Khối SearchBar & Filter Chips cố định
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  onChanged: (q) {
                    vm.setQuery(q);
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Filter Chips danh mục + Chip "Đã xong tiên quyết" (default: off)
                AppFilterChips(
                  categories: CourseFilter.categories,
                  selectedCategory: state?.category ?? CourseFilter.categoryAll,
                  onSelected: vm.setCategory,
                  trailingChip: _EligibleFilterChip(
                    isSelected: state?.onlyEligible ?? false,
                    onTap: vm.toggleOnlyEligible,
                  ),
                ),
                if (state?.replacingCourseCode != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueTonal,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryBlue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Đổi môn cho ${state!.replacingCourseCode}: Hãy chọn 1 môn đã xong tiên quyết bên dưới',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.bottomClearanceWithBar,
                ),
                child: AppSkeletonLoading(itemCount: 4),
              ),
              error: (e, _) => AppErrorState(
                message: 'Không thể tải danh mục môn học. Vui lòng thử lại.',
                onRetry: vm.reload,
              ),
              data: (data) {
                final courses = data.filteredCourses;
                if (courses.isEmpty) {
                  return AppEmptyState(onAction: data.hasActiveFilter ? _clearFilters : null);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.bottomClearanceWithBar,
                  ),
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) => CourseStrategyCard(
                    course: courses[i],
                    variant: CourseCardVariant.catalog,
                    onTap: () => _handleCourseTap(courses[i], data.replacingCourseCode),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip toggle "Đã xong tiên quyết" (Default: OFF)
class _EligibleFilterChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _EligibleFilterChip({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Bộ lọc Đã xong tiên quyết',
      child: Material(
        color: isSelected ? AppColors.successSurface : AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(
            color: isSelected ? AppColors.successBorder : AppColors.borderStructural,
            width: 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 40,
              minWidth: AppSpacing.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: isSelected ? AppColors.successText : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Đã xong tiên quyết',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.successText : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
