import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../theme/app_dimens.dart';
import '../utils/course_filter.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../widgets/widgets.dart';

/// UC-14 / UC-15: SCR-04 — Course Catalog (danh mục môn mở, tìm kiếm, độ khó tự học)
/// kèm SCR-04_Loading (shimmer) và SCR-04_Empty (không tìm thấy môn).
class CourseCatalogScreen extends ConsumerStatefulWidget {
  const CourseCatalogScreen({super.key});

  @override
  ConsumerState<CourseCatalogScreen> createState() => _CourseCatalogScreenState();
}

class _CourseCatalogScreenState extends ConsumerState<CourseCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCourse(CourseModel course) {
    Navigator.of(context).pushNamed('/course-detail', arguments: course.code);
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
                AppFilterChips(
                  categories: CourseFilter.categories,
                  selectedCategory: state?.category ?? CourseFilter.categoryAll,
                  onSelected: vm.setCategory,
                ),
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
                    onTap: () => _openCourse(courses[i]),
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
