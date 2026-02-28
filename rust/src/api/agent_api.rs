use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use std::collections::HashMap;
use std::sync::OnceLock;
use tokio::sync::Mutex as TokioMutex;

// ──────────────────────────── DTOs ────────────────────────────

/// Events emitted during agent processing, streamed to Flutter UI

#[derive(Debug, Clone)]
pub enum AgentEvent {
    /// Agent is thinking / preparing
    Thinking,
    /// Incremental text token from LLM
    TextDelta { text: String },
    /// LLM started calling a tool
    ToolCallStart { name: String, args: String },
    /// Tool call completed
    ToolCallEnd {
        name: String,
        result: String,
        success: bool,
    },
    /// Full message generation complete
    MessageComplete {
        input_tokens: Option<u64>,
        output_tokens: Option<u64>,
    },
    /// Error during processing
    Error { message: String },
}

/// A single message in a chat session

#[derive(Debug, Clone)]
pub struct ChatMessageDto {
    pub id: String,
    pub role: String,
    pub content: String,
    pub timestamp: i64,
    pub tool_calls: Option<Vec<ToolCallDto>>,
}

/// Tool call information

#[derive(Debug, Clone)]
pub struct ToolCallDto {
    pub id: String,
    pub name: String,
    pub arguments: String,
    pub result: Option<String>,
    pub success: Option<bool>,
}

/// Chat session info

#[derive(Debug, Clone)]
pub struct ChatSessionInfo {
    pub id: String,
    pub title: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub message_count: u32,
}

/// Tool specification for UI display

#[derive(Debug, Clone)]
pub struct ToolSpecDto {
    pub name: String,
    pub description: String,
}

/// Runtime status information

#[derive(Debug, Clone)]
pub struct RuntimeStatus {
    pub initialized: bool,
    pub has_api_key: bool,
    pub provider: String,
    pub model: String,
}

// ──────────────────────── Runtime State ───────────────────────

pub(crate) struct RuntimeState {
    pub(crate) config: Option<zeroclaw::Config>,
    pub(crate) active_session_id: Option<String>,
    pub(crate) agent: Option<zeroclaw::agent::Agent>,
}

pub(crate) fn runtime_state() -> &'static TokioMutex<RuntimeState> {
    static STATE: OnceLock<TokioMutex<RuntimeState>> = OnceLock::new();
    STATE.get_or_init(|| {
        TokioMutex::new(RuntimeState {
            config: None,
            active_session_id: None,
            agent: None,
        })
    })
}

// ──────────────────── Initialization API ──────────────────────

/// Initialize the agent runtime: load zeroclaw config from ~/.zeroclaw/config.toml.
/// Returns a status string describing what was loaded.
pub async fn init_runtime() -> String {
    // Initialize tracing for debug logging
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("warn")),
        )
        .try_init();

    match zeroclaw::Config::load_or_init().await {
        Ok(config) => {
            let info = format!(
                "provider={}, model={}, has_key={}",
                config.default_provider.as_deref().unwrap_or("(none)"),
                config.default_model.as_deref().unwrap_or("(none)"),
                config.api_key.is_some(),
            );
            let mut state = runtime_state().lock().await;
            state.config = Some(config);
            state.agent = None;
            state.active_session_id = None;
            tracing::info!("DeskClaw runtime initialized: {info}");
            info
        }
        Err(e) => {
            tracing::error!("Failed to load config: {e}");
            format!("error: {e}")
        }
    }
}

/// Check if the runtime has a loaded config with an API key
pub async fn get_runtime_status() -> RuntimeStatus {
    let state = runtime_state().lock().await;
    match &state.config {
        Some(config) => RuntimeStatus {
            initialized: true,
            has_api_key: config.api_key.is_some(),
            provider: config
                .default_provider
                .clone()
                .unwrap_or_else(|| "openrouter".into()),
            model: config
                .default_model
                .clone()
                .unwrap_or_else(|| "anthropic/claude-sonnet-4-20250514".into()),
        },
        None => RuntimeStatus {
            initialized: false,
            has_api_key: false,
            provider: String::new(),
            model: String::new(),
        },
    }
}

// ──────────────────── Config Management ───────────────────────

