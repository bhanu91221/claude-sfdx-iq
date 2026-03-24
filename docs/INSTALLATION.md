# Installation Guide

## Prerequisites

Before installing claude-sfdx-iq, ensure you have the following:

| Requirement | Minimum Version | Check Command |
|-------------|----------------|---------------|
| Node.js | 18+ | `node --version` |
| Salesforce CLI (sf) | 2.x | `sf --version` |
| Claude Code | Latest | `claude --version` |
| Git | Any | `git --version` |

You also need an authenticated Salesforce org. Run `sf org list` to confirm at least one org is connected.

## Installation

You can install this plugin two ways -- pick whichever you are most comfortable with.

### Directly from Your Terminal

Open a terminal or command prompt and run these three commands:

**Step 1 -- Add the marketplace:**
```
claude plugin marketplace add bhanu91221/claude-sfdx-iq
```

**Step 2 -- Install the plugin:**
```
claude plugin install claude-sfdx-iq@claude-sfdx-iq
```

**Step 3 -- Enable it:**
```
claude plugin enable claude-sfdx-iq
```

### Inside Claude Code

If you are already working inside Claude Code (in VS Code, the Desktop app, or the CLI), type these commands directly:

**Step 1 -- Add the marketplace:**
```
/plugin marketplace add bhanu91221/claude-sfdx-iq
```

**Step 2 -- Install the plugin:**
```
/plugin install claude-sfdx-iq --scope user
```

**Step 3 -- Enable it:**
```
/plugin enable claude-sfdx-iq
```

### Installation Scopes

When installing from inside Claude Code, you can choose where the plugin is available:

| Scope | What it means |
|-------|---------------|
| **user** | Available in all Claude Code sessions for your user account -- stored in your global config (default) |
| **local** | Active only in the current project directory -- stored in `.claude/` but not committed to source control |
| **project** | Shared with your team -- stored in `.claude/settings.json` and committed to the repo so everyone gets the plugin |

## Setting Up Rules for Your SFDX Project

The plugin installs agents, skills, and commands **globally**, but **rules must be copied per SFDX project**. Rules are loaded dynamically -- only 5-8 rules per task instead of all 44, keeping Claude fast and focused.

There are three ways to get rules into your project:

### Option A -- Using npx (recommended)

From your SFDX project root:

```bash
npx claude-sfdx-iq setup-project
```

This pulls the latest rules and config templates directly from npm -- no git clone needed.

### Option B -- Using the slash command

If npm is blocked (corporate VPN), open Claude Code in your SFDX project and run:

```
/setup-project
```

### Option C -- Manual copy from the GitHub repo

Clone the repo and copy files yourself:

```bash
git clone https://github.com/bhanu91221/claude-sfdx-iq.git
cd /path/to/your/sfdx-project
mkdir -p .claude

# Copy rules
cp -r /path/to/claude-sfdx-iq/rules ./.claude/rules

# Copy configuration templates
cp /path/to/claude-sfdx-iq/.claude-project-template/settings.json ./.claude/settings.local.json
cp /path/to/claude-sfdx-iq/.claude-project-template/CLAUDE.md ./.claude/CLAUDE.md
```

**What gets copied to your project:**

| What | Destination | Purpose |
|------|-------------|---------|
| 44 rules | `.claude/rules/` | Domain guidelines, loaded on demand |
| `settings.local.json` | `.claude/settings.local.json` | Plugin configuration |
| `CLAUDE.md` | `.claude/CLAUDE.md` | Project-level Claude instructions |

## How It Works

The plugin has two layers -- global components installed once, and per-project rules copied into each Salesforce project:

```
Global (installed once via marketplace)
Location: ~/.claude/plugins/claude-sfdx-iq/
  Agents (14)     -- Domain specialists
  Skills (36)     -- Knowledge modules
  Commands (53)   -- Slash commands
  Hooks (16)      -- Automated quality checks
                +
Per Project (run setup-project once per repo)
Location: /your-sfdx-project/.claude/
  Rules (44)              -- Loaded dynamically
  settings.local.json     -- Plugin configuration
  CLAUDE.md               -- Project documentation
```

