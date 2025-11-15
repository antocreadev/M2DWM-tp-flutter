import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_user.dart';

/// ViewModel pour gérer l'authentification des utilisateurs
/// Utilise le pattern ChangeNotifier pour notifier les changements d'état
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  ChatUser? _currentChatUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  ChatUser? get currentChatUser => _currentChatUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthViewModel() {
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Gère les changements d'état d'authentification
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      await _loadUserProfile(user.uid);
    } else {
      _currentChatUser = null;
    }
    notifyListeners();
  }

  /// Charge le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentChatUser = ChatUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
    }
  }

  /// Inscription d'un nouvel utilisateur
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔵 Début inscription: $email');

      // Créer le compte Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Compte Firebase créé: ${userCredential.user!.uid}');

      // Créer le profil utilisateur dans Firestore
      final chatUser = ChatUser(
        id: userCredential.user!.uid,
        displayName: displayName,
        email: email,
        bio: '',
        avatarBase64: '', // Pas d'avatar au départ
      );

      debugPrint('🔵 Création du document Firestore...');
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(chatUser.toMap());
      debugPrint('✅ Document Firestore créé');

      // Sauvegarder la session localement
      await _saveSession(userCredential.user!.uid);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      _setLoading(false);
      _handleAuthException(e);
      return false;
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      _setLoading(false);
      _errorMessage = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Connexion d'un utilisateur existant
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sauvegarder la session localement
      await _saveSession(userCredential.user!.uid);

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthException(e);
      return false;
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      await _clearSession();
      _currentUser = null;
      _currentChatUser = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Erreur lors de la déconnexion: $e';
      notifyListeners();
    }
  }

  /// Sauvegarde la session utilisateur localement
  Future<void> _saveSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid);
  }

  /// Supprime la session utilisateur locale
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  /// Récupère l'ID utilisateur de la session locale
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  /// Gère les exceptions Firebase Auth
  void _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        _errorMessage = 'Le mot de passe est trop faible.';
        break;
      case 'email-already-in-use':
        _errorMessage = 'Cet email est déjà utilisé.';
        break;
      case 'user-not-found':
        _errorMessage = 'Aucun utilisateur trouvé avec cet email.';
        break;
      case 'wrong-password':
        _errorMessage = 'Mot de passe incorrect.';
        break;
      case 'invalid-email':
        _errorMessage = 'Email invalide.';
        break;
      case 'user-disabled':
        _errorMessage = 'Ce compte a été désactivé.';
        break;
      case 'too-many-requests':
        _errorMessage = 'Trop de tentatives. Réessayez plus tard.';
        break;
      default:
        _errorMessage = 'Erreur d\'authentification: ${e.message}';
    }
    notifyListeners();
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
