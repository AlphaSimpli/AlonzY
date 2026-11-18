import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
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
  bool _loadFailed = false;
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
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final conversations = await _dbService.getConversations(userId);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
        _loadFailed = false;
      });
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.chatMessagesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: strings.chatRefresh,
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(strings.chatLoadFailed),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadConversations,
                    child: Text(strings.chatRetry),
                  ),
                ],
              ),
            )
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
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            strings.chatEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              strings.chatEmptyMessage,
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
    final strings = AppLocalizations.of(context);
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
              other?.displayName ?? strings.chatMember,
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
                ? strings.chatNoMessages
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
        _relativeTime(context, conversation.lastMessageAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  static String _relativeTime(BuildContext context, DateTime time) {
    final strings = AppLocalizations.of(context);
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return strings.chatNow;
    if (diff.inHours < 1) return strings.chatMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return strings.chatHoursAgo(diff.inHours);
    if (diff.inDays < 7) return strings.chatDaysAgo(diff.inDays);
    return DateFormat.Md(Localizations.localeOf(context).toString()).format(
      time,
    );
  }
}