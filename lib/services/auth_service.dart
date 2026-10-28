import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Đăng nhập bằng Google Account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        AppLogger.info('Người dùng đã hủy hộp thoại đăng nhập Google.');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      AppLogger.info('Đăng nhập Google thành công: ${userCredential.user?.email}');
      return userCredential;
    } catch (e, st) {
      AppLogger.warning('Lỗi đăng nhập Google: $e');
      AppLogger.error('Google Sign-In Exception', e, st);
      rethrow;
    }
  }

  /// Đăng xuất tài khoản
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      AppLogger.info('Đã đăng xuất tài khoản thành công.');
    } catch (e) {
      AppLogger.warning('Lỗi khi đăng xuất: $e');
    }
  }
}
