---
description: Explain what Salesforce code does — Apex classes, triggers, LWC components, Flows. Use --deep for cross-file behavioral tracing.
---

# /explain

Produce a human-readable explanation of any Salesforce code artifact. Understands what the code does end-to-end: data sources, user interactions, business logic, side effects, and integration points.

## Usage

```
/explain                          Explain the active/specified file
/explain --apex <file or name>    Explain an Apex class or trigger
/explain --lwc <component name>   Explain an LWC component
/explain --flow <flow name>       Explain a Salesforce Flow
/explain --deep                   Deep behavioral analysis: trace fields, cross-file data flow
```

## Use Cases

- "What does this Apex class do?"
- "Explain this LWC component to me"
- "Walk me through this Flow step by step"
- "What happens when this trigger fires?"
- "Trace how this field gets set — from the UI all the way to the database"
- "What code touches the Opportunity when it closes?"

## Workflow

### Step 1: Identify What to Explain

- If `--apex <path or name>`, search `force-app/**/classes/<name>.cls` or `**/triggers/<name>.trigger`
- If `--lwc <name>`, search `force-app/**/lwc/<name>/` — read `.js`, `.html`, `.css` together
- If `--flow <name>`, search `force-app/**/flows/<name>.flow-meta.xml`
- If no flag, detect the file from context (path provided in the message)
- If nothing provided, ask: "Which file would you like me to explain? You can provide a path, a class name, or a component name."

### Step 2: Read All Related Files

For Apex classes: read the class + related selector classes referenced by name.
For triggers: read the trigger + its handler class + handler's dependencies.
For LWC: read all files in the component directory (`.js`, `.html`, `.css`).
For Flows: read the `.flow-meta.xml` fully.

### Step 3: Apply Domain-Specific Explanation Strategy

**For Apex Classes (`.cls`):**
- Summarize the class role (Service, Selector, Controller, Batch, Utility, etc.)
- Explain each public/global method: inputs → logic → outputs
- Identify SOQL queries: what object, what filters, what's returned
- Identify DML operations: what records are affected
- Note external callouts, platform events, or async jobs triggered
- Highlight security: `with sharing` usage, CRUD/FLS enforcement

**For Triggers (`.trigger`):**
- State which object and which events (before insert, after update, etc.)
- Trace the handler chain: trigger → handler class → service/domain classes
- Explain what happens for each event context
- Identify which fields get assigned or modified and under what conditions
- Note governor limit considerations

**For LWC Components (`.js` / `.html`):**
- Summarize the component's purpose
- Explain the template: what sections are shown, what conditions control visibility
- Explain data sources: `@wire` adapters or Apex methods providing data
- Explain user interactions: what each button/input does, what events fire
- Explain parent/child communication: `@api` properties, CustomEvents emitted/received
- Describe loading, error, and empty states

**For Flows (`.flow-meta.xml`):**
- State the flow type and entry conditions
- Walk through elements in execution order
- Explain each decision, assignment, loop, and DML/SOQL element
- Describe what the flow does to records and its side effects

### Step 4: Deep Analysis (`--deep` flag)

For cross-file behavioral tracing:
- Use Grep to find all classes, triggers, flows that reference the target object/field
- Trace the complete path: what initiates the change → what processes it → what persists it
- Map dependencies: which classes call which, what's the execution chain
- Identify all entry points (trigger, flow, Apex action, REST endpoint) that affect the artifact

Example deep analysis questions this handles:
- "Trace how Opportunity.Stage gets updated to Closed Won"
- "What code runs when an Account is inserted?"
- "Which classes touch the Case object?"

### Step 5: Output Format

```
## What this [class/trigger/component/flow] does

[One paragraph plain-English summary]

## How it works

[Step-by-step explanation with code references (file:line)]

## Key behaviors

- [Specific behavior with its condition]
- [Specific behavior with its condition]

## Data flow

[Entry point → processing → output/side effects]

## Dependencies

- Calls: [Apex classes, components, agents invoked]
- Data: [Objects and fields accessed or modified]
- Events: [Platform events, CustomEvents, LMS channels]
```

For `--deep` additionally include:
```
## Cross-file trace

[Full execution chain from trigger/entry point through all classes]

## All entry points that affect this artifact

| Entry Point | Type | Condition |
|-------------|------|-----------|
```

## Examples

```
/explain --apex AccountService
/explain --apex force-app/main/default/classes/OpportunityService.cls
/explain --apex force-app/main/default/triggers/AccountTrigger.trigger
/explain --lwc accountList
/explain --lwc force-app/main/default/lwc/opportunityTiles/opportunityTiles.js
/explain --flow Account_UpdateContactIndustry_RAF
/explain --apex AccountService --deep
/explain --lwc accountList --deep
```
