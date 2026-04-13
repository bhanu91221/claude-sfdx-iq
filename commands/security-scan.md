---
description: Security vulnerability scan for CRUD/FLS, sharing model, SOQL injection, XSS, and hardcoded secrets
argument-hint: "[file, directory, or blank for changed files]"
allowed-tools: [Read, Glob, Grep, Bash]
---

# /security-scan

Scan the entire codebase for security vulnerabilities: CRUD/FLS enforcement, sharing model violations, SOQL injection, CSP/XSS issues in LWC, and hardcoded secrets.

## Workflow

### Step 1: Discover Scannable Files

- Apex classes: `Glob force-app/**/*.cls`
- Apex triggers: `Glob force-app/**/*.trigger`
- LWC JavaScript: `Glob force-app/**/lwc/**/*.js`
- LWC HTML templates: `Glob force-app/**/lwc/**/*.html`
- Visualforce pages: `Glob force-app/**/*.page` (if present)

### Step 2: Delegate to security-auditor Agent

Pass the full file inventory to the **security-auditor** agent for comprehensive review across:

**CRUD/FLS Enforcement:**
- `@AuraEnabled` methods without `WITH USER_MODE`, `WITH SECURITY_ENFORCED`, or `Security.stripInaccessible()`
- `@RestResource` methods without access enforcement
- Visualforce controllers without field-level checks

**Sharing Model:**
- Apex classes missing `with sharing`, `without sharing`, or `inherited sharing` keyword
- `without sharing` classes that are user-facing (require documented justification)

**SOQL Injection:**
- `Database.query()` with string concatenation
- Inline SOQL built with `+` operator and user-supplied variables
- `String.format()` used to construct SOQL

**LWC/CSP Security:**
- `innerHTML` assignments with non-static values
- `eval()` usage
- External script loading outside `lightning/platformResourceLoader`

**Hardcoded Secrets:**
- Passwords, API keys, tokens, or credentials in Apex strings
- Hardcoded endpoint URLs (should use Named Credentials)
- Hardcoded Record Type IDs, Profile IDs, User IDs

**Experience Cloud Guest User:**
- Classes accessible to guest user profiles without explicit security review
- `without sharing` classes exposed to unauthenticated users

### Step 3: Generate Prioritized Report

```
# Security Scan Report

## Summary
| Severity | Count | Must Fix Before Deploy |
|----------|-------|----------------------|
| CRITICAL | X | Yes |
| HIGH | X | Recommended |
| MEDIUM | X | Next Sprint |
| LOW | X | Backlog |

## CRUD/FLS Compliance
| File | Method | Enforcement | Status |
|------|--------|-------------|--------|

## Sharing Model Violations
| File | Current Keyword | Risk | Action |
|------|----------------|------|--------|

## Injection Vulnerabilities
| File | Line | Pattern | Fix |
|------|------|---------|-----|

## Detailed Findings
[CRITICAL findings first, full descriptions with file:line and remediation]

## Remediation Priority
1. [Most critical — immediate fix]
2. ...
```

## Error Handling

- If no Apex or LWC files found, inform the user
- If a file cannot be parsed, note it in the report and continue
- Report only actionable findings — no false positives for intentional `without sharing` with documented justification

## Examples

```
/security-scan
```
