//! Agent Workspace API — per-agent independent workspace management.
//!
//! Each "agent workspace" is a self-contained directory with its own identity
//! files (SOUL.md, AGENTS.md, etc.) and optional config overrides. When a
//! session is bound to an agent workspace, it uses that workspace's personality
//! and context instead of the global defaults.

use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::OnceLock;
use tokio::sync::Mutex as TokioMutex;

// ──────────────────────── DTOs ────────────────────────────

/// An agent workspace configuration exposed to Flutter UI
#[derive(Debug, Clone)]
pub struct AgentWorkspaceDto {
    /// Unique identifier for this agent workspace
    pub id: String,
    /// Display name (e.g. "Product Manager", "Flutter Dev")
    pub name: String,
    /// Short description of this agent's role
    pub description: String,
    /// Optional emoji/icon identifier
    pub avatar: String,
    /// Workspace directory path
    pub workspace_dir: String,
    /// Whether this workspace is active/enabled
    pub enabled: bool,
    /// Custom system prompt override (if any)
    pub system_prompt: String,
    /// Contents of SOUL.md
    pub soul_md: String,
    /// Contents of AGENTS.md
    pub agents_md: String,
    /// Contents of USER.md
    pub user_md: String,
    /// Contents of IDENTITY.md
    pub identity_md: String,
    /// Optional color tag (hex string like "#FF5722")
    pub color_tag: String,
    /// Created timestamp (epoch seconds)
    pub created_at: i64,
    /// Updated timestamp (epoch seconds)
    pub updated_at: i64,
}

/// Summary for listing agent workspaces in UI
#[derive(Debug, Clone)]
pub struct AgentWorkspaceSummary {
    pub id: String,
    pub name: String,
    pub description: String,
    pub avatar: String,
    pub enabled: bool,
    pub color_tag: String,
}

// ──────────────────── Persistence State ──────────────────────

#[frb(ignore)]
#[derive(Debug, Clone, Serialize, Deserialize)]
struct PersistedAgentWorkspace {
    id: String,
    name: String,
    description: String,
    avatar: String,
    enabled: bool,
    system_prompt: String,
    soul_md: String,
    agents_md: String,
    user_md: String,
    identity_md: String,
    color_tag: String,
    created_at: i64,
    updated_at: i64,
}

#[frb(ignore)]
#[derive(Debug, Default, Serialize, Deserialize)]
struct AgentWorkspaceStore {
    workspaces: Vec<PersistedAgentWorkspace>,
}

fn workspace_store() -> &'static TokioMutex<AgentWorkspaceStore> {
    static STORE: OnceLock<TokioMutex<AgentWorkspaceStore>> = OnceLock::new();
    STORE.get_or_init(|| TokioMutex::new(AgentWorkspaceStore::default()))
}

fn store_file_path() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_default()
        .join(".zeroclaw")
        .join("coraldesk_agent_workspaces.json")
}

fn agent_workspace_base_dir() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_default()
        .join(".zeroclaw")
        .join("agent_workspaces")
}

// ──────────────────── API Functions ──────────────────────────

/// Initialize agent workspace store — load from disk
pub async fn init_agent_workspace_store() -> String {
    let path = store_file_path();
    let store = if path.exists() {
        match tokio::fs::read_to_string(&path).await {
            Ok(content) => {
                serde_json::from_str::<AgentWorkspaceStore>(&content).unwrap_or_default()
            }
            Err(_) => AgentWorkspaceStore::default(),
        }
    } else {
        AgentWorkspaceStore::default()
    };

    // Ensure base directory exists
    let _ = tokio::fs::create_dir_all(agent_workspace_base_dir()).await;

    let count = store.workspaces.len();
    *workspace_store().lock().await = store;
    format!("loaded {} agent workspaces", count)
}

