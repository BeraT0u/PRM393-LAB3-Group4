import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/app_logger.dart';

class UploadProgressInfo {
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  final String? downloadUrl;
  final String? errorMessage;

  const UploadProgressInfo({
    required this.progress,
    this.isCompleted = false,
    this.downloadUrl,
    this.errorMessage,
  });
}

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Tải file PDF bản vẽ kế hoạch lên Firebase Cloud Storage
  /// Đường dẫn cô lập theo từng user: reports/{userId}/{fileName}
  Stream<UploadProgressInfo> uploadReportPdf({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async* {
    yield const UploadProgressInfo(progress: 0.05);

    try {
      final safeFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';
      final storageRef = _storage.ref().child('reports/$userId/$safeFileName');

      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploaded_by': userId,
          'app': 'EduPlan Mobile',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putData(bytes, metadata);

      // Lắng nghe sự kiện tiến trình tải lên
      await for (final snapshot in uploadTask.snapshotEvents) {
        final totalBytes = snapshot.totalBytes;
        final bytesTransferred = snapshot.bytesTransferred;
        final currentProgress = totalBytes > 0 ? (bytesTransferred / totalBytes) : 0.5;

        if (snapshot.state == TaskState.running) {
          yield UploadProgressInfo(progress: currentProgress);
        } else if (snapshot.state == TaskState.success) {
          final downloadUrl = await storageRef.getDownloadURL();
          AppLogger.info('Upload PDF thành công! URL: $downloadUrl');
          yield UploadProgressInfo(
            progress: 1.0,
            isCompleted: true,
            downloadUrl: downloadUrl,
          );
          return;
        } else if (snapshot.state == TaskState.error) {
          yield const UploadProgressInfo(
            progress: 0.0,
            errorMessage: 'Lỗi tải lên Cloud Storage.',
          );
          return;
        }
      }
    } catch (e, st) {
      AppLogger.warning('Lỗi ngoại lệ khi upload lên Firebase Storage: $e');
      AppLogger.error('Storage Exception', e, st);
      yield UploadProgressInfo(
        progress: 0.0,
        errorMessage: 'Không thể kết nối Cloud Storage: ${e.toString()}',
      );
    }
  }
}
