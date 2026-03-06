/// Represents a chat session
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final List<String> attachedFiles;

  /// Whether this session uses multi-agent role mode.
  final bool isMultiAgent;

  /// Active role names in this session (e.g. ['architect', 'coder', 'critic']).
  final List<String> activeRoles;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.attachedFiles = const [],
    this.isMultiAgent = false,
    this.activeRoles = const [],
  });

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    int? messageCount,
    List<String>? attachedFiles,
    bool? isMultiAgent,
    List<String>? activeRoles,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      attachedFiles: attachedFiles ?? this.attachedFiles,
      isMultiAgent: isMultiAgent ?? this.isMultiAgent,
      activeRoles: activeRoles ?? this.activeRoles,
    );
  }
}
