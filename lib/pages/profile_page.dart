// =============================================================================
// profile_page.dart - PAGE : PROFIL UTILISATEUR
// =============================================================================
// Page permettant à l'utilisateur de voir et modifier son profil :
//   - Changer son avatar (sélection depuis la galerie photo)
//   - Modifier son nom d'affichage
//   - Modifier sa bio
//   - Se déconnecter
//
// ViewModels utilisés :
//   - ChatUserViewModel : lire et mettre à jour le profil
//   - AuthViewModel : déconnexion
//
// Package externe : image_picker (pour sélectionner une photo)
// Utilitaire : ImageHelper (conversion image -> base64)
// =============================================================================

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

/// Page de profil utilisateur avec édition.
///
/// StatefulWidget car elle gère :
/// - Le chargement initial du profil (async dans initState)
/// - Les contrôleurs de texte (nom, bio)
/// - L'aperçu du nouvel avatar avant sauvegarde
/// - L'état de chargement
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Contrôleurs pour les champs de texte
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Instance du sélecteur d'image (galerie photo)
  final ImagePicker _imagePicker = ImagePicker();

  // Profil de l'utilisateur connecté (chargé depuis Firestore)
  ChatUser? _currentUser;

  // Nouvel avatar sélectionné (en base64, null si pas de changement)
  // On le garde en mémoire jusqu'à ce que l'utilisateur clique "Enregistrer"
  String? _newAvatarBase64;

  // Indicateur de chargement initial
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Charger le profil au démarrage de la page
    _loadUserProfile();
  }

  /// Charge le profil de l'utilisateur connecté depuis Firestore.
  /// Remplit les champs de texte avec les données actuelles.
  Future<void> _loadUserProfile() async {
    final chatUserViewModel = context.read<ChatUserViewModel>();
    final user = await chatUserViewModel.getCurrentUser();

    if (user != null) {
      setState(() {
        _currentUser = user;
        // Pré-remplir les champs avec les données actuelles
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
          // Bouton "Enregistrer" dans l'AppBar
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
      // Affiche un spinner pendant le chargement initial du profil
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Section avatar avec bouton caméra
                  _buildAvatarSection(),
                  const SizedBox(height: 40),
                  // Champ nom d'affichage
                  _buildDisplayNameField(),
                  const SizedBox(height: 20),
                  // Champ bio
                  _buildBioField(),
                  const SizedBox(height: 40),
                  // Bouton de déconnexion
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  /// Section avatar : grand cercle avec bouton caméra superposé.
  ///
  /// Utilise un Stack pour superposer le bouton caméra en bas à droite
  /// de l'avatar. Positioned place le bouton à la position exacte souhaitée.
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          // L'avatar (grand, 50px de rayon)
          _buildAvatar(),
          // Bouton caméra positionné en bas à droite de l'avatar
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
                onPressed: _pickImage, // Ouvre la galerie photo
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit le grand avatar de l'utilisateur.
  ///
  /// Priorité d'affichage :
  /// 1. Le nouvel avatar sélectionné (_newAvatarBase64) -> aperçu avant sauvegarde
  /// 2. L'avatar actuel du profil (_currentUser?.avatarBase64)
  /// 3. L'initiale du nom (avatar par défaut)
  Widget _buildAvatar() {
    // Utilise le nouvel avatar si sélectionné, sinon l'avatar actuel
    final avatarBase64 = _newAvatarBase64 ?? _currentUser?.avatarBase64 ?? '';

    if (avatarBase64.isNotEmpty && ImageHelper.isValidBase64(avatarBase64)) {
      try {
        final Uint8List bytes = base64Decode(avatarBase64);
        return CircleAvatar(
          radius: AppConstants.largeAvatarRadius, // Grand avatar (50px)
          backgroundImage: MemoryImage(bytes),
        );
      } catch (e) {
        debugPrint('Erreur décodage avatar: $e');
      }
    }

    // Avatar par défaut : cercle violet avec initiale
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

  /// Champ de saisie de la bio (description courte du profil)
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
      maxLines: 3, // Permet 3 lignes
      maxLength: 150, // Limite à 150 caractères (avec compteur affiché)
    );
  }

  /// Bouton de déconnexion rouge avec icône
  Widget _buildLogoutButton() {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.red),
      label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red), // Bordure rouge
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }

  /// Ouvre la galerie photo pour sélectionner un nouvel avatar.
  ///
  /// Flux :
  /// 1. Ouvre le sélecteur d'image natif (ImagePicker)
  /// 2. L'image est redimensionnée à max 512x512 et compressée à 85%
  /// 3. Convertie en base64 via ImageHelper
  /// 4. Si l'image fait plus de 500KB, elle est refusée
  /// 5. Sinon, elle est stockée dans _newAvatarBase64 (aperçu immédiat)
  /// 6. L'image ne sera envoyée à Firestore que quand on clique "Enregistrer"
  Future<void> _pickImage() async {
    try {
      // Ouvrir le sélecteur d'image natif du téléphone
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, // Depuis la galerie (pas la caméra)
        maxWidth: 512, // Redimensionne si plus large
        maxHeight: 512, // Redimensionne si plus haut
        imageQuality: 85, // Compression JPEG à 85%
      );

      // L'utilisateur a annulé la sélection
      if (image == null) return;

      // Convertir l'image en base64 avec vérification de taille
      final base64String = await ImageHelper.compressAndConvertToBase64(
        image,
        maxSizeInBytes: 500000, // 500KB maximum
      );

      // L'image est trop grande même après compression
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

      // Stocker l'image en base64 pour l'aperçu immédiat
      setState(() {
        _newAvatarBase64 = base64String;
      });

      debugPrint(
        'Image sélectionnée: ${ImageHelper.getBase64SizeInKB(base64String).toStringAsFixed(2)} KB',
      );
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'image: $e');
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

  /// Sauvegarde les modifications du profil dans Firestore.
  ///
  /// Envoie le nom, la bio et le nouvel avatar (si changé) au ViewModel
  /// qui les écrit dans Firestore. Affiche un message de succès ou d'erreur.
  Future<void> _saveProfile() async {
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    // Validation : le nom ne peut pas être vide
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

    // Mettre à jour le profil via le ViewModel
    // _newAvatarBase64 est null si l'avatar n'a pas changé
    await chatUserViewModel.updateUserProfile(
      displayName: displayName,
      bio: bio,
      avatarBase64: _newAvatarBase64,
    );

    if (mounted) {
      if (chatUserViewModel.errorMessage != null) {
        // Erreur -> afficher un message rouge
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatUserViewModel.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Succès -> afficher un message vert et revenir à la page précédente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Retour à HomePage
      }
    }
  }

  /// Déconnexion avec boîte de dialogue de confirmation.
  ///
  /// Affiche un AlertDialog demandant confirmation avant de déconnecter.
  /// Si confirmé, appelle AuthViewModel.logout() et redirige vers LoginPage.
  Future<void> _logout() async {
    // Afficher la boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          // Bouton "Annuler" -> retourne false
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          // Bouton "Déconnexion" -> retourne true
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

    // Si l'utilisateur a confirmé
    if (confirmed == true && mounted) {
      final authViewModel = context.read<AuthViewModel>();
      await authViewModel.logout();
      if (mounted) {
        // Redirige vers LoginPage et supprime toute la pile de navigation
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
