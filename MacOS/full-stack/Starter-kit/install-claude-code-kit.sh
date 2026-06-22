#!/bin/bash
# ============================================================================
# Claude Code Starter Kit Installer (macOS)
# ----------------------------------------------------------------------------
# AUTHOR: Mayur Agrawal
# LAST REVIEW: 22 June 2026 14:30
# ----------------------------------------------------------------------------
# Installs Claude Code (native installer), registers the Supermemory MCP
# server, and optionally installs the caveman plugin.
#
# Run:  double-click setup-claude-code.command
#   or in Terminal:  bash install-claude-code-kit.sh
# No sudo required. Safe to re-run.
# ============================================================================
set -u

line()    { printf '======================================================\n'; }
section() { printf '\n'; line; printf '%s\n' "$1"; line; }

resolve_claude() {
  export PATH="$HOME/.local/bin:$PATH"
  if command -v claude >/dev/null 2>&1; then command -v claude; return; fi
  [ -x "$HOME/.local/bin/claude" ] && { printf '%s\n' "$HOME/.local/bin/claude"; return; }
  printf '\n'
}

node_major() {
  command -v node >/dev/null 2>&1 || { echo 0; return; }
  node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1
}

section "Claude Code Starter Kit Installer (macOS)"
echo "Sets up Claude Code and a few extras. No sudo required."

# --- Step 1: Git ------------------------------------------------------------
section "Step 1 of 3 - Git"
if command -v git >/dev/null 2>&1; then
  echo "Git is already installed."
else
  echo "Git not found. Triggering Xcode Command Line Tools install (a dialog appears)."
  xcode-select --install 2>/dev/null || true
  echo "Finish that install if prompted, then re-run this script."
fi

# --- Step 2: Claude Code ----------------------------------------------------
section "Step 2 of 3 - Claude Code"
CLAUDE="$(resolve_claude)"
if [ -n "$CLAUDE" ]; then
  echo "Claude Code already present at: $CLAUDE"
else
  echo "Installing Claude Code via the official native installer ..."
  curl -fsSL https://claude.ai/install.sh | bash || echo "Native installer failed."
  CLAUDE="$(resolve_claude)"
  if [ -n "$CLAUDE" ]; then
    echo "Installed at: $CLAUDE"
  else
    echo "Claude Code could not be installed automatically. Run this, then re-run:"
    echo "  curl -fsSL https://claude.ai/install.sh | bash"
  fi
fi

# --- Step 3: Supermemory MCP + caveman --------------------------------------
section "Step 3 of 3 - Supermemory MCP and caveman"
SUPERMEMORY_URL="https://mcp.supermemory.ai/mcp"
if [ -n "$CLAUDE" ]; then
  echo "Registering Supermemory MCP (you sign in to your own account on first use) ..."
  "$CLAUDE" mcp add supermemory --transport http "$SUPERMEMORY_URL" --scope user \
    || echo "  (may already be registered)"
else
  echo "Claude not on PATH yet - skipping Supermemory."
fi
echo "Manual command if needed:"
echo "  claude mcp add supermemory --transport http $SUPERMEMORY_URL --scope user"
echo

NM="$(node_major)"
if [ "${NM:-0}" -ge 18 ]; then
  echo "Installing caveman plugin ..."
  npx -y claudepluginhub juliusbrussee/caveman --plugin caveman \
    || echo "caveman skipped (non-zero exit)."
else
  echo "Node.js 18+ not found - skipping caveman (optional)."
  echo "Install Node (e.g. 'brew install node'), then run:"
  echo "  npx -y claudepluginhub juliusbrussee/caveman --plugin caveman"
fi

# --- Done -------------------------------------------------------------------
section "Setup complete"
echo "Next steps:"
echo "  1. Open a NEW Terminal window (so PATH updates)."
echo "  2. Run:    claude     and complete the one-time browser sign-in."
echo "  3. Inside Claude Code: /context (Supermemory), /caveman (token saver)."
echo
