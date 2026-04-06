# Command Reference

All commands are invoked as slash commands within Claude Code (e.g., `/apex-class --review`).

Commands are self-contained — each includes its own domain standards. No context loading step is required.

---

## Domain Commands

Each domain command covers the full lifecycle of a Salesforce artifact. Use flags to select the workflow.

### Flag Behaviors (consistent across all domain commands)

| Flag | Workflow |
|------|----------|
| `--new` | Gather requirements → scaffold artifact + test class → explain what was generated |
| `--review` | Identify files → apply domain standards → delegate to agent → severity report |
| `--refine` | Understand change request → apply modification → update tests |
| `--bug-fix` | Gather symptoms (current vs. expected) → diagnose root cause → fix → explain |
| `--explain` | Describe purpose, data flow, key behaviors, dependencies |

---

### /apex-class

General-purpose Apex classes: service layers, controllers, utilities, selectors.

**Baked-in standards:** `with sharing` enforcement, bulkification, SOQL bind variables, governor limits reference, error handling patterns, naming conventions, test patterns.

| Flag | Example |
|------|---------|
| `--new` | `/apex-class --new` (asks for name, type, sObject) |
| `--review` | `/apex-class --review AccountService.cls` |
| `--refine` | `/apex-class --refine AccountService.cls` |
| `--bug-fix` | `/apex-class --bug-fix AccountService.cls` |

`--review` delegates to `apex-code-reviewer` agent.

---

### /trigger

Apex triggers with handler delegation. Enforces one-trigger-per-object.

**Baked-in standards:** one-trigger-per-object, handler delegation pattern, zero logic in trigger body, recursion prevention, all 7 event contexts, bulkification.

| Flag | Example |
|------|---------|
| `--new` | `/trigger --new` (asks for sObject, events) |
| `--review` | `/trigger --review AccountTrigger.trigger` |
| `--refine` | `/trigger --refine AccountTrigger.trigger` |
| `--bug-fix` | `/trigger --bug-fix AccountTrigger.trigger` |

Checks for existing triggers on the sObject before creating a new one.

---

### /async-apex

Asynchronous Apex: Batch, Queueable, Schedulable, @future methods.

**Baked-in standards:** Batch/Queueable/Schedulable/@future patterns, async governor limits (200 SOQL, 60k CPU, 12MB heap), chaining patterns, `Test.startTest()/stopTest()` for async tests.

| Flag | Example |
|------|---------|
| `--new` | `/async-apex --new` (asks for type, purpose) |
| `--refine` | `/async-apex --refine DataCleanupBatch.cls` |
| `--bug-fix` | `/async-apex --bug-fix DataCleanupBatch.cls` |

---

### /integration-apex

REST and SOAP callout classes, inbound web services.

**Baked-in standards:** Named Credentials always (never hardcode endpoints), callout patterns, retry with exponential backoff, circuit breaker, inbound REST/SOAP patterns, `HttpCalloutMock` test pattern.

| Flag | Example |
|------|---------|
| `--new` | `/integration-apex --new` (asks for direction, protocol) |
| `--refine` | `/integration-apex --refine ExternalApiService.cls` |
| `--bug-fix` | `/integration-apex --bug-fix ExternalApiService.cls` |

Delegates to `integration-specialist` agent.

---

### /lwc

Lightning Web Components: UI components, data binding, event handling.

**Baked-in standards:** `@api/@wire/@track` usage, lifecycle hooks, event patterns (custom events, bubbling), SLDS design tokens, accessibility (aria), CSP security, Jest test patterns with `lwc-jest`.

| Flag | Example |
|------|---------|
| `--new` | `/lwc --new` (asks for name, purpose, targets) |
| `--explain` | `/lwc --explain accountSearch` |
| `--refine` | `/lwc --refine accountSearch` |
| `--bug-fix` | `/lwc --bug-fix accountSearch` |

`--explain` and review scenarios delegate to `lwc-reviewer` agent.

---

### /flow

Salesforce Flows: Screen Flows, Record-Triggered Flows, Scheduled Flows.

**Baked-in standards:** flow type selection matrix, DML-in-loop prohibition, fault path requirements, before-save vs after-save decision guide, recursion prevention, naming conventions.

| Flag | Example |
|------|---------|
| `--new` | `/flow --new` (asks for type, trigger object, purpose) |
| `--review` | `/flow --review Account_Automation` |
| `--refine` | `/flow --refine Account_Automation` |
| `--explain` | `/flow --explain Account_Automation` |

`--review` delegates to `flow-analyst` agent.

---

## Cross-Domain Commands

### /code-review

Full code review with specialist agents running in parallel.

| Flag | Example |
|------|---------|
| `--apex [file]` | `/code-review --apex AccountService.cls` |
| `--apex --all` | `/code-review --apex --all` (all Apex classes) |
| `--lwc [comp]` | `/code-review --lwc accountSearch` |
| `--lwc --all` | `/code-review --lwc --all` (all LWC components) |
| `--flow [name]` | `/code-review --flow Account_Automation` |
| `--flow --all` | `/code-review --flow --all` (all flows) |

Combines flags to run multiple domains in parallel: `/code-review --apex --all --lwc --all`

**Agent delegation:**
- `--apex` → `apex-code-reviewer`
- `--lwc` → `lwc-reviewer`
- `--flow` → `flow-analyst`

---

### /explain

Explain what code does. Use `--deep` for cross-file behavioral tracing.

| Flag | Example |
|------|---------|
| `--apex [file]` | `/explain --apex AccountService.cls` |
| `--lwc [comp]` | `/explain --lwc accountSearch` |
| `--flow [name]` | `/explain --flow Account_Automation` |
| `--deep` | `/explain --apex AccountTriggerHandler.cls --deep` |

`--deep` traces behavior across related files (e.g., trigger → handler → service → selector chain). Absorbs the functionality of the former `/analyze` command.

---

### /security-scan

Cross-domain security scan. No flags needed — scans the entire project.

**Checks:** CRUD/FLS enforcement, `with sharing` keywords, SOQL injection risks, XSS vectors, CSP violations, guest user access patterns, permission set coverage.

```
/security-scan
```

Delegates to `security-auditor` agent.

---

## Utility Commands

| Command | What it does | Example |
|---------|-------------|---------|
| `/setup-project` | Copy plugin configuration to SFDX project | `/setup-project` |
| `/doctor` | Diagnose plugin and org configuration issues | `/doctor` |
| `/status` | Show plugin status and org connection | `/status` |
| `/org-health` | Org health: security score, limits, technical debt, metadata | `/org-health` |
| `/data-model` | ER design, object relationships, best practices | `/data-model --sobject Account` |
| `/plan` | Implementation planning with phased roadmap | `/plan` |
| `/package` | 2GP package versioning and management | `/package` |
| `/debug-log` | Retrieve and analyze Salesforce debug logs | `/debug-log` |
| `/repair` | Auto-fix common configuration problems | `/repair` |

**Agent delegation for utility commands:**
- `/org-health` → `devops-coordinator`
- `/plan` → `solution-designer`
- `/data-model` → `solution-designer`

---

## Agent Reference

| Agent | Invoked By |
|-------|-----------|
| `apex-code-reviewer` | `/apex-class --review`, `/trigger --review`, `/code-review --apex` |
| `lwc-reviewer` | `/lwc --explain`, `/code-review --lwc` |
| `security-auditor` | `/security-scan` |
| `flow-analyst` | `/flow --review`, `/code-review --flow` |
| `solution-designer` | `/plan`, `/data-model` |
| `devops-coordinator` | `/org-health` |
| `integration-specialist` | `/integration-apex` |