/// Update configuration fields. Invalidates the current agent so the next
/// message will create a fresh agent with the new settings.
pub async fn update_config(
    provider: Option<String>,
    model: Option<String>,
    api_key: Option<String>,
    api_base: Option<String>,
    temperature: Option<f64>,
) -> String {
    let mut state = runtime_state().lock().await;
    let config = match state.config.as_mut() {
        Some(c) => c,
        None => return "error: runtime not initialized".into(),
    };

    // Handle api_base first since "compatible" provider needs it
    if let Some(base) = api_base {
        config.api_url = if base.is_empty() {
            None
        } else {
            Some(base.clone())
        };
    }
    if let Some(p) = provider {
        // Map "compatible" to zeroclaw's "custom:<url>" format
        if p == "compatible" {
            let base_url = config.api_url.clone().unwrap_or_default();
            if !base_url.is_empty() {
                config.default_provider = Some(format!("custom:{base_url}"));
            } else {
                config.default_provider = Some("compatible".into());
            }
        } else {
            config.default_provider = Some(p);
        }
    }
    if let Some(m) = model {
        config.default_model = Some(m);
    }
    if let Some(k) = api_key {
        config.api_key = if k.is_empty() { None } else { Some(k) };
    }
    if let Some(t) = temperature {
        config.default_temperature = t;
    }

    // Invalidate agent so it gets recreated with new config
    state.agent = None;
    state.active_session_id = None;

    "ok".into()
}

/// Persist current config to disk (~/.zeroclaw/config.toml).
/// Reads the existing file, merges relevant fields, and writes back.
pub async fn save_config_to_disk() -> String {
    let state = runtime_state().lock().await;
    let config = match &state.config {
        Some(c) => c,
        None => return "error: no config loaded".into(),
    };

    let config_path = &config.config_path;
    if config_path.as_os_str().is_empty() {
        return "error: config_path not set".into();
    }

    // Read existing TOML or start fresh
    let mut table: toml::Table = match tokio::fs::read_to_string(config_path).await {
        Ok(content) => content.parse().unwrap_or_default(),
        Err(_) => toml::Table::new(),
    };

    // Update the user-facing fields
    if let Some(ref provider) = config.default_provider {
        table.insert(
            "default_provider".into(),
            toml::Value::String(provider.clone()),
        );
    }
    if let Some(ref model) = config.default_model {
        table.insert("default_model".into(), toml::Value::String(model.clone()));
    }
    if let Some(ref key) = config.api_key {
        table.insert("api_key".into(), toml::Value::String(key.clone()));
    }
    if let Some(ref url) = config.api_url {
        table.insert("api_url".into(), toml::Value::String(url.clone()));
    }
    table.insert(
        "default_temperature".into(),
        toml::Value::Float(config.default_temperature),
    );

    let output = match toml::to_string_pretty(&table) {
        Ok(s) => s,
        Err(e) => return format!("error: serialize failed: {e}"),
    };

    match tokio::fs::write(config_path, output).await {
        Ok(()) => "ok".into(),
        Err(e) => format!("error: write failed: {e}"),
    }
}

/// Get the current config values as an AppConfig DTO
pub async fn get_current_config() -> super::config_api::AppConfig {
    let state = runtime_state().lock().await;
    if let Some(config) = &state.config {
        let raw_provider = config
            .default_provider
            .clone()
            .unwrap_or_else(|| "openrouter".into());

        // Reverse-map zeroclaw's "custom:<url>" back to UI's "compatible"
        let (ui_provider, ui_api_base) = if raw_provider.starts_with("custom:") {
            let url = raw_provider
                .strip_prefix("custom:")
                .unwrap_or("")
                .to_string();
            ("compatible".to_string(), Some(url))
        } else {
            (raw_provider, config.api_url.clone())
        };

        super::config_api::AppConfig {
            provider: ui_provider,
            model: config
                .default_model
                .clone()
                .unwrap_or_else(|| "anthropic/claude-sonnet-4-20250514".into()),
            api_key: config.api_key.clone().unwrap_or_default(),
            api_base: ui_api_base,
            temperature: config.default_temperature,
            max_tool_iterations: config.agent.max_tool_iterations as u32,
            language: "en".into(),
        }
    } else {
        super::config_api::AppConfig::default()
    }
}

// ──────────────────── Session Management ──────────────────────

/// Create a new chat session descriptor
#[frb(sync)]
pub fn create_session() -> ChatSessionInfo {
    let now = chrono::Utc::now().timestamp();
    ChatSessionInfo {
        id: uuid::Uuid::new_v4().to_string(),
        title: "New Chat".into(),
        created_at: now,
        updated_at: now,
        message_count: 0,
    }
}

/// Clear the current session (resets agent conversation history)
pub async fn clear_session() {
    let mut state = runtime_state().lock().await;
    if let Some(agent) = state.agent.as_mut() {
        agent.clear_history();
    }
    state.active_session_id = None;
}

/// Switch to a different session — clears agent history for the new context
pub async fn switch_session(session_id: String) {
    let mut state = runtime_state().lock().await;
    if state.active_session_id.as_ref() != Some(&session_id) {
        if let Some(agent) = state.agent.as_mut() {
            agent.clear_history();
        }
        state.active_session_id = Some(session_id);
    }
}

