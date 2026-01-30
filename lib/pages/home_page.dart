// =============================================================================
// home_page.dart - PAGE : ACCUEIL / LISTE DES UTILISATEURS
// =============================================================================
// Page principale de l'application après connexion.
// Affiche la liste de tous les utilisateurs inscrits (sauf soi-même)
// pour permettre d'initier une conversation.
//
// Utilise ChatUserViewModel.getUsersStream() pour afficher les utilisateurs
// en TEMPS RÉEL : si un nouvel utilisateur s'inscrit, il apparaît
// automatiquement dans la liste sans rechargement.
//
// Architecture :
//   - StreamBuilder écoute le Stream Firestore en temps réel
//   - Consumer<ChatUserViewModel> donne accès au ViewModel
//   - Chaque utilisateur est affiché avec un _UserListTile
//
// Navigation :
//   - Clic sur un utilisateur -> ChatPage (conversation)
//   - Bouton profil (AppBar) -> ProfilePage
//   - Bouton déconnexion (AppBar) -> LoginPage
// =============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/chat_user.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/chat_user_viewmodel.dart';
import '../constants.dart';
import 'chat_page.dart';
import 'profile_page.dart';

/// Page d'accueil affichant la liste des utilisateurs disponibles.
///
/// StatelessWidget car tout l'état est géré par les ViewModels et les Streams.
/// Pas besoin d'état local.
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // --- Bouton pour accéder au profil ---
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // --- Bouton de déconnexion ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // context.read<T>() est un raccourci pour Provider.of<T>(listen: false)
              final authViewModel = context.read<AuthViewModel>();
              await authViewModel.logout();
              if (context.mounted) {
                // Redirige vers la page de login et supprime la pile de navigation
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      // Consumer écoute le ChatUserViewModel pour accéder à getUsersStream()
      body: Consumer<ChatUserViewModel>(
        builder: (context, viewModel, child) {
          // StreamBuilder écoute le Stream de Firestore en temps réel
          // À chaque changement dans la collection "users", le builder est rappelé
          return StreamBuilder<List<ChatUser>>(
            stream: viewModel.getUsersStream(),
            builder: (context, snapshot) {
              // État 1 : En attente de la première donnée
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // État 2 : Erreur (problème réseau, permissions Firestore...)
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              // État 3 : Données reçues
              final users = snapshot.data ?? [];

              // Cas : aucun autre utilisateur inscrit
              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun utilisateur disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              // Cas normal : afficher la liste des utilisateurs
              // ListView.builder construit les éléments à la demande (lazy loading)
              // = performant même avec beaucoup d'utilisateurs
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserListTile(user: user);
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Widget privé représentant une ligne d'utilisateur dans la liste.
///
/// Affiche :
/// - L'avatar (image base64 ou initiale du nom)
/// - Le nom de l'utilisateur
/// - La bio (si elle existe)
/// - Une flèche vers la droite (indication de navigation)
///
/// Le underscore _ rend cette classe PRIVÉE (visible uniquement dans ce fichier).
class _UserListTile extends StatelessWidget {
  /// L'utilisateur à afficher dans cette ligne
  final ChatUser user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Avatar à gauche
      leading: _buildAvatar(),
      // Nom de l'utilisateur en titre
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      // Bio en sous-titre (affichée seulement si non vide)
      subtitle: user.bio.isNotEmpty
          ? Text(
              user.bio,
              maxLines: 1, // Maximum 1 ligne
              overflow: TextOverflow.ellipsis, // "..." si trop long
              style: TextStyle(color: Colors.grey[600]),
            )
          : null,
      // Icône flèche à droite (indique qu'on peut cliquer)
      trailing: const Icon(Icons.chevron_right),
      // Action au clic : ouvrir la conversation avec cet utilisateur
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatPage(otherUser: user)),
        );
      },
    );
  }

  /// Construit l'avatar de l'utilisateur.
  ///
  /// Si l'utilisateur a une image en base64 -> affiche l'image
  /// Sinon -> affiche un cercle coloré avec l'initiale du nom
  Widget _buildAvatar() {
    // Vérifie si l'utilisateur a un avatar en base64
    if (user.avatarBase64.isNotEmpty) {
      try {
        // Décode le base64 en bytes (données brutes de l'image)
        final Uint8List bytes = base64Decode(user.avatarBase64);
        // MemoryImage crée une image à partir des bytes en mémoire
        return CircleAvatar(radius: 24, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        debugPrint('Erreur décodage avatar: $e');
      }
    }

    // Avatar par défaut : cercle violet avec la première lettre du nom
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppConstants.primaryColor,
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