/// List all agent workspaces (summary only)
pub async fn list_agent_workspaces() -> Vec<AgentWorkspaceSummary> {
    let store = workspace_store().lock().await;
    store
        .workspaces
        .iter()
        .map(|w| AgentWorkspaceSummary {
            id: w.id.clone(),
            name: w.name.clone(),
            description: w.description.clone(),
            avatar: w.avatar.clone(),
            enabled: w.enabled,
            color_tag: w.color_tag.clone(),
        })
        .collect()
}

/// Get full details of a single agent workspace
pub async fn get_agent_workspace(workspace_id: String) -> Option<AgentWorkspaceDto> {
    let store = workspace_store().lock().await;
    store
        .workspaces
        .iter()
        .find(|w| w.id == workspace_id)
        .map(|w| {
            let ws_dir = agent_workspace_base_dir().join(&w.id);
            AgentWorkspaceDto {
                id: w.id.clone(),
                name: w.name.clone(),
                description: w.description.clone(),
                avatar: w.avatar.clone(),
                workspace_dir: ws_dir.to_string_lossy().to_string(),
                enabled: w.enabled,
                system_prompt: w.system_prompt.clone(),
                soul_md: w.soul_md.clone(),
                agents_md: w.agents_md.clone(),
                user_md: w.user_md.clone(),
                identity_md: w.identity_md.clone(),
                color_tag: w.color_tag.clone(),
                created_at: w.created_at,
                updated_at: w.updated_at,
            }
        })
}

/// Create or update an agent workspace
pub async fn upsert_agent_workspace(workspace: AgentWorkspaceDto) -> String {
    // Generate UUID if ID is empty (new workspace)
    let id = if workspace.id.trim().is_empty() {
        uuid::Uuid::new_v4().to_string()
    } else {
        workspace.id.trim().to_string()
    };
    if workspace.name.trim().is_empty() {
        return "error: workspace name must not be empty".into();
    }

    let now = chrono::Utc::now().timestamp();
    let mut store = workspace_store().lock().await;

    // Create workspace directory and write identity files
    let ws_dir = agent_workspace_base_dir().join(&id);
    if let Err(e) = std::fs::create_dir_all(&ws_dir) {
        return format!("error: failed to create workspace dir: {e}");
    }

    // Write identity files to workspace directory
    write_identity_file(&ws_dir, "SOUL.md", &workspace.soul_md);
    write_identity_file(&ws_dir, "AGENTS.md", &workspace.agents_md);
    write_identity_file(&ws_dir, "USER.md", &workspace.user_md);
    write_identity_file(&ws_dir, "IDENTITY.md", &workspace.identity_md);

    if let Some(existing) = store.workspaces.iter_mut().find(|w| w.id == id) {
        existing.name = workspace.name;
        existing.description = workspace.description;
        existing.avatar = workspace.avatar;
        existing.enabled = workspace.enabled;
        existing.system_prompt = workspace.system_prompt;
        existing.soul_md = workspace.soul_md;
        existing.agents_md = workspace.agents_md;
        existing.user_md = workspace.user_md;
        existing.identity_md = workspace.identity_md;
        existing.color_tag = workspace.color_tag;
        existing.updated_at = now;
    } else {
        store.workspaces.push(PersistedAgentWorkspace {
            id,
            name: workspace.name,
            description: workspace.description,
            avatar: workspace.avatar,
            enabled: workspace.enabled,
            system_prompt: workspace.system_prompt,
            soul_md: workspace.soul_md,
            agents_md: workspace.agents_md,
            user_md: workspace.user_md,
            identity_md: workspace.identity_md,
            color_tag: workspace.color_tag,
            created_at: now,
            updated_at: now,
        });
    }

    drop(store);
    persist_store().await
}

/// Delete an agent workspace
pub async fn delete_agent_workspace(workspace_id: String) -> String {
    let mut store = workspace_store().lock().await;
    store.workspaces.retain(|w| w.id != workspace_id);
    drop(store);

    // Optionally remove workspace directory
    let ws_dir = agent_workspace_base_dir().join(&workspace_id);
    if ws_dir.exists() {
        let _ = std::fs::remove_dir_all(&ws_dir);
    }

    persist_store().await
}

