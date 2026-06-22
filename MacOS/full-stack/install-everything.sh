#!/bin/bash
# ============================================================================
# Claude Code Full Stack Installer (macOS)
# ----------------------------------------------------------------------------
# AUTHOR: Mayur Agrawal
# LAST REVIEW: 22 June 2026 14:30
# ----------------------------------------------------------------------------
# Installs Claude Code, frontend skills, the caveman plugin, and MCP servers
# (supermemory, Supabase, 21st.dev Magic, TestSprite, Vercel) with no prompts
# where possible. Fully unattended only if matching secrets are exported.
#
# Run: double-click install-everything.command
#  or:  bash install-everything.sh
# No sudo required. Safe to re-run.
#
# NOTE: the skill installer here is the CORRECTED version - it prefers each
# repo's .claude/ variant, skips other IDEs' copies, and de-dupes by name.
# ============================================================================
set -u

# ---- CONFIG: secrets come from environment variables; unset = skip ---------
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-}"
SUPABASE_ACCESS_TOKEN="${SUPABASE_ACCESS_TOKEN:-}"
TWENTYFIRST_API_KEY="${TWENTYFIRST_API_KEY:-}"
TESTSPRITE_API_KEY="${TESTSPRITE_API_KEY:-}"
INSTALL_VERCEL_MCP="${INSTALL_VERCEL_MCP:-yes}"
INCLUDE_MEGA_SKILL_LIBRARY="${INCLUDE_MEGA_SKILL_LIBRARY:-no}"

SKILLS_ROOT="$HOME/.claude/skills"
CACHE="${TMPDIR:-/tmp}/cc-fullstack-cache"
mkdir -p "$CACHE"

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

mcp_exists() { # $1=claude $2=name
  "$1" mcp list 2>/dev/null | grep -Eiq "^[[:space:]]*$2[[:space:]:]"
}

add_remote_mcp() { # $1=claude $2=name $3=url ; rest = extra args (e.g. -H "Authorization: Bearer x")
  local c="$1" name="$2" url="$3"; shift 3
  if mcp_exists "$c" "$name"; then echo "  $name already registered - skipping."; return; fi
  if "$c" mcp add "$name" --transport http "$url" --scope user "$@"; then
    echo "  $name registered."
  else
    echo "  $name registration returned non-zero exit."
  fi
}

add_local_mcp() { # $1=claude $2=name $3=ENVPAIR(or empty) ; rest = command
  local c="$1" name="$2" envpair="$3"; shift 3
  if mcp_exists "$c" "$name"; then echo "  $name already registered - skipping."; return; fi
  if [ -n "$envpair" ]; then
    "$c" mcp add "$name" --scope user --env "$envpair" -- "$@" \
      && echo "  $name registered." || echo "  $name registration returned non-zero exit."
  else
    "$c" mcp add "$name" --scope user -- "$@" \
      && echo "  $name registered." || echo "  $name registration returned non-zero exit."
  fi
}

install_skill() { # $1=name $2=url
  local name="$1" url="$2" dest="$CACHE/$1"
  rm -rf "$dest"
  echo "  Cloning $name ..."
  if ! git clone --depth 1 "$url" "$dest" >/dev/null 2>&1; then
    echo "  Clone failed for $name (moved repo or blocked network) - skipping."
    return
  fi
  # Prefer the .claude variant if the repo ships per-IDE copies.
  local list
  list="$(find "$dest" -path '*/.claude/skills/*/SKILL.md' 2>/dev/null)"
  if [ -z "$list" ]; then
    list="$(find "$dest" -name SKILL.md \
      -not -path '*/.cursor/*'   -not -path '*/.gemini/*'  -not -path '*/.github/*' \
      -not -path '*/.codex/*'    -not -path '*/.qoder/*'   -not -path '*/.pi/*' \
      -not -path '*/.rovodev/*'  -not -path '*/.kiro/*'    -not -path '*/.trae/*' \
      -not -path '*/.trae-cn/*'  -not -path '*/.opencode/*' -not -path '*/.agents/*' \
      -not -path '*/.windsurf/*' -not -path '*/.vscode/*' 2>/dev/null)"
  fi
  if [ -z "$list" ]; then
    echo "  No SKILL.md in $name - not a drop-in skill. Skipping."
    return
  fi
  mkdir -p "$SKILLS_ROOT"
  local installed=" " sf srcdir target
  while IFS= read -r sf; do
    [ -n "$sf" ] || continue
    srcdir="$(dirname "$sf")"
    if [ "$srcdir" = "$dest" ]; then target="$name"; else target="$(basename "$srcdir")"; fi
    case "$installed" in *" $target "*) continue;; esac
    rm -rf "${SKILLS_ROOT:?}/$target"
    cp -R "$srcdir" "$SKILLS_ROOT/$target"
    installed="$installed$target "
    echo "  Installed skill: $target"
  done <<EOF
