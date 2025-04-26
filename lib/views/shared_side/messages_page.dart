import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:naturafit/utilities/platform_check.dart';
import 'package:naturafit/widgets/custom_expandable_search.dart';
import 'package:naturafit/widgets/custom_focus_textfield.dart';
import 'package:naturafit/widgets/custom_snack_bar.dart';
import 'package:naturafit/widgets/custom_user_profile_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:naturafit/utilities/color_scheme.dart';
import 'package:provider/provider.dart';
import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/views/shared_side/direct_message_page.dart';
import 'package:naturafit/views/shared_side/group_message_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MessagesPage extends StatefulWidget {
  final bool isVisitingProfile;
  const MessagesPage({Key? key, this.isVisitingProfile = false}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<QuerySnapshot>? _getMessagesStream(String userId) {
    return _firestore
        .collection('messages')
        .doc(userId)
        .collection('last_messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _markAsRead(String myId, String otherUserId) async {
    try {
      await _firestore
          .collection('messages')
          .doc(myId)
          .collection('last_messages')
          .doc(otherUserId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = context.watch<UserProvider>().userData;
    if (userData == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final myIsWebOrDektop = isWebOrDesktopCached;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading:(myIsWebOrDektop && !widget.isVisitingProfile)
            ? const SizedBox.shrink()
            : Container(
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
        actions: myIsWebOrDektop
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CustomExpandableSearch(
                    hintText: l10n.search_messages,
                    onChanged: (value) {
                      setState(() {
                        _searchController.text = value;
                      });
                    },
                  ),
                ),
              ]
            : [],
        centerTitle: myIsWebOrDektop ? false : true,
        title: Text(
          l10n.messages,
          style: GoogleFonts.plusJakartaSans(
            color: theme.brightness == Brightness.light ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!myIsWebOrDektop)
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: CustomFocusTextField(
                      label: '',
                      hintText: l10n.search_messages,
                      controller: _searchController,
                      shouldShowBorder: true,
                    )),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getMessagesStream(userData['userId']),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: myBlue60));
                    }

                    final messages = snapshot.data!.docs;
                    final filteredMessages = messages.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['otherUserName']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery);
                    }).toList();

                    if (filteredMessages.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Center(
                          child: Text(
                            l10n.no_messages_found,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredMessages.length,
                      separatorBuilder: (context, index) => Divider(
                        color: theme.brightness == Brightness.light ? myGrey20 : myGrey80,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final message = filteredMessages[index].data()
                            as Map<String, dynamic>;
                        final isGroup = message['isGroup'] ?? false;

                        if (isGroup) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CustomUserProfileImage(
                                imageUrl: message['imageUrl'] as String? ?? '',
                                name: message['groupName'] as String? ?? 'Group Chat',
                                size: 48,
                                borderRadius: 8,
                              ),
                              title: Text(
                                message['groupName'] ?? l10n.group_chat,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  if (message['senderName'] != null) ...[
                                    Text(
                                      '${message['senderName']}: ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  Expanded(
                                    child: Text(
                                      message['lastMessage'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTimestamp(message['timestamp']),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                    ),
                                  ),
                                  if (!(message['read'] ?? true))
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: myBlue60,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                _markAsRead(
                                    userData['userId'], message['groupId']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GroupMessagePage(
                                      groupId: message['groupId'],
                                      sessionId: message['sessionId'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CustomUserProfileImage(
                                imageUrl: message['otherUserProfileImageUrl'] as String? ?? '',
                                name: message['otherUserName'] as String? ?? 'Unknown',
                                size: 48,
                                borderRadius: 8,
                              ),
                              title: Text(
                                message['otherUserName'] as String? ?? 'Unknown',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                message['lastMessage'] as String? ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTimestamp(message['timestamp']),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.brightness == Brightness.light ? myGrey60 : myGrey40,
                                    ),
                                  ),
                                  if (!(message['read'] ?? true))
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: myBlue60,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                final otherUserId =
                                    message['otherUserId'] as String? ?? '';
                                if (otherUserId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    CustomSnackBar.show(
                                      title: l10n.direct_message,
                                      message: l10n.invalid_chat_data,
                                      type: SnackBarType.error,
                                    ),
                                  );
                                  return;
                                }
                            
                                _markAsRead(userData['userId'], otherUserId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DirectMessagePage(
                                      otherUserId: otherUserId,
                                      otherUserName:
                                          message['otherUserName'] as String? ??
                                              'Unknown',
                                      chatType: message['chatType'] as String? ??
                                          'client',
                                      otherUserProfileImageUrl:
                                          message['otherUserProfileImageUrl'] as String? ??
                                              '',
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('New message button pressed');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: myBlue30,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: myBlue60,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 72,
                          width: 72,
                          child: const Icon(Icons.add,
                              size: 32, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return _getDayName(date.weekday);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}
