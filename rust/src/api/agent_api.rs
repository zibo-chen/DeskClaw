use crate::frb_generated::StreamSink;
use flutter_rust_bridge::frb;
use std::sync::{Arc, OnceLock};
use tokio::sync::{Mutex as TokioMutex, RwLock};

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
//
// Split into two separate locks to reduce contention:
//   - `ConfigState` (RwLock): config + session id — short reads, rare writes
//   - `AgentHandle` (Arc<TokioMutex>): the Agent itself — held only during turn()

pub(crate) struct ConfigState {
    pub(crate) config: Option<zeroclaw::Config>,
    pub(crate) active_session_id: Option<String>,
}

pub(crate) fn config_state() -> &'static RwLock<ConfigState> {
    static STATE: OnceLock<RwLock<ConfigState>> = OnceLock::new();
    STATE.get_or_init(|| {
        RwLock::new(ConfigState {
            config: None,
            active_session_id: None,
        })
    })
}

/// The Agent is behind its own Arc<Mutex> so that config reads don't block on
/// an in-flight LLM call, and vice-versa.
pub(crate) fn agent_handle() -> &'static TokioMutex<Option<zeroclaw::agent::Agent>> {
    static AGENT: OnceLock<TokioMutex<Option<zeroclaw::agent::Agent>>> = OnceLock::new();
    AGENT.get_or_init(|| TokioMutex::new(None))
}

// ──────────────────── Initialization API ──────────────────────

