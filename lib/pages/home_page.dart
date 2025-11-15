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

/// Page d'accueil de l'application
/// Affiche la liste des utilisateurs disponibles pour le chat
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authViewModel = context.read<AuthViewModel>();
              await authViewModel.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Consumer<ChatUserViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder<List<ChatUser>>(
            stream: viewModel.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun utilisateur disponible',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

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

/// Widget représentant un utilisateur dans la liste
class _UserListTile extends StatelessWidget {
  final ChatUser user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildAvatar(),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: user.bio.isNotEmpty
          ? Text(
              user.bio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatPage(otherUser: user)),
        );
      },
    );
  }

  /// Construit l'avatar de l'utilisateur
  Widget _buildAvatar() {
    if (user.avatarBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(user.avatarBase64);
        return CircleAvatar(radius: 24, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        debugPrint('❌ Erreur décodage avatar: $e');
      }
    }

    // Avatar par défaut avec initiale
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
