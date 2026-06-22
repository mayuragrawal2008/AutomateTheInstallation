# Claude Code Starter Kit (macOS)

Sets up Claude Code, the Supermemory MCP server, and the optional caveman plugin.

## Files
- `setup-claude-code.command` - double-click this
- `install-claude-code-kit.sh` - the script it runs
- `README.md` - this file

## Requirements
- macOS (Apple Silicon or Intel)
- A Claude Pro/Max subscription or an Anthropic API key (no free tier)
- `sudo` is **not** required

## How to run

Because macOS quarantines downloaded scripts, do this once in Terminal first:

```bash
cd path/to/macos/starter-kit
xattr -dr com.apple.quarantine .   # clear the download quarantine
chmod +x setup-claude-code.command install-claude-code-kit.sh
```

Then either double-click `setup-claude-code.command`, or run:

```bash
bash install-claude-code-kit.sh
```

## After setup
1. Open a **new** Terminal window (so PATH updates).
2. Run `claude` and complete the one-time browser sign-in.
3. Inside Claude Code: `/context` (Supermemory), `/caveman` (token saver).

## Manual fallback
```bash
curl -fsSL https://claude.ai/install.sh | bash
claude mcp add supermemory --transport http https://mcp.supermemory.ai/mcp --scope user
npx -y claudepluginhub juliusbrussee/caveman --plugin caveman   # needs Node 18+
```
