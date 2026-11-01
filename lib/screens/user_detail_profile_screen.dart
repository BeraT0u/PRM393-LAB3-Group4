import 'package:flutter/material.dart';
import '../models/student_profile_model.dart';
import '../services/student_service.dart';
import 'edit_profile_screen.dart';

class UserDetailProfileScreen extends StatefulWidget {
  final StudentProfileModel profile;

  const UserDetailProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<UserDetailProfileScreen> createState() => _UserDetailProfileScreenState();
}

class _UserDetailProfileScreenState extends State<UserDetailProfileScreen> {
  final _studentService = StudentService();
  late StudentProfileModel _currentProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  // Hàm tải lại dữ liệu hồ sơ mới nhất từ Firestore
  Future<void> _refreshProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = await _studentService.getStudentProfile(
        _currentProfile.uid,
        email: _currentProfile.email,
      );

      setState(() {
        _currentProfile = updatedProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Chỉnh sửa hồ sơ',
            onPressed: () async {
              // Đợi kết quả trả về từ EditProfileScreen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(profile: _currentProfile),
                ),
              );

              // Nếu cập nhật thành công (EditProfileScreen pop về true), tải lại dữ liệu
              if (result == true) {
                _refreshProfile();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFFF3E0),
                    backgroundImage: _currentProfile.avatarUrl != null
                        ? NetworkImage(_currentProfile.avatarUrl!)
                        : null,
                    child: _currentProfile.avatarUrl == null
                        ? Text(
                            _currentProfile.fullName.isNotEmpty
                                ? _currentProfile.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentProfile.fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentProfile.studentId,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Thẻ chi tiết thông tin
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _currentProfile.email ?? 'Chưa cập nhật',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            icon: Icons.school_outlined,
                            label: 'Ngành học',
                            value: 'Kỹ thuật phần mềm',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            icon: Icons.bookmark_outline,
                            label: 'Tín chỉ tích lũy',
                            value: '${_currentProfile.accumulatedCredits} / ${_currentProfile.totalGraduationCredits} TC',
                          ),
                          const Divider(),
                          _buildDetailRow(
                            icon: Icons.star_outline,
                            label: 'GPA hiện tại',
                            value: _currentProfile.currentGpa.toStringAsFixed(2),
                          ),
                          const Divider(),
                          _buildDetailRow(
                            icon: Icons.flag_outlined,
                            label: 'GPA mục tiêu',
                            value: _currentProfile.targetGpa.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}