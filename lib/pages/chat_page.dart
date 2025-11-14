import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import '../model/chat_user.dart';
import '../model/message.dart';
import '../viewmodel/chat_viewmodel.dart';
import '../viewmodel/chat_user_viewmodel.dart';
import '../constants.dart';

/// Page de conversation avec un utilisateur
class ChatPage extends StatefulWidget {
  final ChatUser otherUser;

  const ChatPage({Key? key, required this.otherUser}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Initialise ou récupère le chat avec l'utilisateur
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
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppConstants.primaryLight,
              child: Text(
                widget.otherUser.displayName.isNotEmpty
                    ? widget.otherUser.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
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
      body: _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _buildMessagesList(),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  /// Liste des messages groupés par date
  Widget _buildMessagesList() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        return StreamBuilder<List<Message>>(
          stream: viewModel.getMessagesStream(_chatId!),
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

            final messages = snapshot.data ?? [];

            if (messages.isEmpty) {
              return const Center(
                child: Text(
                  'Aucun message pour le moment\nEnvoyez le premier !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return GroupedListView<Message, DateTime>(
              elements: messages,
              controller: _scrollController,
              reverse: true,
              order: GroupedListOrder.DESC,
              groupBy: (message) {
                final date = message.timestamp;
                return DateTime(date.year, date.month, date.day);
              },
              groupSeparatorBuilder: (DateTime groupByValue) {
                return _buildDateSeparator(groupByValue);
              },
              itemBuilder: (context, message) {
                return _buildMessageBubble(message);
              },
              floatingHeader: true,
              useStickyGroupSeparators: true,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
            );
          },
        );
      },
    );
  }

  /// Séparateur de date entre les messages
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
      dateText = DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
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

  /// Bulle de message
  Widget _buildMessageBubble(Message message) {
    final chatUserViewModel = context.read<ChatUserViewModel>();
    final isMyMessage = message.from == chatUserViewModel.currentUserId;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMyMessage
              ? AppConstants.myMessageColor
              : AppConstants.otherMessageColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppConstants.borderRadius),
            topRight: const Radius.circular(AppConstants.borderRadius),
            bottomLeft: isMyMessage
                ? const Radius.circular(AppConstants.borderRadius)
                : const Radius.circular(4),
            bottomRight: isMyMessage
                ? const Radius.circular(4)
                : const Radius.circular(AppConstants.borderRadius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMyMessage
                    ? AppConstants.myMessageTextColor
                    : AppConstants.otherMessageTextColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
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

  /// Champ de saisie pour envoyer un message
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppConstants.backgroundColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ChatViewModel>(
            builder: (context, viewModel, child) {
              return FloatingActionButton(
                onPressed: viewModel.isLoading ? null : _sendMessage,
                mini: true,
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

  /// Envoie un message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _chatId == null) return;

    final chatViewModel = context.read<ChatViewModel>();
    
    _messageController.clear();
    
    await chatViewModel.sendMessage(
      chatId: _chatId!,
      receiverId: widget.otherUser.id,
      content: content,
    );

    // Scroll vers le bas après l'envoi
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
