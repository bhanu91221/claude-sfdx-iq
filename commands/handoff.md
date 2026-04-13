---
description: Generate a session summary for context handoff to the next conversation
argument-hint: "[--save]"
allowed-tools: [Read, Write, Glob, Bash]
---

# /handoff

Generate a structured session summary so the next conversation can pick up exactly where this one left off. Captures what was built, what decisions were made, and what's next.

## Usage

```
/handoff          Display session summary in chat
/handoff --save   Display summary AND write to HANDOFF.md in project root
```

---

## Workflow

### Step 1: Gather Session Context

Collect the session's work automatically:

```bash
# What files changed this session
git diff --name-only HEAD~1 HEAD 2>/dev/null || git status --short

# Recent commit history (if any commits were made)
git log --oneline -5 2>/dev/null

# Current branch
git branch --show-current 2>/dev/null
```

Also scan for:
- Any newly created files in this session
- Errors or blockers encountered
- Agent outputs from the session

### Step 2: Generate Handoff Document

Produce the following structured summary:

```markdown
# Session Handoff — [Date]

## What Was Built
<!-- List each file created or significantly modified, one line per file -->
- `force-app/main/default/classes/AccountService.cls` — Created service layer with processAccounts() and updateIndustry()
- `force-app/main/default/classes/AccountServiceTest.cls` — Test class with 92% coverage

## Decisions Made
<!-- Key architectural or implementation decisions and WHY -->
- Used `inherited sharing` on AccountService to allow callers to control sharing context (AccountController uses `with sharing`, batch uses `without sharing`)
- Chose Queueable over @future for sync because callout is needed after DML
- TestDataFactory pattern adopted: created TestDataFactory.cls for reuse across test classes

## What's Next
<!-- Incomplete work, next steps, open questions -->
- [ ] Add OpportunityService.cls following same pattern as AccountService
- [ ] Wire AccountController.getAccounts() to accountSummaryCard LWC component
- [ ] Run full org test suite before deploying: `sf apex run test --test-level RunLocalTests`
- [ ] Review if AccountSelector needs a custom index on Industry field (high-volume org)

## Files Changed This Session
<!-- Auto-populated from git diff -->
[list from git diff]

## How to Resume
At the start of your next session, say:
"Read HANDOFF.md and continue from where we left off on [feature name]."
```

### Step 3: Save (if --save flag)

Write the document to `HANDOFF.md` in the project root:

```
✅ Handoff saved to HANDOFF.md
   Load it next session with: "Read HANDOFF.md and continue from where we left off"
```

---

## When to Use

- Before ending a long development session
- Before switching to a different feature (saves context for this one)
- When handing work to another developer using Claude Code
- When you've hit a complex decision point and want to resume with full context

---

## Examples

```
/handoff
/handoff --save
```
