#!/usr/bin/env bash
# Download and extract bundled Python + Bun runtimes for macOS / Linux.
#
# Usage:
#   ./download_runtimes.sh <target_dir> <os> <arch>
#
# Arguments:
#   target_dir  — destination directory (e.g., build/.../runtimes)
#   os          — "macos" | "linux"
#   arch        — "aarch64" | "x86_64"
#
# Environment variables (optional overrides):
#   PYTHON_BUILD_TAG   — python-build-standalone release tag  (default: 20260303)
#   PYTHON_VERSION     — CPython version                       (default: 3.12.13)
#   BUN_VERSION        — Bun version tag                       (default: latest)
#
set -euo pipefail

TARGET_DIR="${1:?Usage: $0 <target_dir> <os> <arch>}"
TARGET_OS="${2:?Usage: $0 <target_dir> <os> <arch>}"
TARGET_ARCH="${3:?Usage: $0 <target_dir> <os> <arch>}"

PYTHON_BUILD_TAG="${PYTHON_BUILD_TAG:-20260303}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.13}"
BUN_VERSION="${BUN_VERSION:-latest}"

PYTHON_BASE_URL="https://github.com/astral-sh/python-build-standalone/releases/download/${PYTHON_BUILD_TAG}"
BUN_BASE_URL="https://github.com/oven-sh/bun/releases"

# ── Resolve platform triplets ────────────────────────────────

case "${TARGET_OS}" in
  macos)
    PYTHON_TRIPLE="${TARGET_ARCH}-apple-darwin"
    BUN_ARCH=$( [ "$TARGET_ARCH" = "aarch64" ] && echo "darwin-aarch64" || echo "darwin-x64" )
    ;;
  linux)
    PYTHON_TRIPLE="${TARGET_ARCH}-unknown-linux-gnu"
    BUN_ARCH=$( [ "$TARGET_ARCH" = "aarch64" ] && echo "linux-aarch64" || echo "linux-x64" )
    ;;
  *)
    echo "ERROR: unsupported OS '${TARGET_OS}'" >&2; exit 1
    ;;
esac

PYTHON_FILENAME="cpython-${PYTHON_VERSION}+${PYTHON_BUILD_TAG}-${PYTHON_TRIPLE}-install_only.tar.gz"
PYTHON_URL="${PYTHON_BASE_URL}/${PYTHON_FILENAME}"

if [ "$BUN_VERSION" = "latest" ]; then
  BUN_URL="${BUN_BASE_URL}/latest/download/bun-${BUN_ARCH}.zip"
else
  BUN_URL="${BUN_BASE_URL}/download/bun-v${BUN_VERSION}/bun-${BUN_ARCH}.zip"
fi

mkdir -p "$TARGET_DIR"

# ── Download & extract Python ─────────────────────────────────

echo "→ Downloading Python ${PYTHON_VERSION} (${PYTHON_TRIPLE}) ..."
TMPDIR_PY=$(mktemp -d)
curl -fSL --retry 3 "$PYTHON_URL" -o "${TMPDIR_PY}/python.tar.gz"

echo "→ Extracting Python to ${TARGET_DIR}/python ..."
mkdir -p "${TARGET_DIR}/python"
tar -xzf "${TMPDIR_PY}/python.tar.gz" -C "${TARGET_DIR}/python" --strip-components=1
rm -rf "$TMPDIR_PY"

# Sanity check
if [ "$TARGET_OS" = "macos" ] || [ "$TARGET_OS" = "linux" ]; then
  PYTHON_BIN="${TARGET_DIR}/python/bin/python3"
else
  PYTHON_BIN="${TARGET_DIR}/python/python3"
fi
if [ ! -f "$PYTHON_BIN" ]; then
  echo "ERROR: Python binary not found at ${PYTHON_BIN}" >&2
  ls -la "${TARGET_DIR}/python/" >&2
  exit 1
fi
echo "  ✓ Python: $($PYTHON_BIN --version 2>&1 || echo 'version check skipped')"

# ── Download & extract Bun ────────────────────────────────────

echo "→ Downloading Bun (${BUN_ARCH}) ..."
TMPDIR_BUN=$(mktemp -d)
curl -fSL --retry 3 "$BUN_URL" -o "${TMPDIR_BUN}/bun.zip"

echo "→ Extracting Bun to ${TARGET_DIR}/bun ..."
mkdir -p "${TARGET_DIR}/bun"
unzip -qo "${TMPDIR_BUN}/bun.zip" -d "${TMPDIR_BUN}/extract"
# The zip contains a directory like bun-darwin-aarch64/ with the binary inside
find "${TMPDIR_BUN}/extract" -name "bun" -type f -exec cp {} "${TARGET_DIR}/bun/bun" \;
chmod +x "${TARGET_DIR}/bun/bun"
rm -rf "$TMPDIR_BUN"