// ──────────────────── Message Handling ────────────────────────

/// Send a message to the zeroclaw agent and get response events.
/// This calls the real LLM provider and executes tools as needed.
pub async fn send_message(session_id: String, message: String) -> Vec<AgentEvent> {
    let mut state = runtime_state().lock().await;

    // Ensure config exists
    let config = match state.config.as_ref() {
        Some(c) => c.clone(),
        None => {
            return vec![AgentEvent::Error {
                message: "Runtime not initialized. Call init_runtime() first.".into(),
            }];
        }
    };

    // Check API key (required for cloud providers)
    let provider_name = config.default_provider.as_deref().unwrap_or("openrouter");
    let needs_key = !matches!(provider_name, "ollama");
    if needs_key && config.api_key.is_none() {
        return vec![AgentEvent::Error {
            message: "No API key configured. Please set your API key in Settings → Models.".into(),
        }];
    }

    // Create agent if needed (new session or config changed)
    let need_new_agent =
        state.agent.is_none() || state.active_session_id.as_ref() != Some(&session_id);

    if need_new_agent {
        tracing::info!("Creating new agent for session {session_id}");
        match zeroclaw::agent::Agent::from_config(&config) {
            Ok(agent) => {
                state.agent = Some(agent);
                state.active_session_id = Some(session_id);
            }
            Err(e) => {
                tracing::error!("Failed to create agent: {e}");
                return vec![AgentEvent::Error {
                    message: format!("Failed to create agent: {e}"),
                }];
            }
        }
    }

    let agent = state.agent.as_mut().unwrap();

    // Track history length before turn (to extract tool call events after)
    let history_before = agent.history().len();

    // Execute the agent turn (calls real LLM + tools)
    let mut events = Vec::new();

    match agent.turn(&message).await {
        Ok(response) => {
            // Extract tool call events from agent's conversation history
            let history = agent.history();
            let mut tool_name_map: HashMap<String, String> = HashMap::new();

            for msg in history.iter().skip(history_before) {
                match msg {
                    zeroclaw::providers::ConversationMessage::AssistantToolCalls {
                        tool_calls,
                        ..
                    } => {
                        for tc in tool_calls {
                            tool_name_map.insert(tc.id.clone(), tc.name.clone());
                            events.push(AgentEvent::ToolCallStart {
                                name: tc.name.clone(),
                                args: truncate_str(&tc.arguments, 1000),
                            });
                        }
                    }
                    zeroclaw::providers::ConversationMessage::ToolResults(results) => {
                        for r in results {
                            let name = tool_name_map
                                .get(&r.tool_call_id)
                                .cloned()
                                .unwrap_or_else(|| r.tool_call_id.clone());
                            events.push(AgentEvent::ToolCallEnd {
                                name,
                                result: truncate_str(&r.content, 500),
                                success: true,
                            });
                        }
                    }
                    _ => {}
                }
            }

            // Send the final response text
            events.push(AgentEvent::TextDelta { text: response });
            events.push(AgentEvent::MessageComplete {
                input_tokens: None,
                output_tokens: None,
            });
        }
        Err(e) => {
            tracing::error!("Agent turn error: {e}");
            events.push(AgentEvent::Error {
                message: e.to_string(),
            });
        }
    }

    events
}

