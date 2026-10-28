import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'chat_page.dart';

/// All driver-passenger conversations, newest activity first.
///
/// Updates in real time whenever a conversation row changes (new message,
/// new thread) via Supabase Realtime.
class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  List<Conversation> _conversations = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  String? get _myId => _authService.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final userId = _myId;
    if (userId == null) return;

    try {
      final conversations = await _dbService.getConversations(userId);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _subscribe() {
    final userId = _myId;
    if (userId == null) return;
    _channel = _dbService.watchConversationEvents(
      userId,
      onEvent: (_) => _loadConversations(),
    );
  }

  Future<void> _openConversation(Conversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(conversation: conversation)),
    );
    _loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) =>
                        _ConversationTile(
                          conversation: _conversations[index],
                          myId: _myId ?? '',
                          onTap: () =>
                              _openConversation(_conversations[index]),
                        ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Message a driver from a ride or a passenger from your bookings '
              'to start chatting.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myId,
    required this.onTap,
  });

  final Conversation conversation;
  final String myId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherParty(myId);
    final lastMessage = conversation.lastMessage;
    final unread = conversation.hasUnread(myId) && lastMessage != null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          other?.initials ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              other?.displayName ?? 'Member',
              style: TextStyle(
                fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (other?.verificationLevel == 3) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: AppColors.success),
          ],
        ],
      ),
      subtitle: Text(
        lastMessage?.isNotEmpty == true
            ? lastMessage!
            : (conversation.ride == null
                ? 'No messages yet'
                : '${conversation.ride!.originAddress} → '
                  '${conversation.ride!.destinationAddress}'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
          color: unread
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _relativeTime(conversation.lastMessageAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}