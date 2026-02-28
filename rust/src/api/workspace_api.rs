// No sync FRB functions needed here currently

// ──────────────────── Workspace Config ────────────────────────

/// Workspace configuration DTO
#[derive(Debug, Clone)]
pub struct WorkspaceConfig {
    pub workspace_dir: String,
    pub config_path: String,
}

/// Autonomy configuration DTO
#[derive(Debug, Clone)]
pub struct AutonomyConfig {
    pub level: String, // "read_only", "supervised", "full"
    pub workspace_only: bool,
    pub allowed_commands: Vec<String>,
    pub forbidden_paths: Vec<String>,
    pub max_actions_per_hour: u32,
    pub max_cost_per_day_cents: u32,
    pub require_approval_for_medium_risk: bool,
    pub block_high_risk_commands: bool,
    pub auto_approve: Vec<String>,
    pub always_ask: Vec<String>,
}

/// Agent config DTO
#[derive(Debug, Clone)]
pub struct AgentConfigDto {
    pub max_tool_iterations: u32,
    pub max_history_messages: u32,
    pub parallel_tools: bool,
    pub tool_dispatcher: String,
    pub compact_context: bool,
}

/// Memory config DTO
#[derive(Debug, Clone)]
pub struct MemoryConfigDto {
    pub backend: String,
    pub auto_save: bool,
    pub hygiene_enabled: bool,
    pub archive_after_days: u32,
    pub purge_after_days: u32,
    pub conversation_retention_days: u32,
    pub embedding_provider: String,
    pub embedding_model: String,
}

/// Cost config DTO
#[derive(Debug, Clone)]
pub struct CostConfigDto {
    pub enabled: bool,
    pub daily_limit_usd: f64,
    pub monthly_limit_usd: f64,
    pub warn_at_percent: u8,
}

/// Channel summary for listing in UI
#[derive(Debug, Clone)]
pub struct ChannelSummary {
    pub id: String,
    pub name: String,
    pub channel_type: String, // "telegram", "discord", etc.
    pub enabled: bool,
    pub description: String,
}

/// Tool info with security attributes
#[derive(Debug, Clone)]
pub struct ToolInfo {
    pub name: String,
    pub description: String,
    pub category: String,
    pub auto_approved: bool,
    pub always_ask: bool,
}

// ──────────────────── API Functions ──────────────────────────

/// Get workspace configuration
pub async fn get_workspace_config() -> WorkspaceConfig {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        WorkspaceConfig {
            workspace_dir: config.workspace_dir.to_string_lossy().to_string(),
            config_path: config.config_path.to_string_lossy().to_string(),
        }
    } else {
        WorkspaceConfig {
            workspace_dir: String::new(),
            config_path: String::new(),
        }
    }
}

/// Get autonomy settings
pub async fn get_autonomy_config() -> AutonomyConfig {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        let a = &config.autonomy;
        let level_str = serde_json::to_string(&a.level)
            .unwrap_or_else(|_| "\"supervised\"".into())
            .trim_matches('"')
            .to_string();
        let level_str: &str = &level_str;
        AutonomyConfig {
            level: level_str.into(),
            workspace_only: a.workspace_only,
            allowed_commands: a.allowed_commands.clone(),
            forbidden_paths: a.forbidden_paths.clone(),
            max_actions_per_hour: a.max_actions_per_hour,
            max_cost_per_day_cents: a.max_cost_per_day_cents,
            require_approval_for_medium_risk: a.require_approval_for_medium_risk,
            block_high_risk_commands: a.block_high_risk_commands,
            auto_approve: a.auto_approve.clone(),
            always_ask: a.always_ask.clone(),
        }
    } else {
        AutonomyConfig {
            level: "supervised".into(),
            workspace_only: true,
            allowed_commands: vec![],
            forbidden_paths: vec![],
            max_actions_per_hour: 20,
            max_cost_per_day_cents: 500,
            require_approval_for_medium_risk: true,
            block_high_risk_commands: true,
            auto_approve: vec![],
            always_ask: vec![],
        }
    }
}

