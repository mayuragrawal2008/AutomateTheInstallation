# Claude Code Full Stack (macOS)

Installs Claude Code, the frontend skills, the caveman plugin, and the MCP servers (supermemory, Supabase, 21st.dev Magic, TestSprite, Vercel) with as little interaction as possible.

## Files
- `install-everything.command` - double-click this
- `install-everything.sh` - the script it runs
- `README.md` - this file

## Requirements
- macOS (Apple Silicon or Intel)
- A Claude Pro/Max subscription or an Anthropic API key
- Homebrew (only needed to auto-install Node.js; otherwise install Node yourself)
- `sudo` is **not** required

## How to run

Clear the download quarantine and set execute bits once:

```bash
cd path/to/macos/full-stack
xattr -dr com.apple.quarantine .
chmod +x install-everything.command install-everything.sh
```

Then double-click `install-everything.command`, or:

```bash
bash install-everything.sh
```

## Maximum automation (optional)

Export any of these **before** running so the matching pieces install with no prompts:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."      # makes 'claude' non-interactive (API billing)
export SUPABASE_PROJECT_REF="abcd1234"
export SUPABASE_ACCESS_TOKEN="sbp_..."     # headless Supabase
export TWENTYFIRST_API_KEY="..."           # 21st.dev Magic
export TESTSPRITE_API_KEY="..."
```

Anything left unset is skipped or falls back to a browser login. Toggle behavior with `INSTALL_VERCEL_MCP=no` or `INCLUDE_MEGA_SKILL_LIBRARY=yes`.

## Is it 100% unattended?

Only with all credentials supplied. supermemory, Vercel, and Stitch are OAuth-only and need a single browser sign-in on first use - no script can click that. With keys set you reach ~95%; finish the rest with `/mcp` inside Claude Code.

## Skill install behavior (the fixed version)

This script clones each skill repo, and when a repo ships the same skill packaged for many IDEs (`.claude/`, `.cursor/`, `.gemini/`, ...), it installs **only the `.claude/` variant** and de-dupes by name. Repos with no `SKILL.md` (or that have moved) are skipped. Skills land in `~/.claude/skills/`.

The 338+ skill library is off by default; set `INCLUDE_MEGA_SKILL_LIBRARY=yes` to include it.

## After setup
1. Open a **new** Terminal window.
2. Run `claude` (sign in once unless `ANTHROPIC_API_KEY` is set).
3. Run `/mcp` inside Claude Code to finish the supermemory / Vercel sign-ins.

Checks: `claude doctor`, `claude mcp list`, `/context`, `/caveman`.