# Sanity check
BUN_BIN="${TARGET_DIR}/bun/bun"
if [ ! -f "$BUN_BIN" ]; then
  echo "ERROR: Bun binary not found at ${BUN_BIN}" >&2
  exit 1
fi
echo "  ✓ Bun: $($BUN_BIN --version 2>&1 || echo 'version check skipped')"

# ── Install agent-browser via Bun ─────────────────────────────
# Pre-install agent-browser (Playwright-based browser automation CLI) so that
# the application works out-of-the-box without requiring users to run npm/bun
# install manually. Playwright's own browser download is skipped — the app
# will auto-detect and use the system Chrome/Chromium/Edge at runtime.

echo "→ Installing agent-browser via bundled Bun ..."
AB_DIR="${TARGET_DIR}/agent-browser"
mkdir -p "$AB_DIR"

# Create a minimal package.json so Bun can install into this directory
cat > "${AB_DIR}/package.json" <<'PKGJSON'
{ "name": "deskclaw-agent-browser", "private": true }
PKGJSON

# Skip Playwright browser download — we use the system browser at runtime
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
PLAYWRIGHT_BROWSERS_PATH=0 \
  "$BUN_BIN" add --cwd "$AB_DIR" agent-browser 2>&1 | tail -5

# Create a platform-appropriate wrapper script that:
#   1. Uses the bundled Bun as the JS runtime
#   2. Sets PLAYWRIGHT env vars to use the system browser
#   3. Forwards all CLI args to the real agent-browser entry point
AB_ENTRY=$(find "${AB_DIR}/node_modules/agent-browser" -name "cli.js" -o -name "index.js" -o -name "agent-browser.js" 2>/dev/null | head -1)
if [ -z "$AB_ENTRY" ]; then
  # Fallback: look for the bin entry via node_modules/.bin
  AB_ENTRY=$(readlink -f "${AB_DIR}/node_modules/.bin/agent-browser" 2>/dev/null || true)
fi
if [ -z "$AB_ENTRY" ]; then
  echo "WARNING: Could not locate agent-browser entry point, browser automation may not work" >&2
else
  # Store relative path from wrapper to entry point
  AB_ENTRY_REL=$(python3 -c "import os.path; print(os.path.relpath('$AB_ENTRY', '$AB_DIR'))" 2>/dev/null || echo "$AB_ENTRY")

  cat > "${AB_DIR}/agent-browser" <<WRAPPER
#!/usr/bin/env bash
# Auto-generated wrapper — launches agent-browser with the bundled Bun runtime
# and auto-detected system browser. Do not edit manually.
SCRIPT_DIR="\$(cd "\$(dirname "\$0")" && pwd)"
RUNTIMES_DIR="\$(cd "\$SCRIPT_DIR/.." && pwd)"
BUN="\$RUNTIMES_DIR/bun/bun"

# Auto-detect system Chrome/Chromium for Playwright
if [ -z "\$PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH" ]; then
  for candidate in \\
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \\
    "/Applications/Chromium.app/Contents/MacOS/Chromium" \\
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \\
    "\$(command -v google-chrome-stable 2>/dev/null)" \\
    "\$(command -v google-chrome 2>/dev/null)" \\
    "\$(command -v chromium-browser 2>/dev/null)" \\
    "\$(command -v chromium 2>/dev/null)" \\
    "\$(command -v microsoft-edge-stable 2>/dev/null)" \\
  ; do
    if [ -n "\$candidate" ] && [ -x "\$candidate" ]; then
      export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="\$candidate"
      break
    fi
  done
fi

exec "\$BUN" "\$SCRIPT_DIR/${AB_ENTRY_REL}" "\$@"
WRAPPER
  chmod +x "${AB_DIR}/agent-browser"

  # Verify
  if "${AB_DIR}/agent-browser" --version >/dev/null 2>&1; then
    AB_VER=$("${AB_DIR}/agent-browser" --version 2>&1 || true)
    echo "  ✓ agent-browser: ${AB_VER}"
  else
    echo "  ✓ agent-browser: installed (version check skipped)"
  fi
fi

# ── Summary ───────────────────────────────────────────────────

echo ""
echo "Runtimes installed to ${TARGET_DIR}:"
du -sh "${TARGET_DIR}/python" "${TARGET_DIR}/bun" "${TARGET_DIR}/agent-browser" 2>/dev/null || true
echo "Done."
