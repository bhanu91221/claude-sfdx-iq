# claude-sfdx-iq

![npm test](https://img.shields.io/badge/npm%20test-416%20passing-brightgreen)
![License: MIT](https://img.shields.io/badge/License-MIT-blue)
![42 commands](https://img.shields.io/badge/commands-42-orange)
![14 agents](https://img.shields.io/badge/agents-14-purple)
![36 skills](https://img.shields.io/badge/skills-36-teal)
![44 rules](https://img.shields.io/badge/rules-44-red)

> Production-ready Claude Code plugin for Salesforce DX development. 14 specialist agents, 36 domain skills, 42 slash commands, 44 always-on rules, and 16 automated hook scripts — all tailored for Apex, LWC, SOQL, Flows, and SFDX DevOps.

---

## Installation

### Option A: Claude Marketplace (Full Control)

After pushing to GitHub, your repo acts as both the plugin AND the marketplace.

**Users install with 2 commands:**

```bash
# 1. Add your marketplace (one-time setup)
/plugin marketplace add bhanu91221/claude-sfdx-iq

# 2. Install the plugin
/plugin install claude-sfdx-iq@claude-sfdx-iq
```

Then copy the example CLAUDE.md into your SFDX project root:

```bash
# From inside your SFDX project
cp ~/.claude/plugins/claude-sfdx-iq/examples/CLAUDE.md ./CLAUDE.md
```

Open Claude Code in your project — all 42 commands and 14 agents are immediately available.

### Activating the Rules (Required)

Because Claude Code plugins cannot currently automatically distribute the `rules/` folder, you must activate the 44 rules manually. Add them to your SFDX project's CLAUDE.md:

```bash
# After installing the plugin, append rule references to your project CLAUDE.md
cat >> ./CLAUDE.md << 'EOF'

## Loaded Rules (claude-sfdx-iq)

@~/.claude/plugins/claude-sfdx-iq/rules/common/security.md
@~/.claude/plugins/claude-sfdx-iq/rules/common/code-quality.md
@~/.claude/plugins/claude-sfdx-iq/rules/apex/bulkification.md
@~/.claude/plugins/claude-sfdx-iq/rules/apex/patterns.md
@~/.claude/plugins/claude-sfdx-iq/rules/lwc/patterns.md
@~/.claude/plugins/claude-sfdx-iq/rules/soql/performance.md
@~/.claude/plugins/claude-sfdx-iq/rules/flows/best-practices.md
@~/.claude/plugins/claude-sfdx-iq/rules/metadata/deployment.md
EOF
```

> **Shortcut:** The pre-built `examples/CLAUDE.md` already includes all rule references — use it instead of appending manually (see the `cp` command above).

### Installation Profiles (Clone Workflow)

If you cloned the repo manually, use `csiq` to install only the components you need:

```bash
git clone https://github.com/bhanu91221/claude-sfdx-iq.git
cd claude-sfdx-iq
npm install

# Install a profile into your SFDX project
node scripts/csiq.js install --profile developer --target /path/to/your/sfdx-project
```

Choose the profile that matches your role:

| Profile | Agents | Skills | Commands | Rules | Hooks | Best For |
|---------|--------|--------|----------|-------|-------|----------|
| `core` | 4 | 8 | 10 | 12 | 4 | Minimal setup, CI environments |
| `developer` | 8 | 20 | 25 | 24 | 8 | Individual Apex/LWC developers |
| `architect` | 10 | 28 | 30 | 32 | 10 | Solution architects, tech leads |
| `admin` | 6 | 15 | 18 | 20 | 6 | Salesforce admins, declarative dev |
| `isv` | 12 | 30 | 35 | 38 | 12 | ISV partners, managed packages |
| `full` | 14 | 36 | 42 | 44 | 16 | Everything enabled |

```bash
node scripts/csiq.js install --profile developer
node scripts/csiq.js install --profile full
```

### Prerequisites

| Tool | Version | Required For |
|------|---------|-------------|
| Node.js | 18+ | CLI tools, hooks |
| Salesforce CLI (`sf`) | latest | Deploy, test, org commands |
| Claude Code | latest | All commands and agents |
| Git | any | Version control hooks |

---

## Quick Start

After installation, open your SFDX project in Claude Code and try:

```
# Review your Apex code for quality issues
/csiq-apex-review

# Run Apex tests with coverage
/csiq-test

# Full security scan
/csiq-security-scan

# Start a new feature with TDD
/csiq-tdd Build an AccountService that returns active accounts

# Scaffold a complete trigger with handler and tests
/csiq-scaffold-trigger Opportunity

# Deploy to sandbox
/csiq-deploy
```

---

## What It Does

Claude SFDX IQ transforms Claude into a team of 14 Salesforce specialists that work alongside you:

### Before the plugin
```apex
// Claude writes this — looks fine, breaks at 200+ records
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
    update acc;
}
```

### With the plugin
```apex
// Claude writes bulkified, secure code automatically
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [
    SELECT Id, AccountId FROM Contact
    WHERE AccountId IN :accounts
    WITH SECURITY_ENFORCED
]) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}
```

The plugin enforces:
- **Governor limits first** — No SOQL/DML in loops, ever
- **Security by default** — `with sharing`, CRUD/FLS, bind variables, no injection
- **Bulkification always** — All code handles 200+ records
- **Test-driven** — 75% minimum coverage, 90%+ target, bulk tests required

---

## Command Reference

### Deployment & Retrieval
| Command | Description |
|---------|-------------|
| `/csiq-deploy` | Source deploy with validation + automatic test level selection |
| `/csiq-push` | Push source to scratch org |
| `/csiq-validate` | Check-only deployment (no changes applied) |
| `/csiq-retrieve` | Retrieve metadata from org |
| `/csiq-destructive` | Generate destructiveChanges.xml |
| `/csiq-destructive-deploy` | Deploy destructive changes with safety checks |

### Code Review & Quality
| Command | Description |
|---------|-------------|
| `/csiq-apex-review` | Apex quality review (bulkification, naming, patterns) |
| `/csiq-lwc-review` | LWC component review (decorators, events, accessibility) |
| `/csiq-soql-review` | SOQL optimization analysis |
| `/csiq-soql-check` | Quick SOQL anti-pattern scan |
| `/csiq-security-scan` | CRUD/FLS/sharing/injection vulnerability scan |
| `/csiq-governor-check` | Governor limit risk analysis |
| `/csiq-flow-review` | Flow best practices check |
| `/csiq-pmd-scan` | PMD static analysis via Salesforce Code Analyzer |
| `/csiq-code-review` | Full review — all agents in parallel |
| `/csiq-org-health` | Org health and technical debt assessment |

### Testing
| Command | Description |
|---------|-------------|
| `/csiq-test` | Run Apex tests with coverage analysis |
| `/csiq-tdd` | TDD workflow — Red-Green-Refactor for Apex and LWC |
| `/csiq-lwc-test` | Run LWC Jest tests |
| `/csiq-test-data` | Generate TestDataFactory class |
| `/csiq-integration-test` | Run integration tests against org |

### Scaffolding
| Command | Description |
|---------|-------------|
| `/csiq-scaffold-trigger` | Generate trigger + handler + test (3 files) |
| `/csiq-scaffold-lwc` | Generate LWC component — JS, HTML, CSS, meta, test (5 files) |
| `/csiq-scaffold-apex` | Generate Apex class + test |
| `/csiq-scaffold-apex-class` | Generate specific pattern — Service, Selector, Domain, etc. |
| `/csiq-scaffold-batch` | Generate Batch + Scheduler + test |
| `/csiq-scaffold-integration` | Generate callout service + mock + test |
| `/csiq-scaffold-flow` | Generate Flow design blueprint |

### Planning & Architecture
| Command | Description |
|---------|-------------|
| `/csiq-plan` | Implementation plan for an SFDX feature |
| `/csiq-data-model` | Design or analyze data model |
| `/csiq-metadata-analyze` | Analyze metadata dependencies |
| `/csiq-metadata-diff` | Compare metadata between orgs or branches |

### Utilities
| Command | Description |
|---------|-------------|
| `/csiq-debug-log` | Retrieve and analyze Salesforce debug logs |
| `/csiq-build-fix` | Diagnose and fix deployment/compilation errors |
| `/csiq-explain-error` | Explain Salesforce error messages with fix guidance |
| `/csiq-sf-help` | Salesforce CLI command reference |
| `/csiq-apex-doc` | Generate ApexDoc documentation |
| `/csiq-create-scratch-org` | Create and configure scratch org |
| `/csiq-package-version` | Create 2GP package version |
| `/csiq-data-seed` | Load test/sample data into org |

Run `/help` for the complete list of all 42 commands.

---

## The 14 Agents

Each agent is a Salesforce specialist. Commands route to them automatically — you rarely call them directly.

| Agent | Specialty | Used By |
|-------|-----------|---------|
| `planner` | Implementation plans across Apex/LWC/metadata | `/csiq-plan` |
| `architect` | Solution architecture, scalability, integrations | `/csiq-plan`, `/csiq-data-model` |
| `apex-reviewer` | Bulkification, naming, error handling, patterns | `/csiq-apex-review`, `/csiq-code-review` |
| `lwc-reviewer` | Wire usage, events, accessibility, performance | `/csiq-lwc-review`, `/csiq-code-review` |
| `soql-optimizer` | Selectivity, indexes, N+1 patterns, binding | `/csiq-soql-review` |
| `security-reviewer` | CRUD/FLS, sharing, injection, CSP | `/csiq-security-scan`, `/csiq-code-review` |
| `governor-limits-checker` | DML/SOQL in loops, CPU, heap | `/csiq-governor-check`, `/csiq-code-review` |
| `flow-analyst` | Flow XML, DML in loops, fault paths | `/csiq-flow-review` |
| `deployment-specialist` | Deploy, packages, destructive changes | `/csiq-deploy`, `/csiq-package-version` |
| `test-guide` | TDD for Apex (90%+) and LWC Jest | `/csiq-tdd`, `/csiq-test` |
| `integration-specialist` | REST/SOAP callouts, events, CDC | `/csiq-scaffold-integration` |
| `metadata-analyst` | Metadata dependencies, unused components | `/csiq-metadata-analyze`, `/csiq-org-health` |
| `data-modeler` | Object relationships, external IDs, data skew | `/csiq-data-model` |
| `admin-advisor` | Permission sets, sharing rules, validation rules | `/csiq-org-health` |

---

## Architecture

```
You
 │
 ├─ /csiq-command  ──────────────────────────────────────────────
 │                                                              │
 ▼                                                             ▼
Commands (42)          Hooks (16 scripts — fire automatically)
 │                      │
 │  ┌─ post-edit-governor-scan.js  (every .cls save)
 │  ├─ post-edit-security-scan.js  (every .cls save)
 │  ├─ post-edit-pmd-scan.js       (every .cls save)
 │  ├─ post-edit-debug-warn.js     (every .cls save)
 │  ├─ quality-gate.js             (pre-commit)
 │  └─ session-start.js            (session init)
 │
 ▼
Agents (14 specialists)
 │
 ├── Skills (36 knowledge modules — auto-loaded by context)
 │     apex-patterns, governor-limits, security-patterns,
 │     lwc-testing, soql-optimization, tdd-workflow ...
 │
 └── Rules (44 always-enforced guidelines)
       common/security, apex/bulkification, lwc/patterns,
       soql/performance, flows/best-practices ...
 │
 ▼
Salesforce CLI  →  Salesforce Org
```

### Core Principles

1. **Governor-Limits-First** — Every code change evaluated against governor limits
2. **Security-First** — CRUD/FLS enforcement, `with sharing` by default, no SOQL injection
3. **Test-Driven** — 75% minimum coverage (90%+ target), test-first development
4. **Bulkification Always** — All code handles 200+ records in trigger context
5. **Agent-First** — Delegate to specialized agents for domain tasks
6. **Plan Before Execute** — Plan complex features before writing code

---

## CLI Tools

The `csiq` CLI manages plugin installation and health. Available when you clone the repo (see Installation Profiles above):

```bash
# Show help
node scripts/csiq.js help

# Install profile into an SFDX project
node scripts/csiq.js install --profile developer --target ./my-sfdx-project

# See plugin status and component counts
node scripts/csiq.js status

# Diagnose environment (Node, sf CLI, Git, org connection)
node scripts/csiq.js doctor

# Check and repair plugin integrity
node scripts/csiq.js repair

# List all installed components
node scripts/csiq.js list --category agents
node scripts/csiq.js list --category commands
```

---

## Project Structure

```
claude-sfdx-iq/
├── agents/          (14)  Specialized Salesforce subagents
├── commands/        (42)  Slash commands
├── skills/          (36)  Domain knowledge modules
├── rules/           (44)  Always-follow guidelines
│   ├── common/      (9)   Universal rules
│   ├── apex/        (9)   Apex-specific rules
│   ├── lwc/         (6)   LWC-specific rules
│   ├── soql/        (6)   SOQL rules
│   ├── flows/       (6)   Flow rules
│   └── metadata/    (8)   Metadata rules
├── hooks/           (6)   Hook JSON definitions
├── scripts/
│   ├── hooks/       (16)  Automated hook scripts
│   ├── lib/         (10)  Shared library scripts
│   └── ci/          (7)   CI validation scripts
├── contexts/        (5)   Mode contexts (develop/review/debug/deploy/admin)
├── manifests/       (5)   Installation profiles
├── mcp-configs/     (6)   MCP server configurations
├── schemas/         (5)   JSON validation schemas
├── examples/              Template files for SFDX projects
├── docs/                  Architecture, customization, contributing guides
└── tests/           (14)  Validator and unit tests
```

---

## Hook Profiles

Control hook aggressiveness via environment variable:

```bash
# Minimal — critical checks only (fastest)
export CSIQ_HOOK_PROFILE=minimal

# Standard — balanced checks (default)
export CSIQ_HOOK_PROFILE=standard

# Strict — all checks including style warnings
export CSIQ_HOOK_PROFILE=strict

# Disable specific hooks
export CSIQ_DISABLED_HOOKS="post-edit-pmd-scan,post-edit-debug-warn"
```

---

## Running Tests

```bash
# Run all validators and unit tests (416 tests)
npm test

# Run individual validators
node scripts/ci/validate-agents.js
node scripts/ci/validate-skills.js
node scripts/ci/validate-commands.js
node scripts/ci/validate-hooks.js
node scripts/ci/validate-rules.js
node scripts/ci/validate-manifests.js
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Guide.md](Guide.md) | Complete guide — what it is, how to use it, tips and tricks |
| [docs/INSTALLATION.md](docs/INSTALLATION.md) | Detailed installation and setup |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical architecture and component flow |
| [docs/COMMAND-REFERENCE.md](docs/COMMAND-REFERENCE.md) | All 42 commands with flags and examples |
| [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | How to add custom agents, skills, commands, rules |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Contribution guidelines |
| [pluginMarketPlace.md](pluginMarketPlace.md) | How to publish to the Claude marketplace |
| [testPlan.md](testPlan.md) | End-to-end test plan |

---

## Contributing

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines on adding agents, skills, commands, hooks, and rules.

**File naming:** lowercase with hyphens — e.g., `apex-reviewer.md`, `soql-optimization/`

**Commit format:** `<type>: <description>` — Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

---

## License

MIT — see [LICENSE](LICENSE) for details.
