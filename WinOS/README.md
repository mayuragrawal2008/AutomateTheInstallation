# Claude Code Full Stack Installer

Installs the toolset from the **web / UI & UX Resources** doc onto a Windows machine with as little interaction as possible: Claude Code, the frontend skills, the caveman plugin, and the MCP servers (supermemory, Supabase, 21st.dev Magic, TestSprite, Vercel).

## Files

| File | Purpose |
|------|---------|
| `Install-Everything.cmd` | **Double-click this.** |
| `Install-Everything.ps1` | The setup script the `.cmd` runs. |
| `README-Install-Everything.md` | This file. |

Keep all three in the same folder.

## Is it 100% unattended?

**Not out of the box — and that's a vendor limitation, not a script one.** Some services require a one-time browser login (OAuth) that no script can click for you. It *becomes* fully unattended only when you supply every credential in advance.

| Piece | Hands-off? | Requirement |
|------|------------|-------------|
| Git, Node.js, Claude Code, skills, caveman | Yes | Nothing |
| Claude Code sign-in | Only with `ANTHROPIC_API_KEY` | Otherwise one browser login (Pro/Max) |
| Magic, TestSprite | Only with an API key | Key as env var |
| Supabase | Only with a PAT | Otherwise OAuth on first use |
| Supermemory, Vercel, Stitch | No | OAuth-only; one click each on first use |

With all keys supplied you're at roughly 95%. The supermemory / Vercel / Stitch first-connect logins are the irreducible remainder.

## Supplying credentials (optional, for maximum automation)

The script reads secrets from environment variables so they stay out of the file. Set any of these **before** running (PowerShell, current user):

```powershell
setx ANTHROPIC_API_KEY     "sk-ant-..."     # makes 'claude' non-interactive (API billing)
setx SUPABASE_PROJECT_REF  "abcd1234"
setx SUPABASE_ACCESS_TOKEN "sbp_..."        # headless Supabase
setx TWENTYFIRST_API_KEY   "..."            # 21st.dev Magic
setx TESTSPRITE_API_KEY    "..."
```

Open a **new** terminal after `setx` so the values are visible, then run the installer. Anything left unset is simply skipped or falls back to a browser login.

## How to run

1. Keep the `.cmd` and `.ps1` together.
2. Double-click `Install-Everything.cmd`.
3. Approve the winget UAC prompt if it appears (for Git/Node).
4. Wait for **"Setup complete"**.

It is safe to re-run; installed items and already-registered MCP servers are skipped.

## After setup

1. Close the window, open a **new** PowerShell window.
2. Run `claude` (and sign in once, unless you set `ANTHROPIC_API_KEY`).
3. Inside Claude Code, run `/mcp` to finish the one-time sign-ins for supermemory and Vercel.

Checks: `claude doctor`, `claude mcp list`, `/context`, `/caveman`.

## What goes where

- **Skills** are cloned into `%USERPROFILE%\.claude\skills\`. The script clones each repo, finds any `SKILL.md`, and copies that folder in — so nested skills land correctly. Repos with no `SKILL.md` (or that have moved) are skipped and left in the temp cache.
- **MCP servers** are registered at **user scope** (`claude mcp add ... --scope user`), so they're available in every project.

## Notes and caveats

- **The 338+ skill library** (`alirezarezvani/claude-skills`) is **off by default** — it would dump hundreds of skills and bloat Claude Code's context. Set `IncludeMegaSkillLibrary = $true` in the script's CONFIG block to include it.
- **Not installed as skills:** UI & UX Pro Max (a website/product), Handy (a desktop app), SkillSpector (a scanner). These are listed at the end of the run for manual handling.
- **Stitch** (Google Labs) is Google-sign-in based with no stable headless endpoint, so it's left as a manual step with a link.
- **Secrets in plaintext:** prefer the `setx` env-var route above over hard-coding keys in the script.
- Some skill repos are third-party and may move or disappear; failed clones are skipped without stopping the run. Run NVIDIA's SkillSpector against `~/.claude/skills` if you want a security pass before trusting them.
