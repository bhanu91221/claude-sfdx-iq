---
description: Create, review, refine, or explain Salesforce Flows
argument-hint: "[--new | --review | --refine | --explain] [FlowName or path]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# /flow

Work with Salesforce Flows using `--new`, `--review`, `--refine`, or `--explain`.

## Usage

```
/flow --new         Design a new Flow blueprint from requirements
/flow --review      Review an existing Flow for best practices and issues
/flow --refine      Modify an existing Flow
/flow --explain     Explain what a Flow does step by step
```

---

## --new: Design a New Flow

### Gather Requirements
Ask the user:
1. What should the Flow do? (business process description)
2. What type? (Record-Triggered, Screen Flow, Schedule-Triggered, Platform Event-Triggered, Autolaunched)
3. Which object and trigger event? (for Record-Triggered: before/after save, before delete)
4. What records does it access or update?
5. Are there decision branches or conditions?
6. Does it need to call Apex actions or send emails?

### Flow Type Selection

| Type | Use When |
|------|----------|
| **Record-Triggered (Before Save)** | Update fields on the same record — no DML cost, runs synchronously |
| **Record-Triggered (After Save)** | Related record operations, callouts (via async), email alerts |
| **Screen Flow** | Guided user interactions, multi-step wizards |
| **Schedule-Triggered** | Batch operations on a schedule (small to medium datasets) |
| **Platform Event-Triggered** | React to events published to the event bus |
| **Autolaunched** | Called from Apex, other flows, or external (no user interaction) |

### Flow Design Blueprint

Generate a text-based design document:

```
## Flow: [Name]
**Type:** Record-Triggered — After Save
**Object:** Account
**Trigger:** Created or Updated

### Entry Criteria
- Run when: Record is created OR Account.Industry changes

### Flow Elements (in execution order)
1. **Decision: Industry Changed?**
   - Outcome YES: {!$Record.Industry} != {!$Record__Prior.Industry}
   - Default: End

2. **Get Records: Active Contacts**
   - Object: Contact
   - Filter: AccountId = {!$Record.Id}, IsActive__c = true
   - Store: contactsCollection (All records)

3. **Loop: For each contact**
   - Collection: contactsCollection
   - Variable: currentContact

   3a. **Update Records: Set Industry**
       - Record: currentContact
       - Field: Industry__c = {!$Record.Industry}

4. **Fault Path: Handle Errors**
   - Create Log_Error__c record with error message

### Variables
| Name | Type | Input/Output | Purpose |
|------|------|--------------|---------|
| contactsCollection | SObject Collection | — | Contacts to update |
| currentContact | SObject | — | Loop variable |

### Governor Limit Considerations
- DML inside loop — CRITICAL issue. Use Collection Update instead of updating inside loop.
  Fix: Collect updates into a collection, then use one Update Records element outside the loop.
```

**Flow Standards:**

**Performance (Critical):**
- DML inside loops — use collection operations instead
  - BAD: Update Records inside Loop
  - GOOD: Assign fields to loop variable → Add to collection → Update Records after loop
- Avoid SOQL inside loops — use Get Records before the loop with a filter
- Keep loops under 2,000 iterations (schedule-triggered flows have governor limits too)

**Reliability:**
- Every flow that performs DML, callouts, or complex logic must have a **Fault Path**
- Fault path should create an error log or send a notification — never leave it empty
- Before-save flows: no fault path needed (rollback is automatic on error)

**Before-Save vs After-Save:**
```
Before Save (faster, no DML cost):
  ✓ Field updates on the same record
  ✓ Validation-like logic
  ✗ Cannot create/update related records
  ✗ Cannot call Apex

After Save:
  ✓ Related record operations
  ✓ Email alerts, Apex actions
  ✗ Direct field update on triggering record requires Get + Update (extra DML)
```

**Recursion Prevention:**
- Record-triggered flows auto-prevent direct recursion (the same record re-triggering the same flow)
- But watch for: Flow A updates Record B → Flow B updates Record A → infinite loop
- Use a Custom Metadata flag or `{!$Flow.CurrentRecord}` checks when needed

