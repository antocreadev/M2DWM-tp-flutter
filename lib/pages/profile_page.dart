import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../model/chat_user.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../viewmodel/chat_user_viewmodel.dart';
import '../utils/image_helper.dart';
import '../constants.dart';

/// Page de profil utilisateur
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  ChatUser? _currentUser;
  String? _newAvatarBase64;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Charge le profil de l'utilisateur connecté
  Future<void> _loadUserProfile() async {
    final chatUserViewModel = context.read<ChatUserViewModel>();
    final user = await chatUserViewModel.getCurrentUser();

    if (user != null) {
      setState(() {
        _currentUser = user;
        _displayNameController.text = user.displayName;
        _bioController.text = user.bio;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatarSection(),
                  const SizedBox(height: 40),
                  _buildDisplayNameField(),
                  const SizedBox(height: 20),
                  _buildBioField(),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  /// Section avatar avec possibilité de modification
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          _buildAvatar(),
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppConstants.primaryColor,
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                onPressed: _pickImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar de l'utilisateur
  Widget _buildAvatar() {
    final avatarBase64 = _newAvatarBase64 ?? _currentUser?.avatarBase64 ?? '';

    if (avatarBase64.isNotEmpty && ImageHelper.isValidBase64(avatarBase64)) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64);
        return CircleAvatar(
          radius: AppConstants.largeAvatarRadius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint('❌ Erreur décodage avatar: $e');
      }
    }

    // Avatar par défaut
    return CircleAvatar(
      radius: AppConstants.largeAvatarRadius,
      backgroundColor: AppConstants.primaryColor,
      child: Text(
        _currentUser?.displayName.isNotEmpty == true
            ? _currentUser!.displayName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Champ de saisie du nom d'affichage
  Widget _buildDisplayNameField() {
    return TextField(
      controller: _displayNameController,
      decoration: InputDecoration(
        labelText: 'Nom d\'affichage',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }

  /// Champ de saisie de la bio
  Widget _buildBioField() {
    return TextField(
      controller: _bioController,
      decoration: InputDecoration(
        labelText: 'Bio',
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        helperText: 'Une courte description de vous',
      ),
      maxLines: 3,
      maxLength: 150,
    );
  }

  /// Bouton de déconnexion
  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }

  /// Sélectionne une image depuis la galerie
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      // Convertir en base64 avec compression
      final base64String = await ImageHelper.compressAndConvertToBase64(
        image,
        maxSizeInBytes: 500000, // 500KB max
      );

      if (base64String == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image trop volumineuse. Veuillez choisir une image plus petite.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _newAvatarBase64 = base64String;
      });

      debugPrint(
        '✅ Image sélectionnée: ${ImageHelper.getBase64SizeInKB(base64String).toStringAsFixed(2)} KB',
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la sélection de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sauvegarde le profil
  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom d\'affichage ne peut pas être vide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final chatUserViewModel = context.read<ChatUserViewModel>();

    await chatUserViewModel.updateUserProfile(
      displayName: displayName,
      bio: bio,
      avatarBase64: _newAvatarBase64,
    );

    if (mounted) {
      if (chatUserViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatUserViewModel.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// Déconnexion
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.logout();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
