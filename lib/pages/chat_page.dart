// =============================================================================
// chat_page.dart - PAGE : CONVERSATION / MESSAGERIE
// =============================================================================
// Page de conversation en temps réel entre deux utilisateurs.
// C'est la page la plus complexe de l'application.
//
// Fonctionnalités :
//   - Affichage des messages en temps réel (StreamBuilder + Firestore)
//   - Messages groupés par date (Aujourd'hui, Hier, date complète)
//   - Bulles de message différenciées (mes messages en violet, les autres en gris)
//   - Horodatage sur chaque message
//   - Champ de saisie avec bouton d'envoi
//   - Auto-scroll vers le dernier message
//   - Avatar et infos de l'interlocuteur dans l'AppBar
//
// ViewModels utilisés :
//   - ChatViewModel : envoi de messages, stream des messages, création de chat
//   - ChatUserViewModel : identification de l'utilisateur courant
//
// Package externe : grouped_list (pour le groupement par date)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../model/chat_user.dart';
import '../model/message.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/chat_user_viewmodel.dart';
import '../constants.dart';

/// Page de conversation avec un utilisateur spécifique.
///
/// Reçoit l'objet [otherUser] en paramètre : c'est l'interlocuteur.
/// Au chargement, elle crée ou récupère la conversation existante
/// via ChatViewModel.getOrCreateChat().
class ChatPage extends StatefulWidget {
  /// L'utilisateur avec qui on discute (passé par la HomePage)
  final ChatUser otherUser;

