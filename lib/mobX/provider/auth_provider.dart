import 'package:bluetooth_test/mobX/state/auth_error.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthProvider {
  String? get userId;
  Future<bool> deleteAccountAndSignOut();
  Future<void> signOut();

  Future<bool> login({required String email, required String password});
  Future<bool> register({required String email, required String password});
}

class FirebaseAuthProvider implements AuthProvider {
  @override
  Future<bool> deleteAccountAndSignOut() async {
    // TODOimplement deleteAccountAndSignOut
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      // delete the user
      await user.delete();
      // log the user out
      await auth.signOut();

      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> login({required String email, required String password}) async {
    // TODOimplement login
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    }

    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Future<bool> register({required String email, required String password}) async {
    // TODOimplement register
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthError.from(e);
    }

    return FirebaseAuth.instance.currentUser != null;
  }

  @override
  Future<void> signOut() async {
    // TODOimplement signOut

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  @override
  // TODOimplement userId
  String? get userId => FirebaseAuth.instance.currentUser?.uid;
}
