/// Represents a chat session
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final List<String> attachedFiles;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.attachedFiles = const [],
  });

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    List<String>? attachedFiles,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      attachedFiles: attachedFiles ?? this.attachedFiles,
    );
  }
}
