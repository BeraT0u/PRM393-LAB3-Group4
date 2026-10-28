import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// UC-08: SCR-01 — Login Screen & SCR-01_Loading
/// Đặc tả kỹ thuật:
/// - Layout: Scaffold(backgroundColor: AppColors.canvasBg) → SafeArea → Padding(16)
///   → Column(mainAxisAlignment: MainAxisAlignment.spaceBetween). Không cuộn.
/// - Components:
///   + Logo EduPlan Master (sổ tay gáy xanh, 64×64 dp).
///   + Khối tiêu đề: "EduPlan" (28sp bold) + Slogan "Lên lịch học thật dễ!".
///   + Nút GoogleSignInButton: Chiều cao 52 dp, nền #FFFFFF, viền #EAE1D0, bo góc 8-12dp, logo Google SVG.
/// - States:
///   + Default: Sẵn sàng tương tác ("Đăng nhập bằng Google").
///   + SCR-01_Loading: Khi bấm, nút hiển thị spinner CircularProgressIndicator(strokeWidth: 2.5)
///     kèm text "Đang xác thực Google...".
class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSignInSuccess;

  const LoginScreen({
    super.key,
    this.onSignInSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  static const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Chuyển sang trạng thái SCR-01_Loading (delay 800ms theo đặc tả handoff)
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.onSignInSuccess != null) {
      widget.onSignInSuccess!();
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hoạ tiết giấy học thuật tinh tế ở 2 góc trên (Khớp SCR-01_Login.png)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Transform.rotate(
                          angle: 0.25,
                          child: Icon(
                            Icons.attach_file_rounded,
                            size: 42,
                            color: AppColors.borderStructural.withValues(alpha: 0.75),
                          ),
                        ),
                        Icon(
                          Icons.star_border_rounded,
                          size: 42,
                          color: AppColors.borderStructural.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),

                  // Thẻ Đăng nhập chính ở trung tâm màn hình
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderStructural, width: 1.0),
                      boxShadow: AppElevation.softShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hàng Logo EduPlan Master (64x64 dp) + Tiêu đề "EduPlan" (28sp Bold)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.borderStructural),
                                      ),
                                      child: const Icon(
                                        Icons.menu_book_rounded,
                                        color: AppColors.primaryBlue,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primaryBlue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'EduPlan',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Slogan phụ đề
                        Semantics(
                          label: 'Lập kế hoạch & Chiến lược học tập thông minh',
                          child: Text(
                            'Lên lịch học thật dễ!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Đường kẻ phân cách ngắn
                        Container(
                          width: 44,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: AppColors.borderStructural,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Nút GoogleSignInButton (Chiều cao chuẩn 52dp, nền #FFFFFF, viền #EAE1D0)
                        Semantics(
                          button: true,
                          enabled: !_isLoading,
                          label: _isLoading
                              ? 'Đang xác thực Google...'
                              : 'Đăng nhập bằng Google',
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLowest,
                                foregroundColor: AppColors.textPrimary,
                                disabledBackgroundColor: AppColors.surfaceLowest,
                                side: const BorderSide(
                                  color: AppColors.borderStructural,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              child: _isLoading
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primaryBlue,
                                          ),
                                        ),
                                        SizedBox(width: AppSpacing.md),
                                        Flexible(
                                          child: Text(
                                            'Đang xác thực Google...',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.string(
                                          _googleLogoSvg,
                                          width: 22,
                                          height: 22,
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Flexible(
                                          child: Text(
                                            'Đăng nhập bằng Google',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chân trang: Các điểm nổi bật (Khớp SCR-01_Login.png)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 16,
                              color: AppColors.warningText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Xếp lịch thông minh',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.borderStructural,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 15,
                              color: AppColors.warningText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Không trùng môn',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
