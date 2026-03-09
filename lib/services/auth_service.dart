import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) return null; // Interaction cancelled

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      // In 7.0.0+, accessToken is separated from authentication.
      // idToken is sufficient for Firebase identity verification.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e, stack) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint("Stack trace: $stack");
      return null;
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
      // Send verification email automatically
      if (credential.user != null) {
        try {
          await credential.user!.reload(); // Refresh state
          await credential.user!.sendEmailVerification();
          debugPrint(
            "Verification email requested for ${credential.user!.email}",
          );
        } catch (vError) {
          debugPrint("Warning: Email verification failed to send: $vError");
          // We don't want to fail the whole signup if just the email fails,
          // but we should probably let the user know.
          // For now, rethrow so the UI catches it.
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
        await user.reload(); // Refresh user data
      }
    } catch (e) {
      debugPrint("Update Profile Error: $e");
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user changes (emits on profile updates)
  Stream<User?> get userChanges => _auth.userChanges();

  // Stream of auth changes (emits on sign in/out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
