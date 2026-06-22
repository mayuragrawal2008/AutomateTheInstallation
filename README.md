# AutomateTheInstallation

Hands-off installers for a **Claude Code** environment on **Windows and macOS** — Claude Code itself, frontend skills, the caveman plugin, and a set of MCP servers (supermemory, Supabase, 21st.dev Magic, TestSprite, Vercel).

Built from the "web / UI & UX Resources" reference doc.

## Layout

```
windows/
  starter-kit/   Setup-ClaudeCode.cmd      + Install-ClaudeCodeKit.ps1
  full-stack/    Install-Everything.cmd    + Install-Everything.ps1
macos/
  starter-kit/   setup-claude-code.command + install-claude-code-kit.sh
  full-stack/    install-everything.command+ install-everything.sh
```

- **starter-kit** = Claude Code + Supermemory MCP + optional caveman. Smallest footprint, no API keys needed.
- **full-stack** = the above plus the frontend skills and the five MCP servers.

Each folder has its own `README.md` with platform-specific steps.

## Quick start

**Windows:** double-click the `.cmd` in the kit you want. (A `.cmd` launcher is used because a bare `.ps1` opens in Notepad and PowerShell blocks unsigned scripts; the launcher runs it with an execution-policy bypass for that one run.)

**macOS:** clear the download quarantine and run the `.command` (or the `.sh`):
```bash
cd macos/full-stack
xattr -dr com.apple.quarantine .
chmod +x install-everything.command install-everything.sh
./install-everything.command   # or: bash install-everything.sh
```

## Requirements

- Windows 10/11 (64-bit) or macOS (Apple Silicon / Intel)
- Internet access
- A Claude Pro/Max subscription or an Anthropic API key (Claude Code has no free tier)
- Admin / `sudo` is **not** required

## Is it 100% unattended?

Only if every credential is supplied in advance (as environment variables). A few services — supermemory, Vercel, Stitch — are OAuth-only and need a single browser sign-in the first time you use them; no script can click that. With keys set you reach ~95%; finish the rest with `/mcp` inside Claude Code.

## Platform differences

| | Windows | macOS |
|---|---|---|
| Launcher | `.cmd` (double-click) | `.command` (double-click after `chmod +x`) |
| Logic | PowerShell `.ps1` | bash `.sh` |
| Prereqs installer | winget | Homebrew |
| Claude Code | native `install.ps1` | native `install.sh` |
| Gatekeeper analog | SmartScreen | quarantine (`xattr -dr`) |

## Known issue (Windows full-stack v1)

The **Windows** `full-stack` skill installer copies every `SKILL.md` it finds, so repos that ship the same skill for many IDEs (`.claude/`, `.cursor/`, ...) collide and the wrong variant can win; plugin repos (impeccable, ponytail, caveman) should go through `claude plugin marketplace add` instead of being cloned.

The **macOS** `full-stack` script **already includes the fix** (it prefers the `.claude/` variant, skips other IDEs' copies, and de-dupes by name). A matching Windows v2 is planned so both platforms behave identically.

Clone failures mid-run are usually a network/proxy throttle (common on managed corporate networks), not bad URLs — re-run to retry.

## Security note

These scripts install third-party skills and connect MCP servers that send context to external services. On a managed/corporate device, check this against your IT policy first, and consider scanning `~/.claude/skills` (e.g. with NVIDIA's SkillSpector) before relying on anything.

## License

MIT — see `LICENSE`.
