// =============================================================================
// auth_viewmodel.dart - VIEWMODEL : AUTHENTIFICATION
// =============================================================================
// Ce fichier gère toute la LOGIQUE MÉTIER liée à l'authentification :
//   - Inscription (signUp)
//   - Connexion (login)
//   - Déconnexion (logout)
//   - Persistance de session (SharedPreferences)
//   - Gestion des erreurs Firebase Auth
//
// RÔLE D'UN VIEWMODEL dans le pattern MVVM :
//   - Faire le PONT entre la Vue (pages) et les données (Models/Firebase)
//   - Contenir la logique métier (pas dans les pages, pas dans les models)
//   - Gérer l'état de l'application (isLoading, errorMessage, currentUser)
//   - Notifier la Vue quand l'état change (via ChangeNotifier + notifyListeners)
//
// DIFFÉRENCE MODEL vs VIEWMODEL :
//   - MODEL = "quoi" (la STRUCTURE des données : un user a un id, un nom...)
//   - VIEWMODEL = "comment" (la LOGIQUE : comment se connecter, comment gérer
//     les erreurs, quand afficher le chargement, etc.)
//
// Le ViewModel étend ChangeNotifier, ce qui permet aux widgets d'écouter
// les changements d'état et de se reconstruire automatiquement quand
// notifyListeners() est appelé.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/chat_user.dart';

