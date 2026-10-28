/// A single chat message inside a conversation.
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic>? json) {
    final data =
        json == null ? <String, dynamic>{} : Map<String, dynamic>.from(json);
    return ChatMessage(
      id: data['id']?.toString() ?? '',
      conversationId: data['conversation_id']?.toString() ?? '',
      senderId: data['sender_id']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}