$list
EOF
}

# ----------------------------------------------------------------------------
section "Claude Code Full Stack Installer (macOS)"
echo "Installing the toolset from the UI/UX Resources doc. No sudo required."

# --- Step 1: Prerequisites --------------------------------------------------
section "Step 1 of 5 - Prerequisites (Git, Node.js)"
if command -v git >/dev/null 2>&1; then
  echo "Git: installed."
else
  echo "Git missing - triggering Xcode Command Line Tools (a dialog appears)."
  xcode-select --install 2>/dev/null || true
  echo "Finish that install, then re-run."
fi
GIT_OK=0; command -v git >/dev/null 2>&1 && GIT_OK=1

NM="$(node_major)"
if [ "${NM:-0}" -ge 18 ]; then
  echo "Node.js: v$NM detected."
else
  echo "Node.js 18+ not found (needed for caveman and the npx MCP servers)."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing Node via Homebrew ..."
    brew install node || true
  else
    echo "Homebrew not found - install Node from https://nodejs.org (or install Homebrew first)."
  fi
  NM="$(node_major)"
fi

# --- Step 2: Claude Code ----------------------------------------------------
section "Step 2 of 5 - Claude Code"
CLAUDE="$(resolve_claude)"
if [ -n "$CLAUDE" ]; then
  echo "Claude Code present at: $CLAUDE"
else
  echo "Installing via the official native installer ..."
  curl -fsSL https://claude.ai/install.sh | bash || echo "Native installer failed."
  CLAUDE="$(resolve_claude)"
  if [ -n "$CLAUDE" ]; then
    echo "Installed at: $CLAUDE"
  else
    echo "Install failed. Run by hand, then re-run: curl -fsSL https://claude.ai/install.sh | bash"
  fi
fi

if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "Anthropic API key supplied - enabling non-interactive auth (API billing)."
  PROFILE="$HOME/.zshrc"
  grep -q 'ANTHROPIC_API_KEY' "$PROFILE" 2>/dev/null \
    || printf '\nexport ANTHROPIC_API_KEY="%s"\n' "$ANTHROPIC_API_KEY" >> "$PROFILE"
  export ANTHROPIC_API_KEY
else
  echo "No API key - you will sign in once via browser when you first run claude."
fi

# --- Step 3: Skills ---------------------------------------------------------
section "Step 3 of 5 - Skills"
if [ "$GIT_OK" -eq 1 ]; then
  install_skill gsap                  https://github.com/greensock/gsap-skills.git
  install_skill frontend-design-audit https://github.com/mistyhx/frontend-design-audit.git
  install_skill seo-audit-skill       https://github.com/seo-skills/seo-audit-skill.git
  install_skill ai-website-cloner     https://github.com/JCodesMore/ai-website-cloner-template.git
  install_skill frontend-designer     https://github.com/emilkowalski/skill.git
  install_skill impeccable            https://github.com/pbakaus/impeccable.git
  install_skill taste-skill           https://github.com/Leonxlnx/taste-skill.git
  install_skill drawio-skill          https://github.com/Agents365-ai/drawio-skill.git
  install_skill ponytail              https://github.com/DietrichGebert/ponytail.git
  install_skill improve               https://github.com/shadcn/improve.git
  install_skill supermemory-skill     https://github.com/supermemoryai/claude-supermemory.git
  if [ "$INCLUDE_MEGA_SKILL_LIBRARY" = "yes" ]; then
    install_skill claude-skills-library https://github.com/alirezarezvani/claude-skills.git
  fi
  echo
  echo "Not installed as skills (handle manually if you want them):"
  echo "  - UI & UX Pro Max (uupm.cc): a website/product, not a git skill."
  echo "  - Handy (github.com/cjpais/Handy): a desktop speech-to-text app."
  echo "  - SkillSpector (github.com/NVIDIA/SkillSpector): a scanner you run, not a skill."
