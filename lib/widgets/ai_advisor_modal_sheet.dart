import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_plan_advice_model.dart';
import '../models/course_model.dart';
import '../services/database_seeder.dart';
import '../services/service_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../viewmodels/course_catalog_viewmodel.dart';
import '../viewmodels/plan_analyzer_viewmodel.dart';

class AiAdvisorModalSheet extends ConsumerStatefulWidget {
  const AiAdvisorModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiAdvisorModalSheet(),
    );
  }

  @override
  ConsumerState<AiAdvisorModalSheet> createState() =>
      _AiAdvisorModalSheetState();
}

class _AiAdvisorModalSheetState extends ConsumerState<AiAdvisorModalSheet> {
  bool _isLoading = true;
  AiPlanAdviceModel? _advice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAiAdvice();
  }

  Future<void> _fetchAiAdvice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final planState = ref.read(planAnalyzerViewModelProvider);
      final catalogState = ref.read(courseCatalogViewModelProvider);

      List<CourseModel> allCourses =
          catalogState.value?.allCourses ?? DatabaseSeeder.sampleCourses;
      if (allCourses.isEmpty) {
        allCourses = DatabaseSeeder.sampleCourses;
      }

      final aiService = ref.read(aiAdvisorServiceProvider);
      final result = await aiService.analyzePlanAndAdvise(
        state: planState,
        allCourses: allCourses,
      );

      if (mounted) {
        setState(() {
          _advice = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối AI: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyAiSuggestion(AiPlanAdviceModel advice) {
    final catalogState = ref.read(courseCatalogViewModelProvider);
    List<CourseModel> allCourses =
        catalogState.value?.allCourses ?? DatabaseSeeder.sampleCourses;
    if (allCourses.isEmpty) {
      allCourses = DatabaseSeeder.sampleCourses;
    }

    CourseModel? replacementCourse;
    if (advice.suggestedCourseCode != null) {
      replacementCourse = allCourses.cast<CourseModel?>().firstWhere(
            (c) => c?.code == advice.suggestedCourseCode,
            orElse: () => null,
          );
    }

    ref.read(planAnalyzerViewModelProvider.notifier).replaceConflictCourse(
          replacement: replacementCourse,
          targetCodeToReplace: advice.targetCourseCode,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Đã áp dụng gợi ý của ${advice.providerDisplayName}! '
          'Lộ trình đã cân bằng (${advice.estimatedHoursAfter.toInt()}h/tuần).',
        ),
        backgroundColor: AppColors.successBorder,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : (_error != null
                ? _buildErrorState()
                : (_advice != null ? _buildAdviceContent(_advice!) : const SizedBox())),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.borderStructural,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF4F46E5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Cố vấn AI đang phân tích kế hoạch...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Đang kết nối Gemini 3.8 Flash & DeepSeek để tìm lộ trình cân bằng tối ưu...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.dangerText, size: 36),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _error ?? 'Không thể tải lời khuyên AI.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.dangerText, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: _fetchAiAdvice,
          child: const Text('Thử lại'),
        ),
      ],
    );
  }

  Widget _buildAdviceContent(AiPlanAdviceModel advice) {
    Color providerBg = const Color(0xFFEFF6FF);
    Color providerText = const Color(0xFF2563EB);
    IconData providerIcon = Icons.auto_awesome;

    if (advice.isDeepSeek) {
      providerBg = const Color(0xFFF3E8FF);
      providerText = const Color(0xFF7E22CE);
      providerIcon = Icons.psychology;
    } else if (advice.isFallbackRule) {
      providerBg = const Color(0xFFFEF3C7);
      providerText = const Color(0xFFB45309);
      providerIcon = Icons.rule_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.borderStructural,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Header + Provider Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(providerIcon, color: providerText, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Cố Vấn Học Tập AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: providerBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: providerText.withValues(alpha: 0.3)),
              ),
              child: Text(
                advice.providerDisplayName,
                style: TextStyle(
                  color: providerText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Analysis Text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderStructural),
          ),
          child: Text(
            advice.analysis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Proposed Action Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Đề xuất chiến lược cân bằng:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (advice.targetCourseCode != null && advice.suggestedCourseCode != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Text(
                        '${advice.targetCourseCode} (Nặng)',
                        style: const TextStyle(
                          color: AppColors.dangerText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textSecondary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Text(
                        '${advice.suggestedCourseCode} (Cân bằng)',
                        style: const TextStyle(
                          color: AppColors.successText,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                '• Khối lượng sau khi đổi: ${advice.estimatedHoursAfter.toInt()}h tự học/tuần (Cân bằng ✅)',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF166534),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                advice.reason,
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.3),
              ),
            ],
          ),
        ),

        // Strategic tips if any
        if (advice.strategicTips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Mẹo chiến lược từ Cố vấn:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          for (final tip in advice.strategicTips)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $tip',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.borderStructural),
                ),
                child: const Text('Để sau'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _applyAiSuggestion(advice),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Áp Dụng Gợi Ý Này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
