import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_profile_model.dart';
import '../services/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/completed_courses_viewmodel.dart';
import '../widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final StudentProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _studentIdController;
  late TextEditingController _majorController;
  late TextEditingController _cohortController;
  late TextEditingController _targetGpaController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _studentIdController = TextEditingController(
      text: widget.profile.studentId,
    );
    _majorController = TextEditingController(text: widget.profile.major);
    _cohortController = TextEditingController(text: widget.profile.cohort);
    _targetGpaController = TextEditingController(
      text: widget.profile.targetGpa.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _majorController.dispose();
    _cohortController.dispose();
    _targetGpaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final studentService = ref.read(studentServiceProvider);
      final fullName = _nameController.text.trim();
      final studentId = _studentIdController.text.trim();
      final major = _majorController.text.trim();
      final cohort = _cohortController.text.trim();
      final targetGpa =
          double.tryParse(_targetGpaController.text.trim()) ??
              widget.profile.targetGpa;

      final words = fullName.split(RegExp(r'\s+'));
      final avatarInitials = words.length >= 2
          ? '${words[words.length - 2][0]}${words.last[0]}'.toUpperCase()
          : fullName
              .substring(0, fullName.length >= 2 ? 2 : 1)
              .toUpperCase();
      final hasHttpAvatar = widget.profile.avatarUrl != null &&
          widget.profile.avatarUrl!.startsWith('http');
      final resolvedAvatar =
          hasHttpAvatar ? widget.profile.avatarUrl! : avatarInitials;

      final updatedProfile = widget.profile.copyWith(
        fullName: fullName,
        studentId: studentId,
        major: major,
        cohort: cohort,
        targetGpa: targetGpa.clamp(0.0, 4.0),
        avatarUrl: resolvedAvatar,
        isNewStudent: false,
      );

      await studentService.updateProfile(updatedProfile);
      await ref
          .read(completedCoursesViewModelProvider.notifier)
          .updatePersonalInfo(
            fullName: fullName,
            studentId: studentId,
            major: major,
            cohort: cohort,
            avatarUrl: resolvedAvatar,
            targetGpa: targetGpa.clamp(0.0, 4.0),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: AppColors.successText,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: AppColors.dangerText,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasHttpAvatar = widget.profile.avatarUrl != null &&
        widget.profile.avatarUrl!.startsWith('http');

    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      appBar: const AppTopBar(
        title: 'Chỉnh Sửa Hồ Sơ',
        subtitle: 'Cập nhật thông tin cá nhân',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Center(
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primaryBlueTonal,
                  backgroundImage:
                      hasHttpAvatar ? NetworkImage(widget.profile.avatarUrl!) : null,
                  child: !hasHttpAvatar
                      ? Text(
                          widget.profile.avatarInitials,
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderStructural),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Họ và tên',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _studentIdController,
                      label: 'Mã sinh viên (MSSV)',
                      icon: Icons.badge_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập MSSV'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _majorController,
                      label: 'Chuyên ngành',
                      icon: Icons.school_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập chuyên ngành'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _cohortController,
                      label: 'Khóa học (VD: K18)',
                      icon: Icons.calendar_today_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập khóa học'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTextField(
                      controller: _targetGpaController,
                      label: 'GPA mục tiêu (Hệ 4.0)',
                      icon: Icons.stars_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Vui lòng nhập GPA mục tiêu'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: !_isSaving,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderStructural),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderStructural),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: AppColors.canvasBg,
      ),
    );
  }
}