else
  echo "Git unavailable - skipping skills."
fi

# --- Step 4: caveman --------------------------------------------------------
section "Step 4 of 5 - caveman plugin"
if [ "${NM:-0}" -ge 18 ]; then
  echo "Installing caveman ..."
  npx -y claudepluginhub juliusbrussee/caveman --plugin caveman \
    || echo "caveman skipped (non-zero exit)."
else
  echo "Node.js not available - skipping caveman."
fi

# --- Step 5: MCP servers ----------------------------------------------------
section "Step 5 of 5 - MCP servers"
NEEDS_LOGIN=""
if [ -z "$CLAUDE" ]; then
  echo "Claude not on PATH - skipping MCP registration. Re-run after opening a new Terminal."
else
  add_remote_mcp "$CLAUDE" supermemory "https://mcp.supermemory.ai/mcp"
  NEEDS_LOGIN="$NEEDS_LOGIN supermemory"

  if [ -n "$SUPABASE_PROJECT_REF" ]; then
    SB_URL="https://mcp.supabase.com/mcp?project_ref=$SUPABASE_PROJECT_REF"
    if [ -n "$SUPABASE_ACCESS_TOKEN" ]; then
      add_remote_mcp "$CLAUDE" supabase "$SB_URL" -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
    else
      add_remote_mcp "$CLAUDE" supabase "$SB_URL"
      NEEDS_LOGIN="$NEEDS_LOGIN supabase"
    fi
  else
    echo "  Supabase: no project ref set - skipping."
  fi

  if [ -n "$TWENTYFIRST_API_KEY" ] && [ "${NM:-0}" -ge 18 ]; then
    add_local_mcp "$CLAUDE" magic "API_KEY=$TWENTYFIRST_API_KEY" npx -y @21st-dev/magic@latest
  else
    echo "  Magic: no API key (or no Node) - skipping."
  fi

  if [ -n "$TESTSPRITE_API_KEY" ] && [ "${NM:-0}" -ge 18 ]; then
    add_local_mcp "$CLAUDE" testsprite "API_KEY=$TESTSPRITE_API_KEY" npx -y @testsprite/testsprite-mcp@latest
  else
    echo "  TestSprite: no API key (or no Node) - skipping."
  fi

  if [ "$INSTALL_VERCEL_MCP" = "yes" ]; then
    add_remote_mcp "$CLAUDE" vercel "https://mcp.vercel.com"
    NEEDS_LOGIN="$NEEDS_LOGIN vercel"
  fi

  echo
  echo "  Stitch (Google Labs): set up manually from"
  echo "    https://stitch.withgoogle.com/docs/mcp/setup"
  echo "    (Google sign-in based; no headless option.)"
fi

# --- Summary ----------------------------------------------------------------
section "Setup complete"
echo "Next steps:"
echo "  1. Open a NEW Terminal window."
if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "  2. Run: claude   (no login needed - API key is set)."
else
  echo "  2. Run: claude   and complete the one-time browser sign-in."
fi
if [ -n "$NEEDS_LOGIN" ]; then
  echo
  echo "One-time browser sign-in still required the first time you use:$NEEDS_LOGIN"
  echo "Inside Claude Code, run /mcp to trigger each sign-in."
fi
echo
echo "Useful checks:"
echo "  claude doctor     - install health"
echo "  claude mcp list   - registered MCP servers and their status"
echo "  /context          - pull your Supermemory profile into a chat"
echo "  /caveman          - turn on token-saving mode"
echo
