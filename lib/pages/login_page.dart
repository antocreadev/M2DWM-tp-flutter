// =============================================================================
// login_page.dart - PAGE : CONNEXION
// =============================================================================
// Formulaire de connexion avec email et mot de passe.
//
// Cette page utilise le AuthViewModel via Provider pour :
//   - Appeler la méthode login() quand le formulaire est soumis
//   - Afficher un spinner pendant le chargement (isLoading)
//   - Afficher les messages d'erreur (errorMessage)
//
// C'est un exemple concret de la relation Vue <-> ViewModel dans MVVM :
//   - La VUE (cette page) gère l'affichage et la saisie utilisateur
//   - Le VIEWMODEL (AuthViewModel) gère la logique de connexion
//   - La Vue ne touche JAMAIS directement à Firebase
//
// Navigation :
//   - Succès -> HomePage
//   - Lien "Pas de compte ?" -> SignupPage
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'signup_page.dart';
import 'home_page.dart';

/// Page de connexion avec formulaire email/mot de passe.
///
/// StatefulWidget car elle gère :
/// - L'état du formulaire (validation, contrôleurs de texte)
/// - La visibilité du mot de passe (toggle oeil)
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Clé globale pour identifier et valider le formulaire
  // Permet d'appeler _formKey.currentState!.validate() pour déclencher
  // tous les validators des champs en même temps
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs de texte : permettent de lire/écrire le contenu des TextField
  // et de les nettoyer quand le widget est détruit (dispose)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // État local pour masquer/afficher le mot de passe (icône oeil)
  bool _obscurePassword = true;

  @override
  void dispose() {
    // IMPORTANT : toujours dispose() les contrôleurs pour libérer la mémoire.
    // Si on oublie, cela crée des fuites de mémoire (memory leaks).
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valide le formulaire et tente la connexion via AuthViewModel.
  ///
  /// Flux :
  /// 1. Valide tous les champs (email non vide, mot de passe >= 6 chars)
  /// 2. Appelle authViewModel.login() (qui communique avec Firebase)
  /// 3. Si succès -> redirige vers HomePage
  /// 4. Si échec -> affiche un SnackBar avec le message d'erreur
  Future<void> _handleLogin() async {
    // validate() appelle tous les validators et retourne true si tout est OK
    if (_formKey.currentState!.validate()) {
      // Provider.of<AuthViewModel>(context, listen: false) récupère le ViewModel
      // listen: false = on ne veut PAS reconstruire le widget quand le ViewModel change
      // (on utilise Consumer<> pour ça, voir plus bas)
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Appeler la méthode login du ViewModel
      // .trim() supprime les espaces en début/fin de l'email
      final success = await authViewModel.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Vérifier que le widget est encore monté (l'utilisateur n'a pas quitté la page)
      if (!mounted) return;

      if (success) {
        // Connexion réussie -> naviguer vers la page d'accueil
        // pushReplacement = on remplace la page de login (pas de retour possible)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Connexion échouée -> afficher le message d'erreur dans un SnackBar
        // (barre temporaire en bas de l'écran)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authViewModel.errorMessage ?? AppConstants.loginError,
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
      body: SafeArea(
        // SafeArea évite que le contenu soit caché par la barre de statut (heure, batterie)
        child: Center(
          child: SingleChildScrollView(
            // SingleChildScrollView permet de scroller si le contenu dépasse l'écran
            // (utile quand le clavier s'ouvre et réduit l'espace disponible)
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Form(
              // Le widget Form regroupe les TextFormField et permet la validation groupée
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Logo de l'application ---
                  Icon(
                    Icons.chat_bubble_rounded,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Titre "Connexion" ---
                  Text(
                    AppConstants.loginTitle,
                    style: TextStyle(
                      fontSize: AppConstants.titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Champ Email ---
                  // TextFormField = TextField avec validation intégrée
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress, // Clavier avec @
                    decoration: const InputDecoration(
                      labelText: AppConstants.emailLabel,
                      prefixIcon: Icon(Icons.email), // Icône à gauche
                    ),
                    // Validator : fonction appelée lors de la validation du formulaire
                    // Retourne null si OK, ou un message d'erreur si invalide
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppConstants.emailRequired;
                      }
                      if (!value.contains('@')) {
                        return AppConstants.emailInvalid;
                      }
                      return null; // Pas d'erreur
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Champ Mot de passe ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Masque les caractères (•••••)
                    decoration: InputDecoration(
                      labelText: AppConstants.passwordLabel,
                      prefixIcon: const Icon(Icons.lock),
                      // Bouton oeil pour afficher/masquer le mot de passe
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility // Oeil fermé -> cliquer pour voir
                              : Icons.visibility_off, // Oeil ouvert -> cliquer pour cacher
                        ),
                        onPressed: () {
                          // setState() reconstruit le widget avec la nouvelle valeur
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
                  const SizedBox(height: AppConstants.largePadding),

                  // --- Bouton de connexion ---
                  // Consumer<AuthViewModel> écoute les changements du ViewModel
                  // et reconstruit UNIQUEMENT ce widget (pas toute la page)
                  Consumer<AuthViewModel>(
                    builder: (context, authViewModel, child) {
                      return SizedBox(
                        width: double.infinity, // Bouton pleine largeur
                        child: ElevatedButton(
                          // Désactive le bouton pendant le chargement (onPressed: null)
                          onPressed: authViewModel.isLoading
                              ? null
                              : _handleLogin,
                          // Affiche un spinner OU le texte selon l'état de chargement
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
                              : const Text(AppConstants.loginButton),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // --- Lien vers la page d'inscription ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppConstants.noAccount),
                      TextButton(
                        onPressed: () {
                          // push() ajoute la page d'inscription par-dessus (on peut revenir)
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          );
                        },
                        child: const Text(AppConstants.signupButton),
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
