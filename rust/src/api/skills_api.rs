use std::path::PathBuf;

// ──────────────────────── DTOs ────────────────────────────

/// A skill loaded from the skills directory
#[derive(Debug, Clone)]
pub struct SkillDto {
    pub name: String,
    pub description: String,
    pub version: String,
    pub author: String,
    pub tags: Vec<String>,
    pub tools: Vec<SkillToolDto>,
    pub prompts: Vec<String>,
    pub source: String, // "local" or "community"
}

/// A tool defined within a skill
#[derive(Debug, Clone)]
pub struct SkillToolDto {
    pub name: String,
    pub description: String,
    pub kind: String, // "shell", "http", "script"
}

/// Skills configuration overview
#[derive(Debug, Clone)]
pub struct SkillsConfigDto {
    pub open_skills_enabled: bool,
    pub prompt_injection_mode: String,
    pub skills_dir: String,
    pub local_skills_count: u32,
    pub community_skills_count: u32,
}

// ──────────────────── API Functions ──────────────────────────

/// Get skills configuration from zeroclaw config
pub async fn get_skills_config() -> SkillsConfigDto {
    let state = super::agent_api::runtime_state().lock().await;
    if let Some(config) = &state.config {
        let skills_dir = config
            .workspace_dir
            .join("skills")
            .to_string_lossy()
            .to_string();

        // Count local skills
        let local_count = count_skills_in_dir(&config.workspace_dir.join("skills"));
        let community_count = if config.skills.open_skills_enabled {
            let open_dir = config
                .skills
                .open_skills_dir
                .as_deref()
                .map(PathBuf::from)
                .unwrap_or_else(|| {
                    dirs::home_dir()
                        .unwrap_or_default()
                        .join(".zeroclaw")
                        .join("open-skills")
                });
            count_skills_in_dir(&open_dir)
        } else {
            0
        };

        let mode = match config.skills.prompt_injection_mode {
            zeroclaw::config::SkillsPromptInjectionMode::Compact => "compact",
            _ => "full",
        };

        SkillsConfigDto {
            open_skills_enabled: config.skills.open_skills_enabled,
            prompt_injection_mode: mode.into(),
            skills_dir,
            local_skills_count: local_count,
            community_skills_count: community_count,
        }
    } else {
        SkillsConfigDto {
            open_skills_enabled: false,
            prompt_injection_mode: "full".into(),
            skills_dir: String::new(),
            local_skills_count: 0,
            community_skills_count: 0,
        }
    }
}

/// List all available skills (local + community if enabled)
pub async fn list_skills() -> Vec<SkillDto> {
    let state = super::agent_api::runtime_state().lock().await;
    let mut skills = Vec::new();

    if let Some(config) = &state.config {
        // Load local skills
        let local_dir = config.workspace_dir.join("skills");
        load_skills_from_dir(&local_dir, "local", &mut skills);

        // Load community skills if enabled
        if config.skills.open_skills_enabled {
            let open_dir = config
                .skills
                .open_skills_dir
                .as_deref()
                .map(PathBuf::from)
                .unwrap_or_else(|| {
                    dirs::home_dir()
                        .unwrap_or_default()
                        .join(".zeroclaw")
                        .join("open-skills")
                });
            load_skills_from_dir(&open_dir, "community", &mut skills);
        }
    }

    skills
}

/// Toggle the open skills feature on/off
pub async fn toggle_open_skills(enabled: bool) -> String {
    let mut state = super::agent_api::runtime_state().lock().await;
    let config = match state.config.as_mut() {
        Some(c) => c,
        None => return "error: not initialized".into(),
    };

    config.skills.open_skills_enabled = enabled;
    // Invalidate agent to pick up change
    state.agent = None;

    // Persist to disk
    drop(state);
    super::agent_api::save_config_to_disk().await
}

