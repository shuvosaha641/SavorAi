import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipeappflutter/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state stream
  Stream<User?> get authStateStream => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _databaseService.createUserDocument(
        userCredential.user!.uid,
        email,
      );

      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
}
