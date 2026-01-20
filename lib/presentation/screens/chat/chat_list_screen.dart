import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/supabase_config.dart';
import '../../../core/services/session_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
    _setupRealtimeListener();
  }

  Future<void> _loadChatRooms() async {
    try {
      setState(() => _isLoading = true);
      _currentUserId = await SessionService.getUserId();
      if (_currentUserId == null) throw 'User not authenticated';

      final response = await SupabaseConfig.client
          .from('chat_rooms')
          .select('''
            *,
            latest_message:chat_messages(
              id,
              message,
              created_at,
              sender_id,
              is_read
            )
          ''')
          .or('customer_id.eq.$_currentUserId,provider_id.eq.$_currentUserId')
          .order('updated_at', ascending: false);

      setState(() {
        _chatRooms = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading chat rooms: $e');
    }
  }

  void _setupRealtimeListener() {
    // Realtime listener will be handled by StreamBuilder or periodic refresh
    // Supabase Flutter v2+ handles this differently
  }

  String _getOtherUserName(Map<String, dynamic> chatRoom) {
    if (chatRoom['customer_id'] == _currentUserId) {
      return chatRoom['provider_name'] ?? 'Provider';
    }
    return chatRoom['customer_name'] ?? 'Customer';
  }

  String? _getLastMessage(Map<String, dynamic> chatRoom) {
    final messages = chatRoom['latest_message'] as List?;
    if (messages != null && messages.isNotEmpty) {
      return messages.first['message'];
    }
    return null;
  }

  int _getUnreadCount(Map<String, dynamic> chatRoom) {
    final messages = chatRoom['latest_message'] as List?;
    if (messages != null) {
      return messages
          .where((msg) =>
              msg['sender_id'] != _currentUserId && msg['is_read'] == false)
          .length;
    }
    return 0;
  }

  Future<void> _deleteChat(String chatRoomId) async {
    try {
      await SupabaseConfig.client.from('chat_rooms').delete().eq('id', chatRoomId);
      _loadChatRooms();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Messages',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5F758C),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = _chatRooms[index];
                    final unreadCount = _getUnreadCount(chatRoom);
                    final lastMessage = _getLastMessage(chatRoom);
                    final otherUserName = _getOtherUserName(chatRoom);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade700,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            otherUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181511),
                            ),
                          ),
                          subtitle: Text(
                            lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5F758C),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _openChat(chatRoom),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Chat?'),
                                content: const Text(
                                  'This will delete the entire conversation.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _deleteChat(chatRoom['id']);
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _openChat(Map<String, dynamic> chatRoom) {
    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatRoom['id'],
          otherUserName: _getOtherUserName(chatRoom),
          otherUserId: chatRoom['customer_id'] == _currentUserId
              ? chatRoom['provider_id']
              : chatRoom['customer_id'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String otherUserId;

  const ChatScreen({
    Key? key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      _currentUserId = await SessionService.getUserId();
      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select()
          .eq('chat_room_id', widget.chatRoomId)
          .order('created_at', ascending: true);

      setState(() {
        _messages = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      await SupabaseConfig.client.from('chat_messages').insert({
        'chat_room_id': widget.chatRoomId,
        'sender_id': _currentUserId,
        'message': _messageController.text,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      _messageController.clear();

      // Update chat room updated_at
      await SupabaseConfig.client
          .from('chat_rooms')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', widget.chatRoomId);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('chat_room_id', widget.chatRoomId)
          .neq('sender_id', _currentUserId ?? '');
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('No messages yet'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isSent = msg['sender_id'] == _currentUserId;
                          final createdAt = DateTime.parse(msg['created_at']);
                          final formattedTime =
                              DateFormat('hh:mm a').format(createdAt);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: isSent
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSent
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg['message'],
                                        style: TextStyle(
                                          color: isSent
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSent
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.blue.shade700,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