/// Update prompt injection mode ("full" or "compact")
pub async fn update_prompt_injection_mode(mode: String) -> String {
    let mut state = super::agent_api::runtime_state().lock().await;
    let config = match state.config.as_mut() {
        Some(c) => c,
        None => return "error: not initialized".into(),
    };

    config.skills.prompt_injection_mode = match mode.as_str() {
        "compact" => zeroclaw::config::SkillsPromptInjectionMode::Compact,
        _ => zeroclaw::config::SkillsPromptInjectionMode::Full,
    };
    state.agent = None;

    drop(state);
    super::agent_api::save_config_to_disk().await
}

// ──────────────────── Helpers ─────────────────────────────────

fn count_skills_in_dir(dir: &std::path::Path) -> u32 {
    if !dir.exists() {
        return 0;
    }
    std::fs::read_dir(dir)
        .map(|entries| {
            entries
                .filter_map(|e| e.ok())
                .filter(|e| e.path().is_dir())
                .filter(|e| {
                    let p = e.path();
                    p.join("SKILL.toml").exists() || p.join("SKILL.md").exists()
                })
                .count() as u32
        })
        .unwrap_or(0)
}

fn load_skills_from_dir(dir: &std::path::Path, source: &str, skills: &mut Vec<SkillDto>) {
    if !dir.exists() {
        return;
    }

    let entries = match std::fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };

    for entry in entries.filter_map(|e| e.ok()) {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }

        let skill_toml = path.join("SKILL.toml");
        let skill_md = path.join("SKILL.md");

        if skill_toml.exists() {
            if let Some(skill) = parse_skill_toml(&skill_toml, source) {
                skills.push(skill);
            }
        } else if skill_md.exists() {
            if let Some(skill) = parse_skill_md(&skill_md, &path, source) {
                skills.push(skill);
            }
        }
    }
}

fn parse_skill_toml(path: &std::path::Path, source: &str) -> Option<SkillDto> {
    let content = std::fs::read_to_string(path).ok()?;
    let table: toml::Table = content.parse().ok()?;

    let skill_section = table.get("skill")?.as_table()?;

    let name = skill_section
        .get("name")
        .and_then(|v| v.as_str())
        .unwrap_or("unknown")
        .to_string();
    let description = skill_section
        .get("description")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let version = skill_section
        .get("version")
        .and_then(|v| v.as_str())
        .unwrap_or("0.1.0")
        .to_string();
    let author = skill_section
        .get("author")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let tags = skill_section
        .get("tags")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();

    // Parse tools
    let tools = table
        .get("tools")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|item| {
                    let t = item.as_table()?;
                    Some(SkillToolDto {
                        name: t.get("name")?.as_str()?.to_string(),
                        description: t
                            .get("description")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string(),
                        kind: t
                            .get("kind")
                            .and_then(|v| v.as_str())
                            .unwrap_or("shell")
                            .to_string(),
                    })
                })
                .collect()
        })
        .unwrap_or_default();

    // Parse prompts
    let prompts = skill_section
        .get("prompts")
        .and_then(|v| v.as_array())
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();

    Some(SkillDto {
        name,
        description,
        version,
        author,
        tags,
        tools,
        prompts,
        source: source.to_string(),
    })
}

fn parse_skill_md(path: &std::path::Path, dir: &std::path::Path, source: &str) -> Option<SkillDto> {
    let content = std::fs::read_to_string(path).ok()?;
    let name = dir
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("unknown")
        .to_string();

    // Extract description from first paragraph
    let description = content
        .lines()
        .find(|line| !line.starts_with('#') && !line.trim().is_empty())
        .unwrap_or("")
        .to_string();

    Some(SkillDto {
        name,
        description,
        version: "0.1.0".into(),
        author: String::new(),
        tags: vec![],
        tools: vec![],
        prompts: content
            .lines()
            .filter(|line| !line.starts_with('#') && !line.trim().is_empty())
            .map(|s| s.to_string())
            .collect(),
        source: source.to_string(),
    })
}
