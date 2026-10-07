import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import 'api_provider.dart';

class AuthState {
  final User? firebaseUser;
  final UserProfile? userProfile;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.firebaseUser,
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      userProfile != null && (firebaseUser != null || kDebugMode);
  String? get role => userProfile?.role;
  bool get isAdmin => userProfile?.isAdmin ?? false;
  bool get isTutor => userProfile?.isTutor ?? false;
  bool get isParent => userProfile?.isParent ?? false;

  AuthState copyWith({
    User? firebaseUser,
    UserProfile? userProfile,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      firebaseUser: firebaseUser ?? this.firebaseUser,
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  AuthState build() {
    _init();
    return const AuthState(isLoading: true);
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user == null) {
        state = const AuthState(isLoading: false);
      } else {
        await loadUserProfile(user);
      }
    });
  }

  Future<void> loadUserProfile(User user) async {
    state = state.copyWith(firebaseUser: user, isLoading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      final profile = await api.getInitialUserProfile();
      state = state.copyWith(userProfile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to resolve user profile: $e',
        clearProfile: true,
      );
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.trim();
    try {
      UserCredential? cred;
      try {
        cred = await _auth.signInWithEmailAndPassword(email: normalizedEmail, password: password);
      } on FirebaseAuthException catch (authErr) {
        if ((authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') &&
            normalizedEmail == 'admin@classping.com') {
          // Auto-provision initial administrator in Firebase Auth for a fresh application
          try {
            cred = await _auth.createUserWithEmailAndPassword(
              email: normalizedEmail,
              password: password,
            );
            if (cred.user != null) {
              await cred.user!.updateDisplayName('Head Administrator');
            }
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (cred.user != null) {
        await loadUserProfile(cred.user!);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Sign in failed.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled Google sign-in dialog
        state = state.copyWith(isLoading: false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await loadUserProfile(cred.user!);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'Google sign-in could not be completed.');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Google Sign-In: $e');
      return false;
    }
  }

  void loginAsRole(String role) {}

  Future<bool> linkParentPhone() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.linkParentPhone();
      if (_auth.currentUser != null) {
        await loadUserProfile(_auth.currentUser!);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    state = const AuthState(isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).userProfile;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).role;
});
