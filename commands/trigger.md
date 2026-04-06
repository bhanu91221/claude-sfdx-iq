---
description: Create, review, refine, or debug Salesforce triggers and their handler classes
---

# /trigger

Work with Salesforce triggers and trigger handler classes using `--new`, `--review`, `--refine`, or `--bug-fix`.

## Usage

```
/trigger --new          Create a new trigger + handler + test class
/trigger --review       Review an existing trigger/handler for quality and patterns
/trigger --refine       Modify a trigger or handler (add event context, change logic)
/trigger --bug-fix      Diagnose and fix a bug in a trigger or handler
```

---

## --new: Create a New Trigger + Handler

### Gather Requirements
Ask the user:
1. Which SObject? (e.g., `Account`, `Custom_Object__c`)
2. Which trigger events? (before insert, before update, before delete, after insert, after update, after delete, after undelete — default: all seven)
3. What business logic should the handler implement? (brief description per event)
4. Does a trigger already exist on this object? (warn if yes — one trigger per object)
5. Use a TriggerHandler framework base class? (if the project has one, detect it)

### Check for Existing Triggers
```
Glob: force-app/**/triggers/<ObjectName>Trigger.trigger
```
If found: warn the user about the one-trigger-per-object rule. Offer to add logic to the existing trigger or stop.

### Trigger Standards (baked in)

**One Trigger Per Object:**
- ONLY ONE trigger per SObject — ever
- All logic belongs in the handler class, not in the trigger body
- The trigger body is a single dispatcher call

**Trigger Pattern:**
```apex
// AccountTrigger.trigger — NO logic here
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new AccountTriggerHandler().run();
}
```

**Handler Class Pattern:**
```apex
public with sharing class AccountTriggerHandler {

    // Recursion prevention
    private static Boolean isRunning = false;

    public void run() {
        if (isRunning) return;
        isRunning = true;
        try {
            if (Trigger.isBefore) {
                if (Trigger.isInsert)  beforeInsert(Trigger.new);
                if (Trigger.isUpdate)  beforeUpdate(Trigger.new, Trigger.oldMap);
                if (Trigger.isDelete)  beforeDelete(Trigger.old);
            }
            if (Trigger.isAfter) {
                if (Trigger.isInsert)  afterInsert(Trigger.new);
                if (Trigger.isUpdate)  afterUpdate(Trigger.new, Trigger.oldMap);
                if (Trigger.isDelete)  afterDelete(Trigger.old);
                if (Trigger.isUndelete) afterUndelete(Trigger.new);
            }
        } finally {
            isRunning = false;
        }
    }

    private void beforeInsert(List<Account> newRecords) {
        // Delegate to service or domain class
        AccountDomain.setDefaultIndustry(newRecords);
    }

    private void afterInsert(List<Account> newRecords) {
        // Collect changed records and delegate
        AccountService.syncToExternalSystem(new Map<Id, Account>(newRecords).keySet());
    }

    private void beforeUpdate(List<Account> newRecords, Map<Id, Account> oldMap) { }
    private void afterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) { }
    private void beforeDelete(List<Account> oldRecords) { }
    private void afterDelete(List<Account> oldRecords) { }
    private void afterUndelete(List<Account> newRecords) { }
}
```

**Handler Rules:**
- Handler must declare `with sharing` or `inherited sharing`
- Handler methods accept `List<SObject>` and/or `Map<Id, SObject>` — NEVER `Trigger.new` directly in service logic
- SOQL and DML belong in service/selector classes — not in the handler itself
- Recursion prevention guard in every handler

**Bulkification in Handlers:**
```apex
// GOOD — collect Ids, single query in selector
private void afterInsert(List<Account> newRecords) {
    Set<Id> accountIds = new Map<Id, Account>(newRecords).keySet();
    AccountService.processNewAccounts(accountIds); // service does the SOQL
}

// BAD — SOQL per record
private void afterInsert(List<Account> newRecords) {
    for (Account acc : newRecords) {
        List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id]; // N+1!
    }
}
```

### Generate Output
Create files:
1. `force-app/main/default/triggers/<ObjectName>Trigger.trigger`
2. `force-app/main/default/triggers/<ObjectName>Trigger.trigger-meta.xml`
3. `force-app/main/default/classes/<ObjectName>TriggerHandler.cls`
4. `force-app/main/default/classes/<ObjectName>TriggerHandler.cls-meta.xml`
5. `force-app/main/default/classes/<ObjectName>TriggerHandlerTest.cls` — tests all event contexts
6. `force-app/main/default/classes/<ObjectName>TriggerHandlerTest.cls-meta.xml`

Summarize what was generated: trigger events implemented, logic per event, test scenarios covered.

---

## --review: Review an Existing Trigger and Handler

### Identify Files
- If path provided, review that trigger and its associated handler
- If no argument, check `git diff --name-only HEAD` for changed `.trigger` and related `.cls` files
- If none, ask which trigger to review

### Trigger-Specific Review Checks

**CRITICAL:**
- More than one trigger on the same object (one-trigger-per-object rule)
- Logic directly in trigger body (must delegate to handler)
- SOQL inside loops in handler (N+1 pattern)
- DML inside loops in handler

**HIGH:**
- No recursion prevention in handler
- Handler missing `with sharing` / `inherited sharing`
- Missing event context handling (handler method is empty stub without comment)
- Hardcoded Record Type IDs, Profile IDs, or User IDs

**MEDIUM:**
- Handler directly contains SOQL (should be in Selector class)
- Handler directly contains DML (should be in Service/Unit of Work)
- Missing test for bulk scenario (200 records)
- Trigger events included that are not needed

**Then delegate to apex-code-reviewer agent** for full Apex review (naming, governor limits, error handling, security).

Output: Severity-grouped findings with file:line references.

---

## --refine: Modify a Trigger or Handler

### Common Refinements
- Add a new event context to an existing handler
- Add new field logic to a before-insert/before-update handler
- Extract direct SOQL from handler into a Selector class
- Add recursion prevention to an existing handler

### Process
1. Read the trigger and handler completely
2. Understand the current dispatch pattern
3. Apply the change following the handler pattern (delegate to service/domain)
4. Update the test class for the new behavior

---

## --bug-fix: Diagnose and Fix a Trigger Bug

### Common Trigger Bugs
- Recursive execution (trigger fires on records it just updated)
- Governor limit hit at scale (SOQL/DML in loop)
- Null pointer in `Trigger.oldMap` during insert (oldMap is null on insert)
- Logic executing for wrong event type
- Test fails with "DML not allowed in this context" (callout in trigger without async)

### Process
1. Gather: current behavior, expected behavior, context (insert/update/delete), error message
2. Diagnose: trace from trigger body → handler → service → identify root cause
3. Fix root cause and add a regression test

---

## Examples

```
/trigger --new
/trigger --new Account with before-insert validation and after-insert sync
/trigger --review
/trigger --review force-app/main/default/triggers/AccountTrigger.trigger
/trigger --refine AccountTriggerHandler add after-update logic to set a field when Status__c changes
/trigger --bug-fix AccountTrigger recursion on update causing stack overflow
```
