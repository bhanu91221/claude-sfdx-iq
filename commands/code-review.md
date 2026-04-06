---
description: Full code review across Apex, LWC, and Flows using specialized agents
---

# /code-review

Run a comprehensive code review by delegating to specialized agents. Supports targeted review by domain or full codebase review.

## Usage

```
/code-review                    Review all changed files (git diff)
/code-review --apex             Review changed Apex files
/code-review --apex <file>      Review a specific Apex file or directory
/code-review --apex-all         Review all Apex files in the project
/code-review --lwc              Review changed LWC components
/code-review --lwc <component>  Review a specific LWC component
/code-review --lwc-all          Review all LWC components
/code-review --flow             Review changed Flows
/code-review --flow <name>      Review a specific Flow
/code-review --flow-all         Review all Flows in the project
```

## Workflow

### Step 1: Identify Scope

**No flag or partial flags — detect changed files:**
```bash
git diff --name-only HEAD
git diff --name-only --cached  # Also check staged
```
Categorize:
- `.cls`, `.trigger` → Apex (delegate to `apex-code-reviewer`)
- `lwc/**/*.js`, `lwc/**/*.html` → LWC (delegate to `lwc-reviewer`)
- `*.flow-meta.xml` → Flows (delegate to `flow-analyst`)

**Specific file argument:** review only that file/component/flow.

**`--all` variants:** Find all files of that type:
- Apex: `Glob force-app/**/*.cls, **/*.trigger`
- LWC: `Glob force-app/**/lwc/**/*.js`
- Flow: `Glob force-app/**/*.flow-meta.xml`

If no reviewable files are found, inform the user and suggest narrowing scope or checking git status.

### Step 2: Delegate to Specialized Agents (in parallel when multiple domains)

| Files | Agent |
|-------|-------|
| `.cls`, `.trigger` | **apex-code-reviewer** — bulkification, governor limits, SOQL, security, naming, error handling |
| `lwc/**` | **lwc-reviewer** — decorators, lifecycle, events, accessibility, CSS, error/loading states |
| `*.flow-meta.xml` | **flow-analyst** — DML in loops, fault paths, before/after save, recursion, naming |

If scope is very large (50+ files), warn the user and suggest narrowing to changed files or a specific directory.

### Step 3: Consolidate Findings

Merge all agent findings into a single report:
- Deduplicate overlapping issues (same file flagged by multiple agents)
- Group by severity: CRITICAL → HIGH → MEDIUM → LOW
- For each finding: file path, line number (if available), domain, description, fix

### Step 4: Generate Report

```
# Code Review Report

## Summary
| Domain | CRITICAL | HIGH | MEDIUM | LOW |
|--------|----------|------|--------|-----|
| Apex   | X        | X    | X      | X   |
| LWC    | X        | X    | X      | X   |
| Flows  | X        | X    | X      | X   |

## Overall Health Score: X/100
(Start at 100; -10 per CRITICAL, -5 per HIGH, -2 per MEDIUM, -1 per LOW)

## Critical Findings (must fix before merge/deploy)
...

## High Findings
...

## Top 3 Action Items
1. [Most impactful fix]
2. ...
3. ...
```

## Error Handling

- If an agent encounters a parse error on a file, report it as unreadable and continue
- If a file type is unrecognized, skip it and note it in the summary
- If git diff fails (not a git repo), ask the user to specify files

## Examples

```
/code-review
/code-review --apex
/code-review --apex force-app/main/default/classes/AccountService.cls
/code-review --apex-all
/code-review --lwc accountList
/code-review --flow Account_UpdateContactIndustry_RAF
/code-review --flow-all
```
