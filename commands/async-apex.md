---
description: Create, refine, or debug async Apex (Batch, Queueable, Schedulable, Future methods)
argument-hint: "[--new | --refine | --bug-fix] [ClassName or path]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# /async-apex

Work with asynchronous Apex patterns using `--new`, `--refine`, or `--bug-fix`.

## Usage

```
/async-apex --new          Create a new async Apex class (Batch, Queueable, Schedulable, or Future)
/async-apex --refine       Modify an existing async class
/async-apex --bug-fix      Diagnose and fix a bug in async Apex code
```

---

## --new: Create a New Async Class

### Gather Requirements
Ask the user:
1. What type? (Batch, Queueable, Schedulable, or @future method)
2. What does it process? (object, business operation)
3. What's the estimated data volume? (helps choose batch size)
4. Does it need to make HTTP callouts?
5. Should it chain to another async job after completion?

### Choosing the Right Pattern

| Pattern | Use When |
|---------|----------|
| **Batch Apex** | Processing large volumes (1,000+ records), scheduled or on-demand |
| **Queueable** | Single async operation, needs callouts, can chain jobs |
| **Schedulable** | Time-based execution (cron), typically kicks off a Batch |
| **@future** | Legacy simple async — prefer Queueable for new code |

---

### Batch Apex Pattern

```apex
public class AccountSyncBatch implements Database.Batchable<SObject>, Database.Stateful {

    private Integer processedCount = 0;
    private List<String> errors = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Use QueryLocator for large volumes — no LIMIT needed here
        return Database.getQueryLocator([
            SELECT Id, Name, SyncStatus__c
            FROM Account
            WHERE SyncStatus__c = 'Pending'
            ORDER BY CreatedDate ASC
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Each execute() gets a FRESH set of governor limits
        List<Account> toUpdate = new List<Account>();
        for (Account acc : scope) {
            acc.SyncStatus__c = 'Complete';
            toUpdate.add(acc);
        }
        Database.SaveResult[] results = Database.update(toUpdate, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                errors.add(sr.getErrors()[0].getMessage());
            } else {
                processedCount++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Chain next job or send notification
        if (!errors.isEmpty()) {
            // Log or email errors
        }
    }
}

// Execute with default 200 scope
Database.executeBatch(new AccountSyncBatch());
// Execute with custom scope size
Database.executeBatch(new AccountSyncBatch(), 50); // smaller = more SOQL budget per execute
```

**Batch Standards:**
- Implement `Database.Stateful` only if you need state between execute() chunks
- Default scope size is 200 — reduce to 50-100 if each record triggers many sub-queries
- Never use `Database.executeBatch()` inside a loop (max 5 active batch jobs)
- `finish()` is ideal for sending notifications or chaining jobs

---

### Queueable Pattern

```apex
public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Set<Id> accountIds;

    public AccountSyncQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH USER_MODE];

        // Make callout if Database.AllowsCallouts is implemented
        for (Account acc : accounts) {
            ExternalApiService.sync(acc);
        }

        // Chain next job (max 1 chain per execute)
        // System.enqueueJob(new NextQueueable(remainingIds));
    }
}

// Enqueue (max 50 enqueueJob calls per transaction)
System.enqueueJob(new AccountSyncQueueable(accountIdSet));
```

**Queueable Standards:**
- Add `Database.AllowsCallouts` only if HTTP callouts are needed
- Maximum 1 chained job per `execute()` in production (unlimited in tests)
- Maximum 50 `System.enqueueJob()` calls per transaction
- Constructor should accept IDs or simple data — avoid passing large collections

---

### Schedulable Pattern

```apex
public class AccountSyncSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Delegate to Batch for actual processing
        Database.executeBatch(new AccountSyncBatch(), 200);
    }
}

// Schedule via Apex (or Setup > Scheduled Jobs)
String cronExp = '0 0 2 * * ?'; // Daily at 2 AM
System.schedule('Account Sync Daily', cronExp, new AccountSyncSchedulable());
```

---

### @future Pattern (Legacy — Prefer Queueable)

```apex
public class AccountAsyncHelper {

    @future(callout=true)
    public static void syncAccountAsync(Set<Id> accountIds) {
        // Cannot pass SObject collections — use primitive types or Ids
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        ExternalApiService.sync(accounts);
    }
}
```

**@future Limitations:** Cannot chain, cannot monitor, no `Database.AllowsCallouts` needed (use `callout=true` annotation). Use Queueable for anything new.

---

### Async Standards

**Governor Limits (Async Context):**
| Limit | Async Value | Notes |
|-------|-------------|-------|
| SOQL queries | 200 (vs 100 sync) | Per execute() chunk |
| CPU time | 60,000 ms (vs 10,000) | Per execute() chunk |
| Heap size | 12 MB (vs 6 MB) | Per execute() chunk |
| Callouts | 100 | Only with AllowsCallouts |
| Future calls | 0 | Cannot call @future from @future |