/// Update autonomy level
pub async fn update_autonomy_level(level: String) -> String {
    let mut state = super::agent_api::runtime_state().lock().await;
    let config = match state.config.as_mut() {
        Some(c) => c,
        None => return "error: not initialized".into(),
    };

    let new_level = match serde_json::from_value(serde_json::Value::String(level.clone())) {
        Ok(l) => l,
        Err(_) => return format!("error: unknown level: {level}"),
    };
    config.autonomy.level = new_level;

    state.agent = None;
    "ok".into()
}

/// Get agent config
pub async fn get_agent_config() -> AgentConfigDto {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        let a = &config.agent;
        AgentConfigDto {
            max_tool_iterations: a.max_tool_iterations as u32,
            max_history_messages: a.max_history_messages as u32,
            parallel_tools: a.parallel_tools,
            tool_dispatcher: a.tool_dispatcher.clone(),
            compact_context: a.compact_context,
        }
    } else {
        AgentConfigDto {
            max_tool_iterations: 10,
            max_history_messages: 50,
            parallel_tools: false,
            tool_dispatcher: "auto".into(),
            compact_context: false,
        }
    }
}

/// Update agent settings
pub async fn update_agent_config(
    max_tool_iterations: Option<u32>,
    max_history_messages: Option<u32>,
    parallel_tools: Option<bool>,
    compact_context: Option<bool>,
) -> String {
    let mut state = super::agent_api::runtime_state().lock().await;
    let config = match state.config.as_mut() {
        Some(c) => c,
        None => return "error: not initialized".into(),
    };

    if let Some(v) = max_tool_iterations {
        config.agent.max_tool_iterations = v as usize;
    }
    if let Some(v) = max_history_messages {
        config.agent.max_history_messages = v as usize;
    }
    if let Some(v) = parallel_tools {
        config.agent.parallel_tools = v;
    }
    if let Some(v) = compact_context {
        config.agent.compact_context = v;
    }

    state.agent = None;
    "ok".into()
}

/// Get memory configuration
pub async fn get_memory_config() -> MemoryConfigDto {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        let m = &config.memory;
        MemoryConfigDto {
            backend: m.backend.clone(),
            auto_save: m.auto_save,
            hygiene_enabled: m.hygiene_enabled,
            archive_after_days: m.archive_after_days,
            purge_after_days: m.purge_after_days,
            conversation_retention_days: m.conversation_retention_days,
            embedding_provider: m.embedding_provider.clone(),
            embedding_model: m.embedding_model.clone(),
        }
    } else {
        MemoryConfigDto {
            backend: "sqlite".into(),
            auto_save: true,
            hygiene_enabled: true,
            archive_after_days: 7,
            purge_after_days: 30,
            conversation_retention_days: 30,
            embedding_provider: "none".into(),
            embedding_model: "text-embedding-3-small".into(),
        }
    }
}

/// Get cost configuration
pub async fn get_cost_config() -> CostConfigDto {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        let c = &config.cost;
        CostConfigDto {
            enabled: c.enabled,
            daily_limit_usd: c.daily_limit_usd,
            monthly_limit_usd: c.monthly_limit_usd,
            warn_at_percent: c.warn_at_percent,
        }
    } else {
        CostConfigDto {
            enabled: false,
            daily_limit_usd: 10.0,
            monthly_limit_usd: 100.0,
            warn_at_percent: 80,
        }
    }
}

