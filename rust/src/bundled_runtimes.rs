//! Bundled runtime discovery and PATH injection.
//!
//! CoralDesk ships with embedded Python and Bun runtimes so that agents can
//! execute code without requiring the user to install interpreters manually.
//!
//! On startup, [`prepend_bundled_runtimes_to_path`] locates the `runtimes/`
//! directory relative to the running executable and prepends the interpreter
//! `bin/` directories to the process-level `PATH`. Because `ShellTool` inherits
//! `PATH` after `env_clear()`, all shell commands will discover the bundled
//! binaries automatically.
//!
//! ### Layout per platform
//!
//! | Platform | Python binary path | Bun binary path |
//! |----------|-------------------|-----------------|
//! | macOS | `…/Contents/Resources/runtimes/python/bin/python3` | `…/Contents/Resources/runtimes/bun/bun` |
//! | Linux | `<bundle>/runtimes/python/bin/python3` | `<bundle>/runtimes/bun/bun` |
//! | Windows | `<Release>/runtimes/python/python.exe` | `<Release>/runtimes/bun/bun.exe` |

use std::path::{Path, PathBuf};

/// Locate the `runtimes/` directory relative to the current executable and
/// prepend bundled interpreter paths to `PATH`.
///
/// Returns the list of directories that were prepended (for logging).
pub fn prepend_bundled_runtimes_to_path() -> Vec<PathBuf> {
    let mut prepended = Vec::new();

    let runtimes_dir = match find_runtimes_dir() {
        Some(dir) => dir,
        None => {
            tracing::debug!("No bundled runtimes directory found");
            return prepended;
        }
    };

    tracing::info!(runtimes_dir = %runtimes_dir.display(), "Found bundled runtimes directory");

    // Collect bin directories to prepend
    let mut bin_dirs: Vec<PathBuf> = Vec::new();

    // Python: bin/ on Unix, root on Windows
    let python_dir = runtimes_dir.join("python");
    if python_dir.is_dir() {
        let python_bin = if cfg!(target_os = "windows") {
            // On Windows, python.exe sits directly in python/
            python_dir.clone()
        } else {
            python_dir.join("bin")
        };
        if python_bin.is_dir() {
            tracing::info!(path = %python_bin.display(), "Bundled Python found");
            bin_dirs.push(python_bin);
        }
    }

    // Bun: binary sits directly in bun/
    let bun_dir = runtimes_dir.join("bun");
    if bun_dir.is_dir() {
        tracing::info!(path = %bun_dir.display(), "Bundled Bun found");
        bin_dirs.push(bun_dir);
    }

    if bin_dirs.is_empty() {
        tracing::debug!("No bundled runtime binaries discovered");
        return prepended;
    }

    // Read current PATH, prepend bundled dirs, and set it back
    let current_path = std::env::var_os("PATH").unwrap_or_default();
    let mut paths: Vec<PathBuf> = bin_dirs.iter().map(|p| p.to_path_buf()).collect();

    // Append existing PATH entries
    for existing in std::env::split_paths(&current_path) {
        // Skip duplicates
        if !paths.contains(&existing) {
            paths.push(existing);
        }
    }

    match std::env::join_paths(&paths) {
        Ok(new_path) => {
            std::env::set_var("PATH", &new_path);
            prepended = bin_dirs;
            tracing::info!(
                count = prepended.len(),
                "Prepended bundled runtimes to PATH"
            );
        }
        Err(e) => {
            tracing::error!(error = %e, "Failed to set PATH with bundled runtimes");
        }
    }

    prepended
}

/// Locate the `runtimes/` directory based on the current executable's location.
fn find_runtimes_dir() -> Option<PathBuf> {
    let exe = std::env::current_exe().ok()?;
    let exe_dir = exe.parent()?;

    // Try multiple candidate locations depending on platform and whether
    // we're running from a dev build or an installed package.
    let candidates = runtime_dir_candidates(exe_dir);

    for candidate in &candidates {
        if candidate.is_dir() {
            return Some(candidate.clone());
        }
    }

    tracing::debug!(
        exe_dir = %exe_dir.display(),
        candidates = ?candidates.iter().map(|p| p.display().to_string()).collect::<Vec<_>>(),
        "No runtimes directory found"
    );
    None
}

/// Return candidate paths for the `runtimes/` directory.
fn runtime_dir_candidates(exe_dir: &Path) -> Vec<PathBuf> {
    let mut candidates = Vec::new();

    #[cfg(target_os = "macos")]
    {
        // macOS app bundle: .app/Contents/MacOS/coraldesk → .app/Contents/Resources/runtimes
        if let Some(contents) = exe_dir.parent() {
            candidates.push(contents.join("Resources").join("runtimes"));
        }
        // Fallback: next to executable
        candidates.push(exe_dir.join("runtimes"));
    }

    #[cfg(target_os = "linux")]
    {
        // Linux bundle: bundle/coraldesk → bundle/runtimes
        candidates.push(exe_dir.join("runtimes"));
        // AppImage: AppDir/usr/bin/coraldesk → AppDir/usr/share/runtimes
        if let Some(usr_dir) = exe_dir.parent() {
            candidates.push(usr_dir.join("share").join("runtimes"));
        }
    }

    #[cfg(target_os = "windows")]
    {
        // Windows: Release/coraldesk.exe → Release/runtimes
        candidates.push(exe_dir.join("runtimes"));
    }

    // Generic fallback: Always check next to the executable
    let generic = exe_dir.join("runtimes");
    if !candidates.contains(&generic) {
        candidates.push(generic);
    }

    candidates
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_runtime_dir_candidates_not_empty() {
        let exe_dir = PathBuf::from("/tmp/fake_app/Contents/MacOS");
        let candidates = runtime_dir_candidates(&exe_dir);
        assert!(!candidates.is_empty());
    }

    #[test]
    fn test_prepend_preserves_existing_path() {
        // This test validates the PATH manipulation logic.
        let original = std::env::var("PATH").unwrap_or_default();
        // Calling with no actual runtimes dir should be a no-op
        let result = prepend_bundled_runtimes_to_path();
        // PATH should still contain original entries
        let after = std::env::var("PATH").unwrap_or_default();
        if result.is_empty() {
            assert_eq!(original, after);
        }
    }
}
