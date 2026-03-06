/// Represents a local agent workspace with independent identity/personality.
class AgentWorkspace {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final bool enabled;
  final String colorTag;
  final String systemPrompt;
  final String soulMd;
  final String agentsMd;
  final String userMd;
  final String identityMd;

  const AgentWorkspace({
    required this.id,
    required this.name,
    this.description = '',
    this.avatar = '🤖',
    this.enabled = true,
    this.colorTag = '',
    this.systemPrompt = '',
    this.soulMd = '',
    this.agentsMd = '',
    this.userMd = '',
    this.identityMd = '',
  });

  AgentWorkspace copyWith({
    String? name,
    String? description,
    String? avatar,
    bool? enabled,
    String? colorTag,
    String? systemPrompt,
    String? soulMd,
    String? agentsMd,
    String? userMd,
    String? identityMd,
  }) {
    return AgentWorkspace(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      enabled: enabled ?? this.enabled,
      colorTag: colorTag ?? this.colorTag,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      soulMd: soulMd ?? this.soulMd,
      agentsMd: agentsMd ?? this.agentsMd,
      userMd: userMd ?? this.userMd,
      identityMd: identityMd ?? this.identityMd,
    );
  }
}