/// ViewModel responsable de l'authentification des utilisateurs.
///
/// Utilise ChangeNotifier pour le pattern Observer :
/// quand l'état change (connexion, déconnexion, erreur), les widgets
/// qui "écoutent" ce ViewModel se reconstruisent automatiquement.
///
/// Utilisé dans : LoginPage, SignupPage, HomePage, ProfilePage
class AuthViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // INSTANCES FIREBASE (services cloud)
  // ---------------------------------------------------------------------------

  /// Instance de Firebase Auth : gère l'authentification (email/mot de passe)
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Instance de Firestore : base de données NoSQL cloud pour les profils
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // ÉTAT INTERNE (variables privées avec underscore _)
  // ---------------------------------------------------------------------------

  /// Utilisateur Firebase Auth actuellement connecté (null si déconnecté)
  /// Contient l'email, l'UID, etc. mais PAS les données de profil (bio, avatar)
  User? _currentUser;

  /// Profil complet de l'utilisateur (données Firestore : nom, bio, avatar)
  /// C'est notre model ChatUser, plus riche que le User Firebase
  ChatUser? _currentChatUser;

  /// Indique si une opération est en cours (pour afficher un spinner)
  bool _isLoading = false;

  /// Message d'erreur à afficher à l'utilisateur (null = pas d'erreur)
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // GETTERS (accès en lecture seule pour les Vues)
  // ---------------------------------------------------------------------------

  /// Utilisateur Firebase Auth (null si non connecté)
  User? get currentUser => _currentUser;

  /// Profil complet ChatUser (null si non chargé)
  ChatUser? get currentChatUser => _currentChatUser;

  /// True si une opération asynchrone est en cours
  bool get isLoading => _isLoading;

  /// Message d'erreur actuel (null = pas d'erreur)
  String? get errorMessage => _errorMessage;

  /// True si un utilisateur est actuellement connecté
  bool get isAuthenticated => _currentUser != null;

  // ---------------------------------------------------------------------------
  // CONSTRUCTEUR
  // ---------------------------------------------------------------------------

  /// Le constructeur s'abonne automatiquement aux changements d'état
  /// d'authentification Firebase. Ainsi, si l'utilisateur se connecte ou
  /// se déconnecte (même depuis un autre appareil), le ViewModel est notifié.
  AuthViewModel() {
    // authStateChanges() retourne un Stream qui émet un événement à chaque
    // changement d'état (connexion, déconnexion, token refresh).
    // .listen() s'abonne à ce stream et appelle _onAuthStateChanged.
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ---------------------------------------------------------------------------
  // MÉTHODES PRIVÉES (logique interne)
  // ---------------------------------------------------------------------------

  /// Callback appelé automatiquement quand l'état d'authentification change.
  /// Si un utilisateur est connecté, on charge son profil Firestore.
  /// Si personne n'est connecté, on efface les données locales.
  Future<void> _onAuthStateChanged(User? user) async {
    _currentUser = user;
    if (user != null) {
      // Un utilisateur est connecté -> charger son profil depuis Firestore
      await _loadUserProfile(user.uid);
    } else {
      // Personne n'est connecté -> effacer le profil local
      _currentChatUser = null;
    }
    // Notifier tous les widgets qui écoutent ce ViewModel
    notifyListeners();
  }

  /// Charge le profil utilisateur depuis la collection "users" de Firestore.
  /// Appelé après chaque connexion/changement d'état auth.
  Future<void> _loadUserProfile(String uid) async {
    try {
      // Récupère le document Firestore de l'utilisateur par son UID
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Convertit les données Firestore en objet ChatUser
        _currentChatUser = ChatUser.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // MÉTHODES PUBLIQUES (appelées par les Vues/Pages)
  // ---------------------------------------------------------------------------

  /// Inscrit un nouvel utilisateur avec email, mot de passe et nom.
  ///
  /// Étapes :
  /// 1. Crée un compte dans Firebase Auth (email + mot de passe)
  /// 2. Crée un document profil dans Firestore (collection "users")
  /// 3. Sauvegarde la session localement (SharedPreferences)
  ///
  /// Retourne true si l'inscription a réussi, false sinon.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    // Active l'indicateur de chargement (le bouton affiche un spinner)
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('Début inscription: $email');

      // ÉTAPE 1 : Créer le compte Firebase Auth
      // Firebase Auth gère le hachage du mot de passe et la validation de l'email
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Compte Firebase créé: ${userCredential.user!.uid}');

      // ÉTAPE 2 : Créer le profil utilisateur dans Firestore
      // Firebase Auth ne stocke que email/password, les données supplémentaires
      // (nom, bio, avatar) sont stockées dans Firestore
      final chatUser = ChatUser(
        id: userCredential.user!.uid,
        displayName: displayName,
        email: email,
        bio: '',
        avatarBase64: '', // Pas d'avatar au départ
      );

      debugPrint('Création du document Firestore...');
      // .set() crée ou remplace le document avec l'UID comme identifiant
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(chatUser.toMap());
      debugPrint('Document Firestore créé');

      // ÉTAPE 3 : Sauvegarder la session localement
      // Permet de restaurer la session au prochain lancement de l'app
      await _saveSession(userCredential.user!.uid);

      _setLoading(false);
      return true; // Inscription réussie
    } on FirebaseAuthException catch (e) {
      // Erreur spécifique Firebase Auth (email déjà utilisé, mot de passe faible...)
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      _setLoading(false);
      _handleAuthException(e); // Traduit le code d'erreur en message français
      return false;
    } catch (e) {
      // Erreur inattendue (réseau, Firestore...)
      debugPrint('Erreur inattendue: $e');
      _setLoading(false);
      _errorMessage = 'Erreur inattendue: $e';
      notifyListeners();
      return false;
    }
  }

  /// Connecte un utilisateur existant avec email et mot de passe.
  ///
  /// Firebase Auth vérifie les identifiants côté serveur.
  /// Si la connexion réussit, _onAuthStateChanged est appelé automatiquement
  /// (car on écoute authStateChanges dans le constructeur).
  ///
  /// Retourne true si la connexion a réussi, false sinon.
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Authentification via Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sauvegarder la session localement
      await _saveSession(userCredential.user!.uid);

      _setLoading(false);
      return true; // Connexion réussie
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

  /// Déconnecte l'utilisateur actuel.
  ///
  /// Étapes :
  /// 1. Déconnexion Firebase Auth (côté serveur)
  /// 2. Suppression de la session locale (SharedPreferences)
  /// 3. Effacement des données en mémoire
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _auth.signOut(); // Déconnexion Firebase
      await _clearSession(); // Suppression session locale
      _currentUser = null; // Effacement mémoire
      _currentChatUser = null;
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _errorMessage = 'Erreur lors de la déconnexion: $e';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // GESTION DE SESSION LOCALE (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// Sauvegarde l'UID de l'utilisateur dans le stockage local du téléphone.
  /// SharedPreferences = petit stockage clé/valeur persistant (comme localStorage en web).
  Future<void> _saveSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid);
  }

  /// Supprime l'UID sauvegardé du stockage local (lors de la déconnexion).
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  /// Récupère l'UID sauvegardé (pour vérifier si une session existe au démarrage).
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // ---------------------------------------------------------------------------
  // GESTION DES ERREURS FIREBASE AUTH
  // ---------------------------------------------------------------------------

  /// Traduit les codes d'erreur Firebase Auth en messages lisibles en français.
  /// Firebase retourne des codes anglais standardisés (ex: 'weak-password').
  /// Cette méthode les convertit en messages compréhensibles pour l'utilisateur.
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
    // Notifie les widgets pour qu'ils affichent le message d'erreur
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // UTILITAIRES INTERNES
  // ---------------------------------------------------------------------------

  /// Met à jour l'état de chargement et notifie les widgets.
  /// Utilisé pour afficher/masquer les spinners dans l'UI.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Efface le message d'erreur (appelé quand l'utilisateur commence à retaper).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
