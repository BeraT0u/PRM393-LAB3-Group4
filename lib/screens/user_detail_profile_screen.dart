import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_profile_model.dart';
import '../services/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/completed_courses_viewmodel.dart';
import '../widgets/widgets.dart';
import 'edit_profile_screen.dart';

class UserDetailProfileScreen extends ConsumerStatefulWidget {
  final StudentProfileModel initialProfile;

  const UserDetailProfileScreen({super.key, required this.initialProfile});

  @override
  ConsumerState<UserDetailProfileScreen> createState() =>
      _UserDetailProfileScreenState();
}

class _UserDetailProfileScreenState
    extends ConsumerState<UserDetailProfileScreen> {
  late StudentProfileModel _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(profile: _profile),
      ),
    );

    if (result == true && mounted) {
      final updated = await ref
          .read(studentServiceProvider)
          .getStudentProfile(_profile.uid);
      if (mounted) {
        setState(() {
          _profile = updated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedAsync = ref.watch(completedCoursesViewModelProvider);
    final activeProfile = completedAsync.value?.profile ?? _profile;
    final hasHttpAvatar = activeProfile.avatarUrl != null &&
        activeProfile.avatarUrl!.startsWith('http');

    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      appBar: const AppTopBar(
        title: 'Chi Tiết Hồ Sơ',
        subtitle: 'Thông tin cá nhân sinh viên',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.primaryBlueTonal,
                backgroundImage:
                    hasHttpAvatar ? NetworkImage(activeProfile.avatarUrl!) : null,
                child: !hasHttpAvatar
                    ? Text(
                        activeProfile.avatarInitials,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
                  _buildInfoRow(
                    theme,
                    'Họ và tên',
                    activeProfile.fullName.trim().isEmpty
                        ? 'Chưa có thông tin'
                        : activeProfile.fullName,
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  _buildInfoRow(
                    theme,
                    'Mã sinh viên',
                    activeProfile.studentId.trim().isEmpty
                        ? 'Chưa có thông tin'
                        : activeProfile.studentId,
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  _buildInfoRow(
                    theme,
                    'Email',
                    (activeProfile.email == null ||
                            activeProfile.email!.trim().isEmpty)
                        ? 'Chưa có thông tin'
                        : activeProfile.email!,
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  _buildInfoRow(
                    theme,
                    'Chuyên ngành',
                    activeProfile.major.trim().isEmpty
                        ? 'Chưa có thông tin'
                        : activeProfile.major,
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  _buildInfoRow(
                    theme,
                    'Khóa học',
                    activeProfile.cohort.trim().isEmpty
                        ? 'Chưa có thông tin'
                        : activeProfile.cohort,
                  ),
                  const Divider(
                    height: AppSpacing.xl,
                    color: AppColors.borderStructural,
                  ),
                  _buildInfoRow(
                    theme,
                    'GPA hiện tại / Mục tiêu',
                    '${activeProfile.currentGpa > 0 ? activeProfile.currentGpa.toStringAsFixed(2) : "Chưa có thông tin"} / ${activeProfile.targetGpa > 0 ? activeProfile.targetGpa.toStringAsFixed(2) : "Chưa có thông tin"}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : 'Chưa cập nhật',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
