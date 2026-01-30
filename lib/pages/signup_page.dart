// =============================================================================
// signup_page.dart - PAGE : INSCRIPTION
// =============================================================================
// Formulaire d'inscription pour créer un nouveau compte utilisateur.
// Collecte : nom complet, email, mot de passe et confirmation du mot de passe.
//
// Même pattern que LoginPage : utilise AuthViewModel via Provider.
//
// Navigation :
//   - Succès -> HomePage (avec suppression de toute la pile de navigation)
//   - Lien "Déjà un compte ?" -> retour à LoginPage
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'home_page.dart';

/// Page d'inscription avec formulaire complet.
///
/// Contient 4 champs :
/// - Nom complet (displayName)
/// - Email
/// - Mot de passe
/// - Confirmation du mot de passe
class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Clé de formulaire pour la validation groupée
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour chaque champ de saisie
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // États pour la visibilité des mots de passe
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    // Libérer la mémoire des contrôleurs
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valide le formulaire et crée un nouveau compte via AuthViewModel.
  ///
  /// Flux :
  /// 1. Valide tous les champs (nom non vide, email valide, mots de passe identiques)
  /// 2. Appelle authViewModel.signUp() (Firebase Auth + Firestore)
  /// 3. Si succès -> redirige vers HomePage avec pushAndRemoveUntil
  ///    (supprime TOUTE la pile de navigation pour empêcher le retour)
  /// 4. Si échec -> affiche un SnackBar avec le message d'erreur
  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      final success = await authViewModel.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Inscription réussie -> naviguer vers HomePage
        // pushAndRemoveUntil supprime toutes les pages précédentes de la pile
        // L'utilisateur ne pourra pas revenir à l'écran d'inscription avec "retour"
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false, // false = supprimer TOUTES les routes précédentes
        );
      } else {
        // Inscription échouée -> afficher le message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authViewModel.errorMessage ?? AppConstants.signupError,
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar avec titre "Inscription" et bouton retour automatique
      appBar: AppBar(title: const Text(AppConstants.signupTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Icône d'ajout de personne ---
                  Icon(
                    Icons.person_add_rounded,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Titre ---
                  Text(
                    AppConstants.signupTitle,
                    style: TextStyle(
                      fontSize: AppConstants.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Champ Nom complet ---
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: AppConstants.displayNameLabel,
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.displayNameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Champ Email ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: AppConstants.emailLabel,
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.emailRequired;
                      }
                      if (!value.contains('@')) {
                        return AppConstants.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Champ Mot de passe ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppConstants.passwordLabel,
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.passwordRequired;
                      }
                      if (value.length < 6) {
                        return AppConstants.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Champ Confirmation du mot de passe ---
                  // Ce champ vérifie que l'utilisateur a bien tapé le même mot de passe
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      // Vérifie que la confirmation correspond au mot de passe saisi
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Bouton d'inscription ---
                  // Consumer écoute le ViewModel pour réagir à isLoading
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authViewModel.isLoading
                              ? null // Désactivé pendant le chargement
                              : _handleSignup,
                          child: authViewModel.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(AppConstants.signupButton),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Lien vers la page de connexion ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppConstants.hasAccount),
                      TextButton(
                        onPressed: () {
                          // pop() revient à la page précédente (LoginPage)
                          Navigator.of(context).pop();
                        },
                        child: const Text(AppConstants.loginButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
