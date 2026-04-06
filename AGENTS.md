# Claude SFDX IQ — Agent Instructions

This is a **Salesforce DX Claude Code plugin** providing 7 specialized agents, 19 self-contained commands, 8 hook definitions, 16 hook scripts, 5 CLI tools, and 5 mode contexts for Salesforce development.

## Core Principles

1. **Governor-Limits-First** — Every code path evaluated for SOQL, DML, CPU, heap limits
2. **Security-First** — CRUD/FLS enforcement, `with sharing`, no SOQL injection
3. **Test-Driven** — 75% minimum (90%+ target), Apex test-first, LWC Jest
4. **Bulkification Always** — Handle 200+ records in every trigger and batch context
5. **Plan Before Execute** — Plan complex Salesforce features before writing code
6. **Agent-First** — Delegate to specialized Salesforce agents for domain tasks

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| apex-code-reviewer | Apex quality: bulkification, SOQL selectivity, N+1, governor limits | After writing/modifying Apex code |
| solution-designer | Solution architecture, phased implementation plans, integration design | Complex features, architectural decisions |
| devops-coordinator | Deployment strategy, test patterns, org health, CI/CD pipelines | Deploy planning, org health checks |
| lwc-reviewer | LWC component quality: wire, events, accessibility, performance | After writing/modifying LWC components |
| security-auditor | CRUD/FLS, sharing model, SOQL injection, XSS, CSP, guest user | Security-sensitive code, before commits |
| flow-analyst | Flow best practices: DML in loops, fault paths, recursion, naming | Flow automation analysis and review |
| integration-specialist | REST/SOAP callouts, Named Credentials, platform events, CDC | Integration code, external services |

## Agent Orchestration

Commands invoke agents automatically. Use agents proactively without user prompt:

- Apex code written/modified → **apex-code-reviewer**
- LWC code written/modified → **lwc-reviewer**
- Security-sensitive code → **security-auditor**
- Flow automation added/changed → **flow-analyst**
- Integration/callout code → **integration-specialist**
- Architectural decision → **solution-designer**
- Deployment operations → **devops-coordinator**

Use parallel execution for independent operations — launch multiple agents simultaneously (e.g., apex-code-reviewer + security-auditor for a new service class).

## Security Guidelines

**Before ANY commit:**
- [ ] All Apex uses `with sharing` (or explicit justification for `without sharing`)
- [ ] All SOQL uses bind variables or `WITH SECURITY_ENFORCED`
- [ ] No dynamic SOQL with string concatenation
- [ ] `Security.stripInaccessible()` used for DML with user-provided data
- [ ] No hardcoded credentials, API keys, or tokens
- [ ] Connected App secrets in Named Credentials, not code
- [ ] Error messages don't expose field names or object structure to unauthorized users

**If security issue found:** STOP → use security-auditor agent → fix CRITICAL issues → review codebase for similar issues.

## Coding Style

**Bulkification (CRITICAL):** All trigger handlers must process `Trigger.new` as a collection. No SOQL or DML inside for loops — ever. Use Maps for lookups.

**File organization:** One trigger per object. Handler class per trigger. Service classes for reusable business logic. Selector classes for SOQL encapsulation. 200-400 lines typical, 800 max.

**Naming:** PascalCase for classes, camelCase for methods/variables, UPPER_SNAKE for constants. Descriptive names — `AccountTriggerHandler` not `ATH`.

## Testing Requirements

**Minimum coverage: 75% (Salesforce requirement), target 90%+**

Test types (all required for Apex):
1. **Unit tests** — Individual methods, utility classes, trigger handlers
2. **Integration tests** — DML operations, SOQL queries, callout mocks
3. **Bulk tests** — Test with 200+ records to verify bulkification

**TDD workflow:**
1. Write test first (RED) — test should FAIL
2. Write minimal Apex implementation (GREEN) — test should PASS
3. Refactor (IMPROVE) — verify coverage 90%+

**Test patterns:**
- Use `@TestSetup` for shared test data
- Use `TestDataFactory` pattern for reusable test data creation
- Use `Test.startTest()`/`Test.stopTest()` for governor limit reset
- Use `System.runAs()` for user context and sharing tests
- Implement `HttpCalloutMock` for external callout tests

## Development Workflow

1. **Plan** — Use solution-designer agent for complex features
2. **TDD** — Write Apex tests first before implementation
3. **Review** — Use apex-code-reviewer + security-auditor agents
4. **Deploy** — Use devops-coordinator agent for deploy planning
5. **Commit** — Conventional commits format

## Git Workflow

**Commit format:** `<type>: <description>` — Types: feat, fix, refactor, docs, test, chore, perf, ci

**Branch naming:** `feature/TICKET-description`, `fix/TICKET-description`, `release/vX.Y.Z`

## Project Structure

```
agents/          — 7 specialized Salesforce subagents
commands/        — 19 self-contained slash commands with inline domain standards
hooks/           — Trigger-based automations with 16 hook scripts
contexts/        — 5 mode-specific context files (develop, review, debug, deploy, admin)
scripts/         — Cross-platform Node.js utilities, CLI tools, library scripts
mcp-configs/     — MCP server configurations
tests/           — Test suite
```

## Success Metrics

- All Apex tests pass with 90%+ coverage
- No security vulnerabilities (CRUD/FLS enforced, no injection)
- No governor limit violations
- All code handles 200+ records (bulkified)
- Code is readable and follows Salesforce best practices