/// Streaming version: sends agent events one-by-one through a StreamSink.
/// This allows the Flutter UI to update in real-time as the agent processes.
pub async fn send_message_stream(
    session_id: String,
    message: String,
    sink: StreamSink<AgentEvent>,
) {
    let mut state = runtime_state().lock().await;

    let config = match state.config.as_ref() {
        Some(c) => c.clone(),
        None => {
            let _ = sink.add(AgentEvent::Error {
                message: "Runtime not initialized. Call init_runtime() first.".into(),
            });
            return;
        }
    };

    let provider_name = config.default_provider.as_deref().unwrap_or("openrouter");
    let needs_key = !matches!(provider_name, "ollama");
    if needs_key && config.api_key.is_none() {
        let _ = sink.add(AgentEvent::Error {
            message: "No API key configured. Please set your API key in Settings → Models.".into(),
        });
        return;
    }

    // Emit thinking event
    let _ = sink.add(AgentEvent::Thinking);

    let need_new_agent =
        state.agent.is_none() || state.active_session_id.as_ref() != Some(&session_id);

    if need_new_agent {
        tracing::info!("Creating new agent for session {session_id}");
        match zeroclaw::agent::Agent::from_config(&config) {
            Ok(agent) => {
                state.agent = Some(agent);
                state.active_session_id = Some(session_id);
            }
            Err(e) => {
                tracing::error!("Failed to create agent: {e}");
                let _ = sink.add(AgentEvent::Error {
                    message: format!("Failed to create agent: {e}"),
                });
                return;
            }
        }
    }

    let agent = state.agent.as_mut().unwrap();
    let history_before = agent.history().len();

    match agent.turn(&message).await {
        Ok(response) => {
            let history = agent.history();
            let mut tool_name_map: HashMap<String, String> = HashMap::new();

            for msg in history.iter().skip(history_before) {
                match msg {
                    zeroclaw::providers::ConversationMessage::AssistantToolCalls {
                        tool_calls,
                        ..
                    } => {
                        for tc in tool_calls {
                            tool_name_map.insert(tc.id.clone(), tc.name.clone());
                            let _ = sink.add(AgentEvent::ToolCallStart {
                                name: tc.name.clone(),
                                args: truncate_str(&tc.arguments, 1000),
                            });
                        }
                    }
                    zeroclaw::providers::ConversationMessage::ToolResults(results) => {
                        for r in results {
                            let name = tool_name_map
                                .get(&r.tool_call_id)
                                .cloned()
                                .unwrap_or_else(|| r.tool_call_id.clone());
                            let _ = sink.add(AgentEvent::ToolCallEnd {
                                name,
                                result: truncate_str(&r.content, 500),
                                success: true,
                            });
                        }
                    }
                    _ => {}
                }
            }

            // Stream text in chunks for real-time feel
            let chunk_size = 20;
            let chars: Vec<char> = response.chars().collect();
            for chunk in chars.chunks(chunk_size) {
                let text: String = chunk.iter().collect();
                let _ = sink.add(AgentEvent::TextDelta { text });
            }

            let _ = sink.add(AgentEvent::MessageComplete {
                input_tokens: None,
                output_tokens: None,
            });
        }
        Err(e) => {
            tracing::error!("Agent turn error: {e}");
            let _ = sink.add(AgentEvent::Error {
                message: e.to_string(),
            });
        }
    }
}

// ──────────────────── Tool Listing ────────────────────────────

/// List available tools (static list of zeroclaw's built-in tools)
#[frb(sync)]
pub fn list_tools() -> Vec<ToolSpecDto> {
    vec![
        ToolSpecDto {
            name: "shell".into(),
            description: "Execute shell commands in the workspace".into(),
        },
        ToolSpecDto {
            name: "file_read".into(),
            description: "Read file contents with line range support".into(),
        },
        ToolSpecDto {
            name: "file_write".into(),
            description: "Write content to files".into(),
        },
        ToolSpecDto {
            name: "file_edit".into(),
            description: "Edit files with search and replace".into(),
        },
        ToolSpecDto {
            name: "glob_search".into(),
            description: "Find files by glob pattern".into(),
        },
        ToolSpecDto {
            name: "content_search".into(),
            description: "Search file contents with regex".into(),
        },
        ToolSpecDto {
            name: "web_search".into(),
            description: "Search the web for information".into(),
        },
        ToolSpecDto {
            name: "web_fetch".into(),
            description: "Fetch and extract webpage content".into(),
        },
        ToolSpecDto {
            name: "http_request".into(),
            description: "Make HTTP API requests (GET/POST/PUT/DELETE)".into(),
        },
        ToolSpecDto {
            name: "git_operations".into(),
            description: "Git version control operations".into(),
        },
        ToolSpecDto {
            name: "memory_store".into(),
            description: "Store information in long-term memory".into(),
        },
        ToolSpecDto {
            name: "memory_recall".into(),
            description: "Recall stored information".into(),
        },
        ToolSpecDto {
            name: "memory_forget".into(),
            description: "Remove information from memory".into(),
        },
        ToolSpecDto {
            name: "screenshot".into(),
            description: "Take a screenshot of the screen".into(),
        },
        ToolSpecDto {
            name: "pdf_read".into(),
            description: "Extract text from PDF files".into(),
        },
        ToolSpecDto {
            name: "image_info".into(),
            description: "Analyze image metadata and content".into(),
        },
        ToolSpecDto {
            name: "schedule".into(),
            description: "Schedule tasks for later execution".into(),
        },
        ToolSpecDto {
            name: "delegate".into(),
            description: "Delegate a sub-task to another agent".into(),
        },
        ToolSpecDto {
            name: "browser".into(),
            description: "Browser automation and web interaction".into(),
        },
    ]
}

// ──────────────────── Helpers ─────────────────────────────────

fn truncate_str(s: &str, max_len: usize) -> String {
    if s.len() > max_len {
        format!("{}…", &s[..max_len])
    } else {
        s.to_string()
    }
}
