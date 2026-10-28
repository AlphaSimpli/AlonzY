import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/verification_badges.dart';

/// Real-time driver-passenger conversation thread.
///
/// Messages stream in via Supabase Realtime; the input bar appends locally
/// for snappy feedback while the server persists the row.
class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({super.key, required this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _bookingSub;
  Booking? _booking;

  String? get _myId => _authService.currentUser?.id;

  AppUser? get _otherParty => widget.conversation.otherParty(_myId ?? '');

  @override
  void initState() {
    super.initState();
    _loadAndWatch();
  }

  Future<void> _loadAndWatch() async {
    final conversationId = widget.conversation.id;
    final userId = _myId;
    final rideId = widget.conversation.rideId;
    if (rideId.isNotEmpty) {
      _booking = await _dbService.getConversationBooking(
        rideId: rideId,
        passengerId: widget.conversation.passengerId,
      );
      if (mounted) setState(() {});
      _bookingSub = _dbService.supabase
          .from('bookings')
          .stream(primaryKey: ['id'])
          .eq('ride_id', rideId)
          .listen((records) async {
            final match = records.where(
              (row) => row['passenger_id']?.toString() ==
                  widget.conversation.passengerId,
            );
            final next = match.isEmpty
                ? null
                : await _dbService.getConversationBooking(
                    rideId: rideId,
                    passengerId: widget.conversation.passengerId,
                  );
            if (mounted) setState(() => _booking = next);
          }, onError: (Object e) => debugPrint('Booking stream error: $e'));
    }

    final messages = await _dbService.getMessages(conversationId);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
    _scrollToBottom();

    if (userId != null) {
      _dbService.markConversationRead(conversationId, userId);
    }

    _messagesSub = _dbService
        .watchConversation(conversationId)
        .listen((records) {
      if (!mounted) return;
      final wasAtBottom =
          _scrollController.hasClients &&
              _scrollController.position.pixels >=
                  _scrollController.position.maxScrollExtent - 80;
      setState(() => _messages = records);
      if (wasAtBottom) _scrollToBottom();
      if (userId != null) {
        _dbService.markConversationRead(conversationId, userId);
      }
    }, onError: (Object e) => debugPrint('Chat stream error: $e'));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final optimistic = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _myId ?? '',
      message: text,
      createdAt: DateTime.now(),
    );
    _inputController.clear();
    setState(() => _messages = [..._messages, optimistic]);
    _scrollToBottom();

    try {
      await _dbService.sendMessage(
        conversationId: widget.conversation.id,
        message: text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _messages = _messages.where((m) => m.id != optimistic.id).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Could not send message: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _bookingSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.conversation.ride;
    final other = _otherParty;
    final isDriver = _myId == widget.conversation.driverId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    other?.initials ?? '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    other?.displayName ?? 'Chat',
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (other != null && other.verificationLevel > 0) ...[
              const SizedBox(height: 2),
              VerificationBadges(user: other, compact: true),
            ],
          ],
        ),
        bottom: ride == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${ride.originAddress} → ${ride.destinationAddress}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: Column(
        children: [
          if (isDriver && _booking?.status == 'pending')
            _BookingApprovalBanner(
              booking: _booking!,
              onAccept: () async {
                await _dbService.approveBooking(_booking!.id);
              },
              onDecline: () async {
                await _dbService.rejectBooking(_booking!.id);
              },
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _EmptyThread()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) =>
                            _MessageBubble(message: _messages[index], mine: _messages[index].senderId == _myId),
                      ),
          ),
          _Composer(
            controller: _inputController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _BookingApprovalBanner extends StatelessWidget {
  const _BookingApprovalBanner({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

  final Booking booking;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  Widget build(BuildContext context) {
    final passenger = booking.passenger?.displayName ?? 'Passenger';
    return Material(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$passenger requested ${booking.seatsBooked} seat(s) '
                'for \$${booking.totalPrice.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Say hi and confirm the details of your trip.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt;
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: mine ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeLabel,
              style: TextStyle(
                fontSize: 10,
                color: mine
                    ? Colors.white.withValues(alpha: 0.75)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Write a message…',
                  isDense: true,
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}