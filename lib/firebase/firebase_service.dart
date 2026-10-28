import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../services/database_seeder.dart';
import '../utils/app_logger.dart';

class FirebaseService {
  static bool isFirebaseInitialized = false;

  static Future<void> initialize() async {
    try {
      // Khởi tạo Firebase SDK
      await Firebase.initializeApp();
      isFirebaseInitialized = true;
      AppLogger.info('Firebase đã được khởi tạo thành công.');

      // Cấu hình Remote Config mặc định
      await _initializeRemoteConfig();

      // Nạp dữ liệu mẫu lên Firestore nếu đang trống
      DatabaseSeeder.seedDatabaseIfEmpty().ignore();
    } catch (e, stack) {
      isFirebaseInitialized = false;
      AppLogger.warning('Firebase chưa thể khởi tạo (đang chạy ở chế độ Local/Fallback): $e');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
    }
  }

  static Future<void> _initializeRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ));

      await remoteConfig.setDefaults(const {
        'max_safe_workload_hours': 25,
        'enable_study_tips': true,
      });

      await remoteConfig.fetchAndActivate();
      AppLogger.info('Remote Config đã đồng bộ: max_hours=${remoteConfig.getInt('max_safe_workload_hours')}');
    } catch (e) {
      AppLogger.warning('Không thể fetch Remote Config từ xa, sử dụng giá trị mặc định (25h): $e');
    }
  }
}
