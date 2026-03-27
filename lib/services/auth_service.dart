import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileComplete => _currentUser?.onboardingCompleted ?? false;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      await _loadUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // ── Email / password ──────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(user.uid).set(user.toMap());
      _currentUser = user;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await _loadUserData(credential.user!.uid);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────
  //
  // Requisitos previos (configuración única por plataforma):
  //   Android → SHA-1 en Firebase Console + google-services.json actualizado
  //   iOS     → URL scheme en Info.plist + GoogleService-Info.plist

  Future<bool> signInWithGoogle() async {
    _clearError();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // usuario canceló el flujo

      _setLoading(true);

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final uid = result.user!.uid;

      // Crear documento solo si es la primera vez
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        final user = UserModel(
          uid: uid,
          email: result.user!.email ?? '',
          displayName: result.user!.displayName ?? 'Atleta',
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(uid).set(user.toMap());
        _currentUser = user;
        notifyListeners();
      }
      // Si el doc ya existe, cargamos explícitamente para garantizar timing
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        notifyListeners();
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setError('Error al conectar con Google. Inténtalo de nuevo.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Recuperación de contraseña ────────────────────────────────────────────

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
    _currentUser = null;
    notifyListeners();
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> updateProfile(UserModel updated) async {
    try {
      await _db.collection('users').doc(updated.uid).set(updated.toMap());
      _currentUser = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // ── Helpers públicos ──────────────────────────────────────────────────────

  void clearError() => _clearError();

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Ese email ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu red e inténtalo de nuevo.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con ese email usando otro método.';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada.';
      default:
        return 'Algo salió mal. Inténtalo de nuevo.';
    }
  }
}
