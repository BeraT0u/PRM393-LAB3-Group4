import 'package:flutter/material.dart';
import '../models/student_profile_model.dart';
import '../services/student_service.dart';

class EditProfileScreen extends StatefulWidget {
  final StudentProfileModel profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();

  late TextEditingController _fullNameController;
  late TextEditingController _studentIdController;
  late TextEditingController _targetGpaController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _studentIdController = TextEditingController(text: widget.profile.studentId);
    _targetGpaController =
        TextEditingController(text: widget.profile.targetGpa.toString());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _targetGpaController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final double? parsedGpa = double.tryParse(_targetGpaController.text.trim());

      await _studentService.updatePersonalInfo(
        uid: widget.profile.uid,
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        targetGpa: parsedGpa,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        // Trở về màn hình trước đó và đóng màn hình edit
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu hồ sơ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa thông tin'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar xem trước
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: const Color(0xFFFFF3E0),
                  backgroundImage: widget.profile.avatarUrl != null
                      ? NetworkImage(widget.profile.avatarUrl!)
                      : null,
                  child: widget.profile.avatarUrl == null
                      ? Text(
                          widget.profile.fullName.isNotEmpty
                              ? widget.profile.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Ô nhập Họ và Tên
              TextFormField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ô nhập Mã sinh viên
              TextFormField(
                controller: _studentIdController,
                decoration: InputDecoration(
                  labelText: 'Mã sinh viên',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã sinh viên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ô nhập GPA mục tiêu
              TextFormField(
                controller: _targetGpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'GPA mục tiêu',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập GPA mục tiêu';
                  }
                  final gpa = double.tryParse(value);
                  if (gpa == null || gpa < 0.0 || gpa > 4.0) {
                    return 'GPA phải nằm trong khoảng từ 0.0 đến 4.0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Nút Lưu thay đổi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
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
}