import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// UC-07: Khung điều hướng chung MainScaffold, AppTopBar & Responsive NavigationRail (Width >= 600dp)
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showLogo;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? trailingWidget;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = false,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.trailingWidget,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 68.0 : 60.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: AppColors.canvasBg,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: AppSpacing.lg,
      shape: const Border(
        bottom: BorderSide(color: AppColors.borderStructural, width: 1.0),
      ),
      title: Row(
        children: [
          if (showBack) ...[
            Semantics(
              button: true,
              label: 'Quay lại màn hình trước',
              child: SizedBox(
                width: AppSpacing.minTouchTarget,
                height: AppSpacing.minTouchTarget,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ] else if (showLogo) ...[
            Image.asset(
              'assets/images/logo.png',
              width: 38,
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryBlue,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailingWidget!,
          ],
        ],
      ),
      actions: actions,
    );
  }
}

/// Khung Scaffold dùng chung cho toàn ứng dụng
/// - Hỗ trợ hiển thị/ẩn Bottom Navigation Bar theo quy chuẩn từng màn hình
/// - Tự động chuyển sang NavigationRail + căn giữa maxWidth 540dp trên màn hình rộng >= 600dp
class MainScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final int currentTabIndex;
  final ValueChanged<int>? onTabSelected;
  final bool showBottomBar;
  final Widget? dockedFooter;

  const MainScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.currentTabIndex = 0,
    this.onTabSelected,
    this.showBottomBar = true,
    this.dockedFooter,
  });

  void _handleDefaultTabTap(BuildContext context, int index) {
    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    if (index == currentTabIndex) return;

    final routes = ['/home', '/completed-courses', '/catalog', '/profile'];
    if (index >= 0 && index < routes.length) {
      Navigator.of(context).pushReplacementNamed(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth >= 600.0;

        final Widget constrainedBody = isWideScreen
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540.0),
                  child: body,
                ),
              )
            : body;

        return Scaffold(
          backgroundColor: AppColors.canvasBg,
          appBar: appBar,
          body: Row(
            children: [
              if (isWideScreen && showBottomBar) ...[
                NavigationRail(
                  backgroundColor: AppColors.surfaceCard,
                  selectedIndex: currentTabIndex,
                  onDestinationSelected: (idx) => _handleDefaultTabTap(context, idx),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: AppColors.primaryBlueTonal,
                  selectedIconTheme: const IconThemeData(color: AppColors.primaryBlue),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
                  selectedLabelTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Trang chủ'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check_rounded),
                      label: Text('Đã học'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_rounded),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: Text('Tìm môn'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Cá nhân'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.borderStructural),
              ],
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: constrainedBody),
                    if (dockedFooter != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border(
                              top: BorderSide(color: AppColors.borderStructural, width: 1.0),
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                          ),
                          child: isWideScreen
                              ? Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 540.0),
                                    child: dockedFooter!,
                                  ),
                                )
                              : dockedFooter!,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: (!isWideScreen && showBottomBar)
              ? Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.borderStructural, width: 1.0),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentTabIndex,
                    onDestinationSelected: (idx) => _handleDefaultTabTap(context, idx),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Trang chủ',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.fact_check_outlined),
                        selectedIcon: Icon(Icons.fact_check_rounded),
                        label: 'Đã học',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.search_rounded),
                        selectedIcon: Icon(Icons.search_rounded),
                        label: 'Tìm môn',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline_rounded),
                        selectedIcon: Icon(Icons.person_rounded),
                        label: 'Cá nhân',
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
