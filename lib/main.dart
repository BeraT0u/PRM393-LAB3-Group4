import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase/firebase_service.dart';
import 'screens/completed_courses_screen.dart';
import 'screens/course_catalog_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/plan_analyzer_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/selected_courses_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase SDK (có fallback offline mượt mà)
  await FirebaseService.initialize();

  runApp(
    const ProviderScope(
      child: EduPlanApp(),
    ),
  );
}

class EduPlanApp extends StatelessWidget {
  const EduPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPlan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.warmPaperTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/completed-courses': (context) => const CompletedCoursesScreen(),
        '/catalog': (context) => const CourseCatalogScreen(),
        '/course-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final code = (args is Map ? args['courseCode'] as String? : (args is String ? args : null)) ?? 'PRM393';
          return CourseDetailScreen(courseCode: code);
        },
        '/plan-analyzer': (context) => const PlanAnalyzerScreen(),
        '/selected-courses': (context) => const SelectedCoursesScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/summary': (context) => const MainScaffold(
              currentTabIndex: 0,
              appBar: AppTopBar(
                title: 'Tổng Kết Kế Hoạch',
                subtitle: 'Fall 2024 • Kế hoạch học tập',
                showBack: true,
              ),
              body: Center(child: Text('SCR-07: Tổng Kết Kế Hoạch Kỳ (Nhóm 5)')),
            ),
      },
    );
  }
}
