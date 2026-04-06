# Architecture

## System Overview

```
User
  |
  v
Commands (/apex-class --review, /trigger --new, /code-review --apex, ...)
  |   (each command includes domain standards inline)
  |
  +---> Agent (invoked when deeper expertise is needed)
  |       apex-code-reviewer, lwc-reviewer, security-auditor,
  |       solution-designer, devops-coordinator, flow-analyst,
  |       integration-specialist
  |
  v
SF CLI / External Tools (sf project deploy, sf apex run test, ...)
  |
  v
Salesforce Org
```

Commands are self-contained. Each command includes the domain standards it needs (Apex patterns, governor limits, SOQL rules, etc.) baked inline. There is no dynamic loading step — invoking a command is all that is needed.

## Component Flow: /apex-class --review Example

When a user runs `/apex-class --review AccountService.cls`:

1. **Command layer** (`commands/apex-class.md`) identifies the target file and loads its domain standards from its inline standards section: sharing keywords, bulkification rules, SOQL selectivity, governor limits reference, error handling patterns, and naming conventions.

2. **Review execution** The command applies the inline standards against the file content, producing a structured findings list with severity levels (critical / warning / suggestion).

3. **Agent delegation** For deeper analysis, the command delegates to the `apex-code-reviewer` agent (`agents/apex-code-reviewer.md`), which performs a comprehensive review covering N+1 SOQL detection, bulk safe patterns, CPU risk estimation, and security posture.

4. **Result reporting** The agent returns structured findings grouped by severity. Critical issues (e.g., SOQL in a loop) are flagged first with specific line references and fix guidance.

## Agent Delegation

Commands invoke specialized agents for domain expertise. Each agent has defined tools and a model specified in its frontmatter:

| Agent | Invoked By | Specialization |
|-------|-----------|----------------|
| `apex-code-reviewer` | `/apex-class --review`, `/trigger --review`, `/code-review --apex` | Apex quality, SOQL, governor limits |
| `lwc-reviewer` | `/lwc --review`, `/code-review --lwc` | LWC component quality |
| `security-auditor` | `/security-scan`, `/apex-class --review` | CRUD/FLS, injection, sharing |
| `flow-analyst` | `/flow --review`, `/code-review --flow` | Flow best practices |
| `solution-designer` | `/plan` | Architecture, phased planning |
| `devops-coordinator` | `/org-health` | Deployment, org health, CI/CD |
| `integration-specialist` | `/integration-apex` | REST/SOAP callouts, CDC |

Agents operate independently and return structured findings. The command layer assembles the final output.

## Hook Pipeline

Hooks trigger automatically on file events. The pipeline is:

```
File Saved/Edited
  |
  v
Matcher (file pattern, e.g., *.cls)
  |
  v
Hook Script (e.g., scripts/hooks/apex-pmd-scan.js)
  |
  v
Findings Output (severity, line number, message, rule)
```

Hook definitions live in `hooks/` as JSON files. Each hook specifies:

- **matcher**: file glob pattern and event type (post-edit, pre-commit)
- **command**: the script or tool to execute
- **args**: arguments passed to the command

Example from `hooks/apex-post-edit.json`: when an Apex class is saved, the PMD scanner runs and outputs findings inline.

## Extension Points

### Adding a new agent

Create a markdown file in `agents/` with YAML frontmatter specifying `name`, `description`, `tools`, and `model`. The agent becomes available to commands immediately.

### Adding a new command

Create a markdown file in `commands/` with `description` frontmatter. Include an inline domain standards section with the rules and patterns the command needs. The command is registered as a slash command automatically.

To add flags to a command, document them in the command body with clear workflow steps for each flag (e.g., `--new`, `--review`, `--refine`, `--bug-fix`).

### Adding a new hook

Create a JSON file in `hooks/` with `matcher` and `hooks` arrays. The hook fires whenever a matching file event occurs.
