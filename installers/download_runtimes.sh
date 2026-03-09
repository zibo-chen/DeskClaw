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

# ── Summary ───────────────────────────────────────────────────

echo ""
echo "Runtimes installed to ${TARGET_DIR}:"
du -sh "${TARGET_DIR}/python" "${TARGET_DIR}/bun" 2>/dev/null || true
echo "Done."