/// Get the workspace directory path for an agent workspace
pub async fn get_agent_workspace_dir(workspace_id: String) -> String {
    agent_workspace_base_dir()
        .join(&workspace_id)
        .to_string_lossy()
        .to_string()
}

/// Resolve agent workspace identity files into the agent config.
/// Called by `ensure_session_agent` when a session is bound to an agent workspace.
pub(crate) async fn resolve_workspace_config(
    config: &mut zeroclaw::Config,
    workspace_id: &str,
) -> Result<(), String> {
    let store = workspace_store().lock().await;
    let ws = store
        .workspaces
        .iter()
        .find(|w| w.id == workspace_id)
        .ok_or_else(|| format!("Agent workspace '{}' not found", workspace_id))?;

    if !ws.enabled {
        return Err(format!("Agent workspace '{}' is disabled", workspace_id));
    }

    // Set workspace directory to agent-specific directory
    let ws_dir = agent_workspace_base_dir().join(workspace_id);
    let _ = std::fs::create_dir_all(&ws_dir);

    // Write identity files to workspace directory
    write_identity_file(&ws_dir, "SOUL.md", &ws.soul_md);
    write_identity_file(&ws_dir, "AGENTS.md", &ws.agents_md);
    write_identity_file(&ws_dir, "USER.md", &ws.user_md);
    write_identity_file(&ws_dir, "IDENTITY.md", &ws.identity_md);

    // Override workspace dir
    config.workspace_dir = ws_dir;

    // If there's a custom system prompt, configure it
    // (the identity files already provide the main personality override)

    Ok(())
}

// ──────────────────── Session binding ────────────────────────

#[frb(ignore)]
static SESSION_AGENT_BINDINGS: OnceLock<TokioMutex<std::collections::HashMap<String, String>>> =
    OnceLock::new();

fn session_bindings() -> &'static TokioMutex<std::collections::HashMap<String, String>> {
    SESSION_AGENT_BINDINGS.get_or_init(|| TokioMutex::new(std::collections::HashMap::new()))
}

/// Bind a session to an agent workspace. The next time the session's agent
/// is created, it will use this workspace's identity files.
pub async fn bind_session_to_agent(session_id: String, workspace_id: String) -> String {
    let mut bindings = session_bindings().lock().await;
    bindings.insert(session_id, workspace_id);
    "ok".into()
}

/// Unbind a session from any agent workspace (revert to default).
pub async fn unbind_session_agent(session_id: String) -> String {
    let mut bindings = session_bindings().lock().await;
    bindings.remove(&session_id);
    "ok".into()
}

/// Get the agent workspace ID bound to a session, if any.
pub async fn get_session_agent_binding(session_id: String) -> Option<String> {
    let bindings = session_bindings().lock().await;
    bindings.get(&session_id).cloned()
}

/// Get the agent workspace ID for a session (used internally by agent_api).
pub(crate) async fn get_binding_for_session(session_id: &str) -> Option<String> {
    let bindings = session_bindings().lock().await;
    bindings.get(session_id).cloned()
}

// ──────────────────── Helpers ─────────────────────────────────

fn write_identity_file(dir: &std::path::Path, filename: &str, content: &str) {
    if !content.trim().is_empty() {
        let _ = std::fs::write(dir.join(filename), content);
    }
}

async fn persist_store() -> String {
    let store = workspace_store().lock().await;
    let path = store_file_path();
    if let Some(parent) = path.parent() {
        let _ = tokio::fs::create_dir_all(parent).await;
    }
    match serde_json::to_string_pretty(&*store) {
        Ok(json) => match tokio::fs::write(&path, json).await {
            Ok(()) => "ok".into(),
            Err(e) => format!("error: write failed: {e}"),
        },
        Err(e) => format!("error: serialize failed: {e}"),
    }
}
