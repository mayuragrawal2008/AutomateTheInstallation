# Claude Code Starter Kit

A one-step setup for **Claude Code** on Windows. Double-click one file and it installs Claude Code, wires up persistent memory (Supermemory), and adds the optional token-saving **caveman** plugin.

## What's in this kit

| File | Purpose |
|------|---------|
| `Setup-ClaudeCode.cmd` | **Double-click this to run everything.** |
| `Install-ClaudeCodeKit.ps1` | The actual setup script (the `.cmd` calls it). |
| `README.md` | This file. |

Keep all three files in the same folder.

## What it installs

1. **Claude Code** — Anthropic's official **native installer** (`https://claude.ai/install.ps1`). This is the recommended method and needs no Node.js.
2. **Supermemory MCP** — persistent memory across chats. Registered with `claude mcp add`; each person who runs this **signs into their own Supermemory account**, so memories are never shared between users.
3. **caveman plugin** *(optional)* — cuts Claude Code's response tokens by roughly 75% while keeping technical accuracy. Needs Node.js 18+, which the script tries to install via `winget` if it's missing. The kit works fine without it.

It also checks for **Git for Windows** (recommended so Claude Code can use its Bash tool) and installs it via `winget` if absent.

## Requirements

- Windows 10 or 11 (64-bit)
- An internet connection
- A **Claude Pro or Max subscription**, or an Anthropic API key — Claude Code has no free tier
- Administrator rights are **not** needed (and you should not run Claude Code as Administrator)

## How to run

1. Make sure `Setup-ClaudeCode.cmd` and `Install-ClaudeCodeKit.ps1` are in the same folder.
2. **Double-click `Setup-ClaudeCode.cmd`.**
3. If Windows SmartScreen warns about an unrecognized app, click **More info → Run anyway** (it is your own script).
4. Wait for the **"Setup complete"** banner.

> Why the `.cmd`? Double-clicking a `.ps1` opens it in Notepad instead of running it, and PowerShell blocks unsigned scripts by default. The `.cmd` launches the script correctly with an execution-policy bypass for that one run only.
>
> Prefer PowerShell directly? Right-click `Install-ClaudeCodeKit.ps1` → **Run with PowerShell**.

## After setup

1. **Close the window and open a new PowerShell window** so the updated PATH is loaded.
2. Run:
   ```
   claude
   ```
3. Complete the browser sign-in when prompted.

Inside Claude Code:
- `/context` — pulls your Supermemory profile into the current chat
- `/caveman` — switches on token-saving mode (say `normal mode` to turn it off)
- `claude doctor` — checks install health any time

## If something doesn't install

Run these by hand in a **new** terminal:

```
# Claude Code (native installer)
irm https://claude.ai/install.ps1 | iex

# Supermemory MCP
claude mcp add supermemory --transport http https://mcp.supermemory.ai/mcp --scope user

# caveman plugin (needs Node.js 18+)
npx -y claudepluginhub juliusbrussee/caveman --plugin caveman
```

Useful checks:
```
claude doctor        # diagnose the install
claude mcp list      # confirm Supermemory is registered
```

## Notes

- **Safe to re-run.** The script skips anything already installed.
- **Supermemory is per-user.** Each person authenticates their own account on first connect.
- **caveman is third-party** (`github.com/JuliusBrussee/caveman`). It is optional; skip it with no impact on Claude Code itself.
