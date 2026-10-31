import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// UC-03: Thanh tìm kiếm (AppSearchBar) & Bộ lọc Filter Chips chuyên ngành
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? semanticsLabel;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Tìm mã môn hoặc tên môn...',
    this.onChanged,
    this.onClear,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller != null && controller!.text.isNotEmpty;

    return Semantics(
      textField: true,
      label: semanticsLabel ?? hintText,
      child: SizedBox(
        height: AppSpacing.minTouchTarget,
        child: TextFormField(
          controller: controller,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Xóa từ khóa',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: () {
                      controller?.clear();
                      onClear?.call();
                      onChanged?.call('');
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Bộ lọc Filter Chips ngang chuẩn thiết kế Figma (Tất cả, Chuyên ngành SE, Cơ sở...)
class AppFilterChips extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final Widget? trailingChip;

  const AppFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    this.trailingChip,
  });

  @override
  Widget build(BuildContext context) {
    final int count = categories.length + (trailingChip != null ? 1 : 0);

    return SizedBox(
      height: AppSpacing.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (trailingChip != null && index == categories.length) {
            return Center(child: trailingChip!);
          }
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Semantics(
            button: true,
            selected: isSelected,
            label: 'Bộ lọc $category',
            child: Center(
              child: Material(
                color: isSelected ? AppColors.primaryBlue : AppColors.surfaceCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: isSelected ? AppColors.primaryBlue : AppColors.borderStructural,
                    width: 1.0,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onSelected(category),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      minWidth: AppSpacing.minTouchTarget,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.onPrimaryWhite : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