**Key benefits:**
- Commands are available globally (work in any SFDX project)
- Rules only load in SFDX projects (no token waste elsewhere)
- Dynamic rule loading (5-8 rules per task instead of all 44)

## Verify the Installation

Open your SFDX project in Claude Code and run:

```
/csiq-help
```

You should see the full list of available commands. Try:

```
/status    -- Check plugin and org status
/doctor    -- Diagnose environment issues
/list      -- Show installed agents, skills, commands
```

## CLI Tools Reference

All CLI tools are available both from the terminal (via `npx`) and as slash commands inside Claude Code:

| CLI Command | Slash Command | Description |
|---|---|---|
| `npx claude-sfdx-iq setup-project` | `/setup-project` | Copy rules + config to SFDX project |
| `npx claude-sfdx-iq help` | `/csiq-help` | Show available commands |
| `npx claude-sfdx-iq status` | `/status` | Plugin status and component counts |
| `npx claude-sfdx-iq doctor` | `/doctor` | Diagnose environment |
| `npx claude-sfdx-iq repair` | `/repair` | Check and repair plugin integrity |
| `npx claude-sfdx-iq list` | `/list` | List installed components |
| `npx claude-sfdx-iq tokens` | `/tokens` | Show token budget |
| `npx claude-sfdx-iq install` | `/install` | Install from profile/manifest |
| `npx claude-sfdx-iq pick` | `/pick` | Interactive component picker |
| `npx claude-sfdx-iq refresh` | `/refresh` | Regenerate project CLAUDE.md |

> **Corporate VPN / blocked npm?** All CLI tools are also available as slash commands -- no npm required.

## Configuration

### Selecting a manifest

Manifests control which components (agents, skills, commands, hooks, rules) are active. Choose one that fits your role:

| Manifest | Description |
|----------|-------------|
| `default` | All components enabled (recommended for full-stack SF devs) |
| `minimal` | Core commands only: deploy, retrieve, test |
| `apex-only` | Apex agents, skills, and rules; no LWC or Flow components |
| `lwc-only` | LWC agents, skills, and rules; no Apex or Flow components |
| `admin` | Flow, metadata, and org-health focused; no code review agents |

To switch manifests, update your project's `.claude/settings.json`:

```json
{
  "plugins": {
    "claude-sfdx-iq": {
      "manifest": "apex-only"
    }
  }
}
```

### Customizing rules

Rules in `rules/` are loaded automatically based on file type. To disable a specific rule file, add it to the `disabledRules` array in your settings.

## Environment Setup

### JWT authentication for CI/CD

For headless CI environments, configure JWT-based auth:

1. Create a connected app in Salesforce with a digital certificate.
2. Export the private key as `server.key`.
3. Authenticate:

```bash
sf org login jwt \
  --client-id <CONSUMER_KEY> \
  --jwt-key-file server.key \
  --username <USERNAME> \
  --instance-url https://login.salesforce.com \
  --set-default
```

### DevHub setup

Enable Dev Hub in your production org, then authenticate:

```bash
sf org login web --set-default-dev-hub --alias DevHub
```

### Scratch org pool

Create scratch orgs for development:

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias my-scratch \
  --set-default \
  --duration-days 7
```

## Troubleshooting

### `sf: command not found`

The Salesforce CLI is not installed or not on your PATH. Install it from <https://developer.salesforce.com/tools/salesforcecli> and restart your terminal.

### `ERROR: auth expired`

Your org session has expired. Re-authenticate:

```bash
sf org login web --alias <your-org-alias>
```

### Plugin not loading

1. Confirm the plugin path is correct: `claude plugin list`
2. Ensure `package.json` and `.claude-plugin/plugin.json` exist in the plugin root.
3. Run the doctor script to diagnose issues:

```bash
npx claude-sfdx-iq doctor
```

### "Not an SFDX project" error

Make sure you are in a directory that contains `sfdx-project.json` and that you have run the setup-project step to copy rules into `.claude/rules/`.

### Validators failing on install

Run the full test suite to identify the issue:

```bash
npm test
```

This executes all component validators (agents, commands, rules, skills, hooks) and reports any malformed files.