  const ChatPage({Key? key, required this.otherUser}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// Contrôleur du champ de saisie de message
  final TextEditingController _messageController = TextEditingController();

  /// Contrôleur de scroll pour auto-scroller vers le bas après envoi
  final ScrollController _scrollController = ScrollController();

  /// ID de la conversation (null tant qu'elle n'est pas initialisée)
  /// Format : "{uid1}_{uid2}" triés alphabétiquement
  String? _chatId;

  @override
  void initState() {
    super.initState();
    // Initialiser la conversation dès l'ouverture de la page
    _initializeChat();
  }

  /// Crée ou récupère la conversation avec l'interlocuteur.
  ///
  /// Appelle ChatViewModel.getOrCreateChat() qui :
  /// 1. Génère l'ID unique de la conversation
  /// 2. Vérifie si elle existe dans Firestore
  /// 3. La crée si elle n'existe pas
  /// 4. Retourne l'ID du chat
  ///
  /// Une fois l'ID obtenu, setState() déclenche un rebuild pour afficher les messages.
  Future<void> _initializeChat() async {
    final chatViewModel = context.read<ChatViewModel>();
    final chatId = await chatViewModel.getOrCreateChat(widget.otherUser.id);
    setState(() {
      _chatId = chatId;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar avec avatar et infos de l'interlocuteur ---
      appBar: AppBar(
        title: Row(
          children: [
            // Avatar de l'interlocuteur
            _buildAvatar(),
            const SizedBox(width: 12),
            // Nom et bio de l'interlocuteur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  // Affiche la bio seulement si elle existe
                  if (widget.otherUser.bio.isNotEmpty)
                    Text(
                      widget.otherUser.bio,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- Corps de la page ---
      // Affiche un spinner tant que le chatId n'est pas initialisé,
      // puis affiche les messages + le champ de saisie
      body: _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Zone des messages (prend tout l'espace disponible)
                Expanded(child: _buildMessagesList()),
                // Champ de saisie en bas (taille fixe)
                _buildMessageInput(),
              ],
            ),
    );
  }

  /// Construit la liste des messages groupés par date.
  ///
  /// Utilise :
  /// - Consumer<ChatViewModel> pour accéder au ViewModel
  /// - StreamBuilder pour écouter les messages en temps réel
  /// - GroupedListView pour grouper les messages par jour
  ///
  /// Les messages sont affichés en ordre inversé (plus récent en bas)
  /// pour un comportement naturel de messagerie.
  Widget _buildMessagesList() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<Message>>(
          // Stream temps réel des messages de cette conversation
          stream: viewModel.getMessagesStream(_chatId!),
          builder: (context, snapshot) {
            // Chargement initial
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Erreur
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final messages = snapshot.data ?? [];

            // Aucun message : affiche un texte d'invitation
            if (messages.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun message pour le moment\nEnvoyez le premier !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            // GroupedListView : package externe qui groupe les éléments par critère
            // Ici, on groupe les messages par DATE (jour/mois/année)
            return GroupedListView<Message, DateTime>(
              elements: messages,
              controller: _scrollController,
              reverse: true, // Plus récent en bas (comme WhatsApp)
              order: GroupedListOrder.DESC, // Ordre décroissant
              // Fonction de groupement : extraire la date (sans l'heure) du timestamp
              groupBy: (message) {
                final date = message.timestamp;
                return DateTime(date.year, date.month, date.day);
              },
              // Widget séparateur affiché entre les groupes de dates
              groupSeparatorBuilder: (DateTime groupByValue) {
                return _buildDateSeparator(groupByValue);
              },
              // Widget pour chaque message individuel
              itemBuilder: (context, message) {
                return _buildMessageBubble(message);
              },
              floatingHeader: true, // Le header de date "flotte" en haut
              useStickyGroupSeparators: true, // Headers collants au scroll
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
            );
          },
        );
      },
    );
  }

  /// Construit le séparateur de date entre les groupes de messages.
  ///
  /// Affiche :
  /// - "Aujourd'hui" si c'est aujourd'hui
  /// - "Hier" si c'est hier
  /// - La date complète sinon (ex: "15 janvier 2024")
  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date == today) {
      dateText = 'Aujourd\'hui';
    } else if (date == yesterday) {
      dateText = 'Hier';
    } else {
      // DateFormat du package intl pour formater la date en français
      dateText = DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }

    // Pastille grise arrondie au centre
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  /// Construit une bulle de message.
  ///
  /// La bulle est positionnée :
  /// - À DROITE si c'est MON message (fond violet, texte blanc)
  /// - À GAUCHE si c'est le message de l'AUTRE (fond gris, texte noir)
  ///
  /// Chaque bulle contient le texte du message et l'heure d'envoi.
  /// Les coins sont arrondis avec un coin plus petit en bas (style WhatsApp).
  Widget _buildMessageBubble(Message message) {
    final chatUserViewModel = context.read<ChatUserViewModel>();
    // Détermine si c'est MON message en comparant l'expéditeur avec mon UID
    final isMyMessage = message.from == chatUserViewModel.currentUserId;

    return Align(
      // Aligne à droite (mes messages) ou à gauche (messages reçus)
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        // Limite la largeur à 70% de l'écran pour l'effet "bulle"
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          // Couleur différente selon l'expéditeur
          color: isMyMessage
              ? AppConstants.myMessageColor // Violet pour mes messages
              : AppConstants.otherMessageColor, // Gris pour les autres
          // Coins arrondis avec un coin plus petit en bas (effet bulle)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppConstants.borderRadius),
            topRight: const Radius.circular(AppConstants.borderRadius),
            // Le coin en bas est plus petit du côté de l'expéditeur
            bottomLeft: isMyMessage
                ? const Radius.circular(AppConstants.borderRadius)
                : const Radius.circular(4), // Petit coin = côté expéditeur
            bottomRight: isMyMessage
                ? const Radius.circular(4) // Petit coin = côté expéditeur
                : const Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Texte du message
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage
                    ? AppConstants.myMessageTextColor // Blanc
                    : AppConstants.otherMessageTextColor, // Noir
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            // Horodatage du message (format HH:mm, ex: "14:30")
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isMyMessage
                    ? AppConstants.myMessageTextColor.withOpacity(0.7)
                    : AppConstants.otherMessageTextColor.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit le champ de saisie pour écrire et envoyer un message.
  ///
  /// Composé de :
  /// - Un TextField arrondi (style moderne)
  /// - Un FloatingActionButton mini pour envoyer
  ///
  /// Le Consumer<ChatViewModel> désactive le bouton d'envoi pendant
  /// l'envoi d'un message (isLoading).
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      // Ombre légère en haut pour séparer visuellement du contenu
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2), // Ombre vers le haut
          ),
        ],
      ),
      child: Row(
        children: [
          // Champ de texte (prend tout l'espace disponible)
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24), // Très arrondi
                  borderSide: BorderSide.none, // Pas de bordure visible
                ),
                filled: true,
                fillColor: AppConstants.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null, // Permet les messages multi-lignes
              textCapitalization: TextCapitalization.sentences, // Majuscule auto
              onSubmitted: (_) => _sendMessage(), // Envoi avec la touche Entrée
            ),
          ),
          const SizedBox(width: 8),
          // Bouton d'envoi (petit bouton rond violet)
          Consumer<ChatViewModel>(
            builder: (context, viewModel, child) {
              return FloatingActionButton(
                onPressed: viewModel.isLoading ? null : _sendMessage,
                mini: true, // Version petite du FAB
                backgroundColor: AppConstants.primaryColor,
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Envoie le message saisi par l'utilisateur.
  ///
  /// Flux :
  /// 1. Récupère le texte et le nettoie (trim = supprime espaces)
  /// 2. Vérifie que le texte n'est pas vide et que le chat est initialisé
  /// 3. Efface le champ de texte AVANT l'envoi (réactivité instantanée)
  /// 4. Appelle ChatViewModel.sendMessage()
  /// 5. Scroll vers le bas pour voir le nouveau message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _chatId == null) return;

    final chatViewModel = context.read<ChatViewModel>();

    // Efface le champ IMMÉDIATEMENT (pas besoin d'attendre l'envoi)
    _messageController.clear();

    // Envoie le message via le ViewModel
    await chatViewModel.sendMessage(
      chatId: _chatId!,
      receiverId: widget.otherUser.id,
      content: content,
    );

    // Auto-scroll vers le bas pour afficher le nouveau message
    // (la liste est inversée donc position 0 = en bas)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Construit l'avatar de l'interlocuteur dans l'AppBar.
  /// Même logique que dans HomePage : image base64 ou initiale.
  Widget _buildAvatar() {
    if (widget.otherUser.avatarBase64.isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(widget.otherUser.avatarBase64);
        return CircleAvatar(radius: 18, backgroundImage: MemoryImage(bytes));
      } catch (e) {
        debugPrint('Erreur décodage avatar: $e');
      }
    }

    // Avatar par défaut avec initiale
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppConstants.primaryLight,
      child: Text(
        widget.otherUser.displayName.isNotEmpty
            ? widget.otherUser.displayName[0].toUpperCase()
            : '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