/// Initialize the agent runtime: load zeroclaw config from ~/.zeroclaw/config.toml.
/// Returns a status string describing what was loaded.
pub async fn init_runtime() -> String {
    crate::logging::init_rust_logging();

    match zeroclaw::Config::load_or_init().await {
        Ok(config) => {
            let info = format!(
                "provider={}, model={}, has_key={}",
                config.default_provider.as_deref().unwrap_or("(none)"),
                config.default_model.as_deref().unwrap_or("(none)"),
                config.api_key.is_some(),
            );
            {
                let mut cs = config_state().write().await;
                cs.config = Some(config);
                cs.active_session_id = None;
            }
            // Invalidate any existing agent
            *agent_handle().lock().await = None;
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
    let cs = config_state().read().await;
    match &cs.config {
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
    let mut cs = config_state().write().await;
    let config = match cs.config.as_mut() {
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
    cs.active_session_id = None;
    drop(cs);
    *agent_handle().lock().await = None;

    "ok".into()
}

/// Persist current config to disk (~/.zeroclaw/config.toml).
/// Reads the existing file, merges relevant fields, and writes back.
pub async fn save_config_to_disk() -> String {
    let cs = config_state().read().await;
    let config = match &cs.config {
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

    // ── Persist feature toggles ──────────────────────────────
    // [web_search]
    let mut ws_table = table
        .get("web_search")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    ws_table.insert(
        "enabled".into(),
        toml::Value::Boolean(config.web_search.enabled),
    );
    table.insert("web_search".into(), toml::Value::Table(ws_table));

    // [web_fetch]
    let mut wf_table = table
        .get("web_fetch")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    wf_table.insert(
        "enabled".into(),
        toml::Value::Boolean(config.web_fetch.enabled),
    );
    table.insert("web_fetch".into(), toml::Value::Table(wf_table));

    // [browser]
    let mut br_table = table
        .get("browser")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    br_table.insert(
        "enabled".into(),
        toml::Value::Boolean(config.browser.enabled),
    );
    table.insert("browser".into(), toml::Value::Table(br_table));

    // [http_request]
    let mut hr_table = table
        .get("http_request")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    hr_table.insert(
        "enabled".into(),
        toml::Value::Boolean(config.http_request.enabled),
    );
    table.insert("http_request".into(), toml::Value::Table(hr_table));

    // [memory]
    let mut mem_table = table
        .get("memory")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    mem_table.insert(
        "auto_save".into(),
        toml::Value::Boolean(config.memory.auto_save),
    );
    table.insert("memory".into(), toml::Value::Table(mem_table));

    // [cost]
    let mut cost_table = table
        .get("cost")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    cost_table.insert("enabled".into(), toml::Value::Boolean(config.cost.enabled));
    table.insert("cost".into(), toml::Value::Table(cost_table));

    // [skills]
    let mut skills_table = table
        .get("skills")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    skills_table.insert(
        "open_skills_enabled".into(),
        toml::Value::Boolean(config.skills.open_skills_enabled),
    );
    let injection_mode = match config.skills.prompt_injection_mode {
        zeroclaw::config::SkillsPromptInjectionMode::Compact => "compact",
        _ => "full",
    };
    skills_table.insert(
        "prompt_injection_mode".into(),
        toml::Value::String(injection_mode.into()),
    );
    table.insert("skills".into(), toml::Value::Table(skills_table));

    // ── Persist autonomy / tool approval settings ────────────
    let mut autonomy_table = table
        .get("autonomy")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    autonomy_table.insert(
        "auto_approve".into(),
        toml::Value::Array(
            config
                .autonomy
                .auto_approve
                .iter()
                .map(|s| toml::Value::String(s.clone()))
                .collect(),
        ),
    );
    autonomy_table.insert(
        "always_ask".into(),
        toml::Value::Array(
            config
                .autonomy
                .always_ask
                .iter()
                .map(|s| toml::Value::String(s.clone()))
                .collect(),
        ),
    );
    table.insert("autonomy".into(), toml::Value::Table(autonomy_table));

    // ── Persist delegate agents [agents.<name>] ─────────────
    let mut agents_table = toml::Table::new();
    for (name, agent_cfg) in &config.agents {
        let mut entry = toml::Table::new();
        entry.insert(
            "provider".into(),
            toml::Value::String(agent_cfg.provider.clone()),
        );
        entry.insert("model".into(), toml::Value::String(agent_cfg.model.clone()));
        if let Some(ref sp) = agent_cfg.system_prompt {
            entry.insert("system_prompt".into(), toml::Value::String(sp.clone()));
        }
        if let Some(ref key) = agent_cfg.api_key {
            entry.insert("api_key".into(), toml::Value::String(key.clone()));
        }
        if let Some(temp) = agent_cfg.temperature {
            entry.insert("temperature".into(), toml::Value::Float(temp));
        }
        entry.insert(
            "max_depth".into(),
            toml::Value::Integer(agent_cfg.max_depth as i64),
        );
        if agent_cfg.agentic {
            entry.insert("agentic".into(), toml::Value::Boolean(true));
            entry.insert(
                "allowed_tools".into(),
                toml::Value::Array(
                    agent_cfg
                        .allowed_tools
                        .iter()
                        .map(|s| toml::Value::String(s.clone()))
                        .collect(),
                ),
            );
            entry.insert(
                "max_iterations".into(),
                toml::Value::Integer(agent_cfg.max_iterations as i64),
            );
        }
        agents_table.insert(name.clone(), toml::Value::Table(entry));
    }
    if !agents_table.is_empty() {
        table.insert("agents".into(), toml::Value::Table(agents_table));
    } else {
        table.remove("agents");
    }

    // [proxy]
    let mut proxy_table = table
        .get("proxy")
        .and_then(|v| v.as_table())
        .cloned()
        .unwrap_or_default();
    proxy_table.insert(
        "enabled".into(),
        toml::Value::Boolean(config.proxy.enabled),
    );
    if let Some(ref url) = config.proxy.http_proxy {
        proxy_table.insert("http_proxy".into(), toml::Value::String(url.clone()));
    } else {
        proxy_table.remove("http_proxy");
    }
    if let Some(ref url) = config.proxy.https_proxy {
        proxy_table.insert("https_proxy".into(), toml::Value::String(url.clone()));
    } else {
        proxy_table.remove("https_proxy");
    }
    if let Some(ref url) = config.proxy.all_proxy {
        proxy_table.insert("all_proxy".into(), toml::Value::String(url.clone()));
    } else {
        proxy_table.remove("all_proxy");
    }
    if !config.proxy.no_proxy.is_empty() {
        proxy_table.insert(
            "no_proxy".into(),
            toml::Value::Array(
                config
                    .proxy
                    .no_proxy
                    .iter()
                    .map(|s| toml::Value::String(s.clone()))
                    .collect(),
            ),
        );
    } else {
        proxy_table.remove("no_proxy");
    }
    let scope_str = match config.proxy.scope {
        zeroclaw::config::ProxyScope::Environment => "environment",
        zeroclaw::config::ProxyScope::Zeroclaw => "zeroclaw",
        zeroclaw::config::ProxyScope::Services => "services",
    };
    proxy_table.insert("scope".into(), toml::Value::String(scope_str.into()));
    if !config.proxy.services.is_empty() {
        proxy_table.insert(
            "services".into(),
            toml::Value::Array(
                config
                    .proxy
                    .services
                    .iter()
                    .map(|s| toml::Value::String(s.clone()))
                    .collect(),
            ),
        );
    } else {
        proxy_table.remove("services");
    }
    table.insert("proxy".into(), toml::Value::Table(proxy_table));

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
    let cs = config_state().read().await;
    if let Some(config) = &cs.config {
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
    {
        let mut agent = agent_handle().lock().await;
        if let Some(a) = agent.as_mut() {
            a.clear_history();
        }
    }
    config_state().write().await.active_session_id = None;
}

/// Switch to a different session — clears agent history for the new context
pub async fn switch_session(session_id: String) {
    let mut cs = config_state().write().await;
    if cs.active_session_id.as_ref() != Some(&session_id) {
        // Release config lock before touching agent
        cs.active_session_id = Some(session_id);
        drop(cs);
        let mut agent = agent_handle().lock().await;
        if let Some(a) = agent.as_mut() {
            a.clear_history();
        }
    }
}

// ──────────────────── Message Handling ────────────────────────

/// Helper: ensure agent is created and session is current.
/// Takes a short config read-lock, then a separate agent lock.
/// Returns an error string if something goes wrong.
async fn ensure_agent(session_id: &str) -> Result<(), String> {
    // 1. Read config (short-lived RwLock read)
    let config = {
        let cs = config_state().read().await;
        match &cs.config {
            Some(c) => c.clone(),
            None => return Err("Runtime not initialized. Call init_runtime() first.".into()),
        }
    };

    // 2. Check API key
    let provider_name = config.default_provider.as_deref().unwrap_or("openrouter");
    let needs_key = !matches!(provider_name, "ollama");
    if needs_key && config.api_key.is_none() {
        return Err("No API key configured. Please set your API key in Settings → Models.".into());
    }

    // 3. Check if we need a new agent (separate locks, no overlap)
    let need_new = {
        let cs = config_state().read().await;
        let agent = agent_handle().lock().await;
        agent.is_none() || cs.active_session_id.as_deref() != Some(session_id)
    };

    if need_new {
        tracing::info!("Creating new agent for session {session_id}");
        let agent = zeroclaw::agent::Agent::from_config(&config)
            .map_err(|e| format!("Failed to create agent: {e}"))?;
        *agent_handle().lock().await = Some(agent);
        config_state().write().await.active_session_id = Some(session_id.to_string());
    }

    Ok(())
}

/// Send a message to the zeroclaw agent and get response events.
/// This calls the real LLM provider and executes tools as needed.
pub async fn send_message(session_id: String, message: String) -> Vec<AgentEvent> {
    // Ensure agent ready — short config lock, released before turn()
    if let Err(msg) = ensure_agent(&session_id).await {
        return vec![AgentEvent::Error { message: msg }];
    }

    // Lock agent only for the actual turn — config_state is NOT locked here,
    // so other APIs (get_runtime_status, get_current_config, etc.) stay responsive.
    let mut agent_guard = agent_handle().lock().await;
    let agent = match agent_guard.as_mut() {
        Some(a) => a,
        None => {
            return vec![AgentEvent::Error {
                message: "Agent not available".into(),
            }];
        }
    };

    let history_before = agent.history().len();
    let mut events = Vec::new();

    match agent.turn(&message).await {
        Ok(response) => {
            // Extract tool call events from conversation history
            let history = agent.history();
            let mut tool_name_map: std::collections::HashMap<String, String> =
                std::collections::HashMap::new();

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

/// Streaming version: sends agent events in real-time through a StreamSink.
///
/// Uses zeroclaw's `Agent::turn_streaming()` which delegates to the internal
/// `run_tool_call_loop` with an `on_delta` channel.  Tool-start / tool-end /
/// thinking events are streamed **as they happen**, not after the full turn
/// completes.
pub async fn send_message_stream(
    session_id: String,
    message: String,
    sink: StreamSink<AgentEvent>,
) {
    // Ensure agent ready — short config lock
    if let Err(msg) = ensure_agent(&session_id).await {
        let _ = sink.add(AgentEvent::Error { message: msg });
        return;
    }

    let _ = sink.add(AgentEvent::Thinking);

    // Create an mpsc channel for streaming deltas from zeroclaw
    let (tx, mut rx) = tokio::sync::mpsc::channel::<String>(64);

    // Wrap the sink in an Arc so it can be shared with the relay task
    let sink = Arc::new(sink);
    let sink_clone = sink.clone();

    // Spawn a relay task that converts zeroclaw's string-based delta protocol
    // into typed AgentEvent messages for Flutter.
    let relay_handle = tokio::spawn(async move {
        while let Some(delta) = rx.recv().await {
            let trimmed = delta.trim();

            // Sentinel: clear accumulated progress (final answer coming)
            if trimmed == "\x00CLEAR\x00" {
                continue; // Flutter handles this differently
            }

            // Structured tool result: \x01TOOL_RESULT\x02name\x02success\x02output\x01
            // Sent right after ✅/❌ with the actual tool output.
            if delta.starts_with('\x01') && delta.contains("TOOL_RESULT\x02") {
                if let Some(rest) = delta
                    .trim_start_matches('\x01')
                    .strip_prefix("TOOL_RESULT\x02")
                {
                    // rest = "name\x02success\x02output\x01"
                    let rest = rest.trim_end_matches('\x01');
                    let parts: Vec<&str> = rest.splitn(3, '\x02').collect();
                    if parts.len() == 3 {
                        let name = parts[0].to_string();
                        let success = parts[1] == "true";
                        let result = parts[2].to_string();
                        let _ = sink_clone.add(AgentEvent::ToolCallEnd {
                            name,
                            result,
                            success,
                        });
                    }
                }
                continue;
            }

            // Tool start: "⏳ tool_name: args" or "⏳ tool_name"
            if trimmed.starts_with('⏳') {
                let rest = trimmed.trim_start_matches('⏳').trim();
                let (name, args) = if let Some((n, a)) = rest.split_once(':') {
                    (n.trim().to_string(), a.trim().to_string())
                } else {
                    (rest.to_string(), String::new())
                };
                let _ = sink_clone.add(AgentEvent::ToolCallStart { name, args });
                continue;
            }

            // Tool success: "✅ tool_name (Ns)"
            // Status-only; the actual result follows in the TOOL_RESULT message.
            if trimmed.starts_with('✅') {
                continue;
            }

            // Tool failure: "❌ tool_name (Ns)"
            // Status-only; the actual result follows in the TOOL_RESULT message.
            if trimmed.starts_with('❌') {
                continue;
            }

            // Thinking progress: "🤔 Thinking..."
            if trimmed.starts_with('🤔') {
                let _ = sink_clone.add(AgentEvent::Thinking);
                continue;
            }

            // Tool call count: "💬 Got N tool call(s) ..."
            if trimmed.starts_with('💬') {
                // Informational — skip or treat as thinking
                continue;
            }

            // Everything else is streamed text content
            if !delta.is_empty() {
                let _ = sink_clone.add(AgentEvent::TextDelta { text: delta });
            }
        }
    });

    // Lock only the agent (not config) for the duration of the LLM turn
    let result = {
        let mut agent_guard = agent_handle().lock().await;
        let agent = match agent_guard.as_mut() {
            Some(a) => a,
            None => {
                let _ = sink.add(AgentEvent::Error {
                    message: "Agent not available".into(),
                });
                return;
            }
        };
        agent.turn_streaming(&message, tx).await
    };

    // Wait for relay task to finish draining
    let _ = relay_handle.await;

    match result {
        Ok(_) => {
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

/// List available tools dynamically from the agent's registered tool specs.
/// Falls back to a minimal static list if no agent is currently initialized.
///
/// Note: kept as sync (#[frb(sync)]) to match the existing FRB generated binding.
/// Uses `try_lock` to avoid blocking if agent is mid-turn.
#[frb(sync)]
pub fn list_tools() -> Vec<ToolSpecDto> {
    // Try non-blocking lock — if agent is busy (mid-turn), fall back to static list
    if let Ok(guard) = agent_handle().try_lock() {
        if let Some(agent) = guard.as_ref() {
            return agent
                .tool_specs()
                .iter()
                .map(|spec| ToolSpecDto {
                    name: spec.name.clone(),
                    description: spec.description.clone(),
                })
                .collect();
        }
    }

    // Fallback: no agent yet or agent is busy
    vec![
        ToolSpecDto {
            name: "shell".into(),
            description: "Execute shell commands".into(),
        },
        ToolSpecDto {
            name: "file_read".into(),
            description: "Read file contents".into(),
        },
        ToolSpecDto {
            name: "file_write".into(),
            description: "Write content to files".into(),
        },
        ToolSpecDto {
            name: "file_edit".into(),
            description: "Edit files with search/replace".into(),
        },
        ToolSpecDto {
            name: "glob_search".into(),
            description: "Find files by glob pattern".into(),
        },
        ToolSpecDto {
            name: "content_search".into(),
            description: "Search file contents".into(),
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