/// List configured channels with their enabled status
pub async fn list_channels() -> Vec<ChannelSummary> {
    let state = super::agent_api::runtime_state().lock().await;
    let mut channels = Vec::new();

    if let Some(config) = &state.config {
        let ch = &config.channels_config;

        channels.push(ChannelSummary {
            id: "cli".into(),
            name: "CLI".into(),
            channel_type: "cli".into(),
            enabled: ch.cli,
            description: "Terminal command-line interface".into(),
        });

        channels.push(ChannelSummary {
            id: "telegram".into(),
            name: "Telegram".into(),
            channel_type: "telegram".into(),
            enabled: ch.telegram.is_some(),
            description: "Telegram Bot integration".into(),
        });

        channels.push(ChannelSummary {
            id: "discord".into(),
            name: "Discord".into(),
            channel_type: "discord".into(),
            enabled: ch.discord.is_some(),
            description: "Discord Bot integration".into(),
        });

        channels.push(ChannelSummary {
            id: "slack".into(),
            name: "Slack".into(),
            channel_type: "slack".into(),
            enabled: ch.slack.is_some(),
            description: "Slack Bot integration".into(),
        });

        channels.push(ChannelSummary {
            id: "matrix".into(),
            name: "Matrix".into(),
            channel_type: "matrix".into(),
            enabled: ch.matrix.is_some(),
            description: "Matrix (Element) integration".into(),
        });

        channels.push(ChannelSummary {
            id: "webhook".into(),
            name: "Webhook".into(),
            channel_type: "webhook".into(),
            enabled: ch.webhook.is_some(),
            description: "HTTP Webhook endpoint".into(),
        });

        channels.push(ChannelSummary {
            id: "email".into(),
            name: "Email".into(),
            channel_type: "email".into(),
            enabled: ch.email.is_some(),
            description: "Email (SMTP/IMAP) integration".into(),
        });

        channels.push(ChannelSummary {
            id: "lark".into(),
            name: "Lark / Feishu".into(),
            channel_type: "lark".into(),
            enabled: ch.lark.is_some() || ch.feishu.is_some(),
            description: "Lark / Feishu Bot integration".into(),
        });

        channels.push(ChannelSummary {
            id: "dingtalk".into(),
            name: "DingTalk".into(),
            channel_type: "dingtalk".into(),
            enabled: ch.dingtalk.is_some(),
            description: "DingTalk Bot integration".into(),
        });

        channels.push(ChannelSummary {
            id: "whatsapp".into(),
            name: "WhatsApp".into(),
            channel_type: "whatsapp".into(),
            enabled: ch.whatsapp.is_some(),
            description: "WhatsApp Cloud / Web integration".into(),
        });

        channels.push(ChannelSummary {
            id: "signal".into(),
            name: "Signal".into(),
            channel_type: "signal".into(),
            enabled: ch.signal.is_some(),
            description: "Signal Messenger integration".into(),
        });

        channels.push(ChannelSummary {
            id: "irc".into(),
            name: "IRC".into(),
            channel_type: "irc".into(),
            enabled: ch.irc.is_some(),
            description: "IRC chat integration".into(),
        });
    }

    channels
}

/// List tools with their approval status based on autonomy config
pub async fn list_tools_with_status() -> Vec<ToolInfo> {
    let state = super::agent_api::runtime_state().lock().await;
    let (auto_approve, always_ask) = if let Some(config) = &state.config {
        (
            config.autonomy.auto_approve.clone(),
            config.autonomy.always_ask.clone(),
        )
    } else {
        (vec![], vec![])
    };

    let tools = vec![
        ("shell", "Execute shell commands", "core"),
        ("file_read", "Read file contents", "core"),
        ("file_write", "Write content to files", "core"),
        ("file_edit", "Edit files with search/replace", "core"),
        ("glob_search", "Find files by glob pattern", "core"),
        ("content_search", "Search file contents", "core"),
        ("git_operations", "Git version control", "vcs"),
        ("web_search", "Search the web", "web"),
        ("web_fetch", "Fetch webpage content", "web"),
        ("http_request", "HTTP API requests", "web"),
        ("browser", "Browser automation", "web"),
        ("memory_store", "Store in memory", "memory"),
        ("memory_recall", "Recall from memory", "memory"),
        ("memory_forget", "Remove from memory", "memory"),
        ("screenshot", "Take screenshots", "system"),
        ("pdf_read", "Extract PDF text", "file"),
        ("image_info", "Image metadata", "file"),
        ("schedule", "Schedule future tasks", "system"),
        ("delegate", "Delegate to sub-agent", "agent"),
        ("cron_add", "Add cron job", "cron"),
        ("cron_list", "List cron jobs", "cron"),
        ("cron_remove", "Remove cron job", "cron"),
    ];

    tools
        .into_iter()
        .map(|(name, desc, cat)| ToolInfo {
            name: name.to_string(),
            description: desc.to_string(),
            category: cat.to_string(),
            auto_approved: auto_approve.contains(&name.to_string()),
            always_ask: always_ask.contains(&name.to_string()),
        })
        .collect()
}
