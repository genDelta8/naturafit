import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class DirectMessagePage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfileImageUrl;
  final String chatType; // 'client' or 'trainer'

  const DirectMessagePage({
    Key? key,
    required this.otherUserId,
    String? otherUserName,
    String? otherUserProfileImageUrl,
    String? chatType,
  }) : 
    otherUserName = otherUserName ?? 'Unknown',
    otherUserProfileImageUrl = otherUserProfileImageUrl ?? '',
    chatType = chatType ?? 'client',
    super(key: key);

  @override
  State<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends State<DirectMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<QuerySnapshot>? _messagesStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupMessagesStream();
  }

  void _setupMessagesStream() {
    final userData = context.read<UserProvider>().userData;
    if (userData == null) return;

    final myId = userData['userId'];
    
    _messagesStream = _firestore
        .collection('messages')
        .doc(myId)
        .collection(widget.otherUserId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();

  }

  Future<void> _sendMessage() async {
    final l10n = AppLocalizations.of(context)!;
    if (_messageController.text.trim().isEmpty) return;
    if (widget.otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.direct_message,
          message: l10n.invalid_recipient,
          type: SnackBarType.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = context.read<UserProvider>().userData;
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          CustomSnackBar.show(
            title: l10n.direct_message,
            message: l10n.user_data_not_available,
            type: SnackBarType.error,
          ),
        );
        return;
      }

      final myId = userData['userId'];
      final message = _messageController.text.trim();
      final timestamp = FieldValue.serverTimestamp();

      // Create message data
      final messageData = {
        'fromId': myId,
        'toId': widget.otherUserId,
        'message': message,
        'timestamp': timestamp,
      };

      // Create batch write
      final batch = _firestore.batch();

      // Add message to sender's collection
      final senderRef = _firestore
          .collection('messages')
          .doc(myId)
          .collection(widget.otherUserId)
          .doc();

      batch.set(senderRef, messageData);

      // Add message to recipient's collection
      final recipientRef = _firestore
          .collection('messages')
          .doc(widget.otherUserId)
          .collection(myId)
          .doc(senderRef.id);

      batch.set(recipientRef, messageData);

      // Update last message for sender
      final senderLastMessageRef = _firestore
          .collection('messages')
          .doc(myId)
          .collection('last_messages')
          .doc(widget.otherUserId);

      batch.set(senderLastMessageRef, {
        'lastMessage': message,
        'timestamp': timestamp,
        'otherUserId': widget.otherUserId,
        'otherUserName': widget.otherUserName,
        'otherUserProfileImageUrl': widget.otherUserProfileImageUrl,
        'chatType': widget.chatType,
        'read': true,
      }, SetOptions(merge: true));

      // Update last message for recipient
      final recipientLastMessageRef = _firestore
          .collection('messages')
          .doc(widget.otherUserId)
          .collection('last_messages')
          .doc(myId);

      batch.set(recipientLastMessageRef, {
        'lastMessage': message,
        'timestamp': timestamp,
        'otherUserId': myId,
        'otherUserName': userData[fbFullName],
        'otherUserProfileImageUrl': userData[fbProfileImageURL],
        'chatType': widget.chatType == 'client' ? 'trainer' : 'client',
        'read': false,
      }, SetOptions(merge: true));

      await batch.commit();
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar.show(
          title: l10n.direct_message,
          message: l10n.error_sending_message(e.toString()),
          type: SnackBarType.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserProvider>().userData;
    final theme = Theme.of(context);
    if (userData == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.chevron_left, color: theme.brightness == Brightness.light ? Colors.black : Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: myBlue60));
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.no_messages_yet,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = message['fromId'] == userData['userId'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? myBlue60 : theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                              bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser 
                                ? CrossAxisAlignment.end 
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                message['message'],
                                style: GoogleFonts.plusJakartaSans(
                                  color: isCurrentUser ? Colors.white : theme.brightness == Brightness.light ? Colors.black87 : Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isCurrentUser 
                                      ? Colors.white.withOpacity(0.7) 
                                      : theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomFocusTextField(
              controller: _messageController,
              hintText: l10n.type_a_message,
              label: '',
            ),
            
            /*
            TextField(
              style: GoogleFonts.plusJakartaSans(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, fontSize: 16),
              controller: _messageController,
              decoration: InputDecoration(
                hintText: l10n.type_a_message,
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: theme.brightness == Brightness.light ? myGrey40 : myGrey60,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.brightness == Brightness.light ? myGrey30 : myGrey70),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.brightness == Brightness.light ? myGrey30 : myGrey70),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: myBlue60),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
            */
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: myBlue60,
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              color: Colors.white,
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.now();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 