**Naming:**
- Flow API name: `Object_ActionDescription_Type` — e.g., `Account_UpdateContactIndustry_RAF`
- Variables: descriptive camelCase — `contactsCollection`, `currentContact`, `errorMessage`
- Decision outcomes: descriptive — `industryChanged`, `defaultOutcome`

**When NOT to Use Flow:**
- More than 5-7 decision nodes → Use Apex
- >2,000 record loops → Use Batch Apex
- Complex SOQL logic → Use Apex
- Multi-object transactions needing rollback → Use Apex
- Callouts with retry logic → Use Apex with `Database.AllowsCallouts`

---

## --review: Review an Existing Flow

### Identify the Flow
- If `--review <FlowName or path>` provided, use that
- If no argument, ask: "Which flow would you like me to review?"
- Search: `force-app/**/flows/*.flow-meta.xml`

### Read and Parse the Flow XML
Read the `.flow-meta.xml` file. Parse key elements:
- `<processType>` — flow type
- `<start>` — entry conditions
- `<decisions>`, `<loops>`, `<assignments>`, `<recordLookups>`, `<recordUpdates>`, `<recordCreates>`
- `<actionCalls>` — Apex actions
- `<faultConnectors>` — error handling

### Review Checks

**CRITICAL:**
- DML operation (recordUpdates/recordCreates/recordDeletes) inside a Loop element
- No fault path on flows that perform DML or callouts
- Recursive flow chain (verify with `<triggerType>` and conditions)
- Active flow modifying the same record it's triggered on in after-save context (triggers re-entry)

**HIGH:**
- Get Records inside a Loop (N+1 query pattern)
- Missing entry criteria (runs on every save, not just relevant changes)
- Scheduled-triggered flow without a record count estimate
- Fault path present but empty (not logging the error)

**MEDIUM:**
- Variable naming is single-letter or non-descriptive
- Flow has no description or purpose documentation
- More than 7 decision nodes (consider Apex instead)
- Old API version (flag flows not updated in 2+ years)

**LOW:**
- Unused variables
- Hard-to-read decision outcome names

**Delegate to flow-analyst agent** for deep flow analysis if needed.

---

## --refine: Modify an Existing Flow

**Important:** Flows are XML metadata — modifications here mean generating the corrected XML or providing the step-by-step changes to make in Flow Builder.

1. Read the flow XML completely
2. Understand the current logic and connections
3. Describe the change with:
   - The new/modified elements
   - Where they connect in the flow (after which element)
   - Updated variable assignments if needed
4. Provide either:
   - Updated XML for the specific changed elements (for source-controlled flows)
   - Step-by-step instructions for Flow Builder (for declarative editing)

---

## --explain: Explain a Flow

### Identify the Flow
- If path provided, use it
- Search: `force-app/**/flows/<name>.flow-meta.xml`

### Explanation Format
```
## What this flow does
[One paragraph plain-English summary]

## Trigger
[Type, object, trigger event, entry criteria]

## Execution steps (in order)
1. [Element name]: [What it does]
2. [Decision: Outcome A → ..., Outcome B → ...]
3. [Loop: iterates over X, does Y per iteration]
...

## Data accessed
[Objects and fields queried or updated]

## Side effects
[Records created/updated/deleted, emails sent, Apex called, events published]

## Error handling
[Fault path behavior]
```

---

## Examples

```
/flow --new
/flow --new Record-triggered flow on Account that updates contact industry when account industry changes
/flow --new Screen flow to capture and validate case details before creating a case record
/flow --review Account_UpdateContactIndustry_RAF
/flow --review force-app/main/default/flows/Account_SyncToERP_RAF.flow-meta.xml
/flow --refine Account_UpdateContactIndustry_RAF add fault path that creates an error log record
/flow --explain Case_EscalationNotification_RAF
```
