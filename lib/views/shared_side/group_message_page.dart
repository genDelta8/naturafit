import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GroupMessagePage extends StatefulWidget {
  final String groupId;
  final String sessionId;

  const GroupMessagePage({
    Key? key,
    required this.groupId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<GroupMessagePage> createState() => _GroupMessagePageState();
}

class _GroupMessagePageState extends State<GroupMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String currentUserId;
  Map<String, Color> userColors = {};
  List<String> participants = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> userNames = {};
  final List<Color> _colors = [
    const Color(0xFF1E88E5), // Blue
    const Color(0xFF43A047), // Green
    const Color(0xFF8E24AA), // Purple
    const Color(0xFFE53935), // Red
    const Color(0xFF3949AB), // Indigo
    const Color(0xFF039BE5), // Light Blue
    const Color(0xFF00897B), // Teal
    const Color(0xFFE91E63), // Pink
    const Color(0xFF6D4C41), // Brown
    const Color(0xFF546E7A), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadParticipants().then((_) => _loadUserNames());
  }

  Future<void> _loadParticipants() async {
    final groupDoc =
        await _firestore.collection('group_chats').doc(widget.groupId).get();

    if (groupDoc.exists) {
      participants = List<String>.from(groupDoc.data()!['participants']);
    }
  }

  Future<void> _loadUserNames() async {
    try {
      for (String userId in participants) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final data = userDoc.data();
        if (data != null) {
          userNames[userId] = data[fbFullName]?.toString().isNotEmpty == true
              ? data[fbFullName]
              : data[fbRandomName]?.toString().isNotEmpty == true
                  ? data[fbRandomName]
                  : 'Unknown User';
        }
      }
    } catch (e) {
      debugPrint('Error loading user names: $e');
    }
  }

  Color _getUserColor(String userId) {
    if (userColors.containsKey(userId)) {
      return userColors[userId]!;
    }

    if (userId == currentUserId) {
      return myBlue60;
    }

    final usedColors = userColors.values.toSet();
    Color? selectedColor;

    for (final color in _colors) {
      if (!usedColors.contains(color)) {
        selectedColor = color;
        break;
      }
    }

    selectedColor ??= _colors[userId.hashCode % _colors.length];

    userColors[userId] = selectedColor;
    return selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection('group_chats')
              .doc(widget.groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            return Text(
              snapshot.data!['name'],
              style: GoogleFonts.plusJakartaSans(
                color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('group_chats')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                debugPrint('Message stream state: ${snapshot.connectionState}');
                debugPrint('Has data: ${snapshot.hasData}');
                if (snapshot.hasData) {
                  debugPrint(
                      'Number of messages: ${snapshot.data!.docs.length}');
                }
                if (snapshot.hasError) {
                  debugPrint('Stream error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: myBlue60));
                }

                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isCurrentUser = message['senderId'] == currentUserId;
                    final senderName = message['senderName'] ?? 'Unknown';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? myBlue60
                                : const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft:
                                  Radius.circular(isCurrentUser ? 16 : 4),
                              bottomRight:
                                  Radius.circular(isCurrentUser ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCurrentUser) ...[
                                Text(
                                  senderName,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _getUserColor(message['senderId']),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                message['text'],
                                style: GoogleFonts.plusJakartaSans(
                                  color: isCurrentUser
                                      ? Colors.white
                                      : Colors.black87,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.white : myGrey80,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
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
                  
                  
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: myBlue60,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final timestamp = FieldValue.serverTimestamp();
      final messageText = _messageController.text.trim();
      final senderName = await _getCurrentUserName();

      debugPrint('Sending message as user: $currentUserId');
      debugPrint('Original participants: $participants');

      // Create a new list that includes the sender
      final allParticipants = [...participants, currentUserId];
      debugPrint('All participants (including sender): $allParticipants');

      // Create batch write
      final batch = _firestore.batch();

      // Add message to group chat messages
      final messageRef = _firestore
          .collection('group_chats')
          .doc(widget.groupId)
          .collection('messages')
          .doc();

      final messageData = {
        'text': messageText,
        'senderId': currentUserId,
        'senderName': senderName,
        'timestamp': timestamp,
      };

      debugPrint('Message data: $messageData');
      batch.set(messageRef, messageData);

      // Update group chat document
      batch.update(_firestore.collection('group_chats').doc(widget.groupId), {
        'lastMessage': messageText,
        'lastMessageTimestamp': timestamp,
        'lastMessageSender': senderName,
      });

      // Get group info first
      final groupInfo = await _getGroupNameAndImageUrl();

      // Then use it in the batch writes
      for (String participantId in allParticipants) {
        final lastMessageRef = _firestore
            .collection('messages')
            .doc(participantId)
            .collection('last_messages')
            .doc(widget.groupId);

        batch.set(lastMessageRef, {
          'lastMessage': messageText,
          'timestamp': timestamp,
          'isGroup': true,
          'groupId': widget.groupId,
          'groupName': groupInfo['name'],
          'imageUrl': groupInfo['imageUrl'],
          'sessionId': widget.sessionId,
          'read': participantId == currentUserId,
          'senderName': senderName,
        });
      }

      await batch.commit();
      _messageController.clear();
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      final data = userDoc.data();
      if (data == null) return 'Unknown User';

      // Try fullName first, then username, then fallback to Unknown User
      return data[fbFullName]?.toString().isNotEmpty == true
          ? data[fbFullName]
          : data[fbRandomName]?.toString().isNotEmpty == true
              ? data[fbRandomName]
              : 'Unknown User';
    } catch (e) {
      debugPrint('Error getting user name: $e');
      return 'Unknown User';
    }
  }

  Future<Map<String, dynamic>> _getGroupNameAndImageUrl() async {
    final groupDoc =
        await _firestore.collection('group_chats').doc(widget.groupId).get();
    return {
      'name': groupDoc.data()?['name'] ?? 'Group Chat',
      'imageUrl': groupDoc.data()?['imageUrl'] ?? '',
    };
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