**Test Pattern for Async:**
```apex
@IsTest
static void testBatch_processesAllRecords() {
    List<Account> accounts = TestDataFactory.createAccounts(200);
    insert accounts;

    Test.startTest();
    Database.executeBatch(new AccountSyncBatch(), 200);
    Test.stopTest(); // Executes batch synchronously in test context

    List<Account> updated = [SELECT SyncStatus__c FROM Account WHERE Id IN :new Map<Id,Account>(accounts).keySet()];
    for (Account acc : updated) {
        System.assertEquals('Complete', acc.SyncStatus__c, 'All accounts should be synced');
    }
}
```

### Generate Output
Create:
1. `force-app/main/default/classes/<ClassName>.cls` — async implementation
2. `force-app/main/default/classes/<ClassName>.cls-meta.xml`
3. `force-app/main/default/classes/<ClassName>Test.cls` — test class with `Test.startTest()/stopTest()`
4. `force-app/main/default/classes/<ClassName>Test.cls-meta.xml`

---

## --refine: Modify an Existing Async Class

1. Read the class completely before modifying
2. Identify type (Batch/Queueable/Schedulable/future) and current behavior
3. Apply change following the correct pattern for its type
4. Update tests — async tests must always use `Test.startTest()/stopTest()`

---

## --bug-fix: Diagnose and Fix Async Bugs

### Common Async Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Too many SOQL queries` in Batch | Query inside execute() loop | Move SOQL to selector, use Map |
| `Callout not allowed` | Missing `Database.AllowsCallouts` | Add interface or use `@future(callout=true)` |
| `Too many future calls` | `@future` inside a loop | Use Queueable with a collection |
| `Maximum batch jobs` | 5 concurrent batch jobs active | Chain or schedule off-peak |
| Test doesn't execute batch | Missing `Test.stopTest()` | Wrap in `Test.startTest()/stopTest()` |
| State lost between execute() chunks | Missing `Database.Stateful` | Add `implements Database.Stateful` |

### Process
1. Gather: error message, where it occurs (start/execute/finish), data volume
2. Identify root cause from the symptom table above
3. Fix and add regression test

---

## Platform Event-Triggered Async Apex

Platform Events fire their own Apex triggers with a **separate governor limit budget** from standard Apex triggers. Use them for event-driven async processing.

### When to Use Platform Events vs Queueable
| Scenario | Use |
|----------|-----|
| React to Salesforce data changes in real time | Change Data Capture trigger |
| Decouple systems (Salesforce ↔ external or SF ↔ SF) | Platform Event |
| One-off async task from a trigger | Queueable |
| Schedule large batch operations | Batch Apex |

### Platform Event Trigger Pattern

```apex
// Trigger fires on platform event publication
trigger OrderEventTrigger on Order_Event__e (after insert) {
    OrderEventHandler handler = new OrderEventHandler();
    handler.handleEvents(Trigger.new);
}

public class OrderEventHandler {
    public void handleEvents(List<Order_Event__e> events) {
        List<Task> toCreate = new List<Task>();

        for (Order_Event__e event : events) {
            if (event.Action__c == 'CREATED') {
                toCreate.add(new Task(
                    Subject = 'Process Order ' + event.Order_Id__c,
                    WhatId = event.Account_Id__c,
                    Status = 'Not Started'
                ));
            }
        }

        if (!toCreate.isEmpty()) {
            // Use allOrNone=false for resilience — one failure shouldn't block others
            Database.SaveResult[] results = Database.insert(toCreate, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Insert failed: ' + err.getMessage());
                    }
                }
            }
        }

        // REQUIRED for high-volume events: checkpoint prevents reprocessing on failure
        if (!events.isEmpty()) {
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(
                events[events.size() - 1].ReplayId
            );
        }
    }
}
```

### Key Platform Event Rules
- Platform event triggers run **after insert** only — no before context
- Each PE trigger batch has its own 200 DML / 100 SOQL limit (not shared with other triggers)
- Always call `setResumeCheckpoint()` on the last processed event — Salesforce uses this to avoid replaying already-processed events on failure
- Use `Database.insert(list, false)` (allOrNone=false) so one bad record doesn't abort the batch
- To publish from Apex: `EventBus.publish(List<My_Event__e>)` — returns `Database.SaveResult[]`

### Publishing Platform Events

```apex
public class OrderService {
    public static void notifyOrderCreated(List<Order__c> orders) {
        List<Order_Event__e> events = new List<Order_Event__e>();
        for (Order__c order : orders) {
            events.add(new Order_Event__e(
                Order_Id__c = order.Id,
                Action__c = 'CREATED',
                Account_Id__c = order.Account__c
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        // Check results — publish can fail silently
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Failed to publish event for Order ' + orders[i].Id + ': ' +
                    results[i].getErrors()[0].getMessage());
            }
        }
    }
}
```

---

## Examples

```
/async-apex --new
/async-apex --new Batch to sync Account records to external system via REST callout
/async-apex --new Queueable that sends email notifications for closed opportunities
/async-apex --new Platform Event trigger to process order events
/async-apex --refine AccountSyncBatch reduce scope size and add error logging to finish()
/async-apex --bug-fix AccountSyncBatch hitting SOQL limit in execute()
```
