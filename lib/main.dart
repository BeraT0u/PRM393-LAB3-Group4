import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase/firebase_service.dart';
import 'screens/completed_courses_screen.dart';
import 'screens/course_catalog_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

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
        '/course-detail': (context) => CourseDetailScreen(
              courseCode: (ModalRoute.of(context)?.settings.arguments as String?) ?? 'PRM393',
            ),
      },
    );
  }
}
