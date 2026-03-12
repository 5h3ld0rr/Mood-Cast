import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Step 1: Trigger the authentication flow
      await _googleSignIn.initialize(
        serverClientId:
            '138700460734-e2ondshg6he0dj8r0hdsvb5rqurptus0.apps.googleusercontent.com',
      );
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Step 2: Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Step 3: Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Step 4: Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e, stack) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint("Stack trace: $stack");
      rethrow;
    }
  }

  // Email Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      rethrow;
    }
  }

  // Email Sign Up
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        try {
          await credential.user!.reload();
          await credential.user!.sendEmailVerification();
        } catch (vError) {
          debugPrint("Warning: Email verification failed to send: $vError");
          rethrow;
        }
      }
      return credential;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      rethrow;
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint("Email Verification Error: $e");
      rethrow;
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password Reset Error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign-Out Error: $e");
    }
  }

  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        await user.reload();
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user changes
  Stream<User?> get userChanges => _auth.userChanges();

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
