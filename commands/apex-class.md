---
description: Create, review, refine, or debug Apex classes (service, selector, controller, utility, domain)
---

# /apex-class

Work with Salesforce Apex classes across the full development lifecycle using `--new`, `--review`, `--refine`, or `--bug-fix`.

## Usage

```
/apex-class --new          Create a new Apex class + test class
/apex-class --review       Review an existing class for quality, security, governor limits
/apex-class --refine       Modify an existing class (add feature, change behavior)
/apex-class --bug-fix      Diagnose and fix a bug in an existing class
```

---

## --new: Create a New Apex Class

### Gather Requirements
Ask the user:
1. What is the class name and its role? (Service, Selector, Controller, Utility, Domain, Batch — see patterns below)
2. What object(s) does it operate on?
3. What methods are needed? (brief description of each)
4. Any specific patterns? (TriggerHandler framework, Callable, Invocable, etc.)

### Apex Class Patterns

**Service Class** — Business operations
```apex
public with sharing class AccountService {
    public static void processAccounts(List<Id> accountIds) {
        List<Account> accounts = AccountSelector.getById(accountIds);
        // business logic
        update accounts;
    }
}
```

**Selector Class** — Centralized SOQL queries (never in service/domain classes)
```apex
public inherited sharing class AccountSelector {
    public static List<Account> getById(Set<Id> accountIds) {
        return [SELECT Id, Name, Industry, OwnerId
                FROM Account
                WHERE Id IN :accountIds
                WITH USER_MODE];
    }
}
```

**Controller (Apex for LWC)** — `@AuraEnabled` methods only; thin layer
```apex
public with sharing class AccountController {
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(Id ownerId) {
        return AccountSelector.getByOwner(new Set<Id>{ownerId});
    }
}
```

**Domain Class** — Object-specific logic without DML/SOQL
```apex
public with sharing class AccountDomain {
    public static void setDefaultIndustry(List<Account> accounts) {
        for (Account acc : accounts) {
            if (String.isBlank(acc.Industry)) acc.Industry = 'Other';
        }
    }
}
```

### Apex Standards (baked in — no separate loading required)

**Security:**
- All classes must declare `with sharing`, `without sharing`, or `inherited sharing` — never omit
- User-facing controllers: use `WITH USER_MODE` or `WITH SECURITY_ENFORCED` in SOQL
- DML on user-supplied data: use `Security.stripInaccessible()` before insert/update
- Dynamic SOQL: use bind variables or `Database.queryWithBinds()` — never string concatenation

**Bulkification:**
- ALL methods accept `List<SObject>` or `Set<Id>` — never single records
- SOQL queries: always outside loops, using `WHERE Id IN :recordIds`
- DML: collect records into a List, then single DML statement

**SOQL:**
- Minimum field selection — only fetch fields you use
- Always add LIMIT unless in Batch Apex `start()`
- Prefer `WHERE Id IN :idSet` for selective, indexed filtering
- Avoid custom field filters without a custom index on high-volume objects

**Error Handling:**
- No empty catch blocks — always log or rethrow
- Use `Database.insert(records, false)` for partial success when appropriate
- Custom exception classes for domain-specific errors

**Naming:**
- Classes: PascalCase + role suffix (`AccountService`, `AccountSelector`, `AccountController`)
- Methods: camelCase verb phrase (`getAccountsByIndustry`, `submitForApproval`)
- Constants: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`)

**Test Class Standards:**
- Name: `<ClassName>Test`
- `@TestSetup` for data setup
- Test all public methods: happy path + bulk (200 records) + null/empty + negative
- `Test.startTest()` / `Test.stopTest()` around the unit being tested
- Target 90%+ coverage; minimum 75%

### Generate Output
Create both files:
1. `force-app/main/default/classes/<ClassName>.cls` — implementation
2. `force-app/main/default/classes/<ClassName>.cls-meta.xml` — metadata with correct API version
3. `force-app/main/default/classes/<ClassName>Test.cls` — test class
4. `force-app/main/default/classes/<ClassName>Test.cls-meta.xml`

Summarize what was generated: methods created, design decisions made, test scenarios covered.

---

## --review: Review an Existing Class

### Identify Files
- If a file path is given, review that file
- If no argument, check `git diff --name-only HEAD` for changed `.cls` files
- If none found, ask: "Which class would you like me to review?"

### Delegate to apex-code-reviewer agent
Pass the identified files to the **apex-code-reviewer** agent with the full review workflow.

The review covers:
- Naming conventions
- Bulkification (SOQL/DML in loops — CRITICAL)
- SOQL selectivity and N+1 patterns
- Governor limits budget estimation
- Error handling
- Security (sharing keywords, CRUD/FLS, SOQL injection)
- Method size and complexity
- Test coverage

Output: Severity-grouped findings (CRITICAL → HIGH → MEDIUM → LOW) with file:line references and fixes.

---

## --refine: Modify an Existing Class

### Identify Target
- If `--refine <ClassName or path>` provided, use that
- Otherwise, ask: "Which class would you like to modify, and what change do you need?"

### Read and Understand First
- Read the class completely before proposing any changes
- Identify all callers of the method(s) being changed (use Grep)
- Understand test coverage before modifying

### Apply Change
- Make the smallest change that achieves the goal
- Keep the same naming conventions and patterns already used
- If the change adds a new method, add corresponding tests
- If the change modifies behavior, update existing tests
- Announce: what changed, why, and what to verify

---

## --bug-fix: Diagnose and Fix a Bug

### Gather Information
Ask the user:
1. What is the current behavior?
2. What is the expected behavior?
3. In what context does it happen? (trigger, LWC action, batch, API)
4. Any error message or stack trace?

### Diagnose
- Read the class and related classes thoroughly
- Identify the root cause (logic error, null check, governor limit, SOQL, etc.)
- Trace the execution path from entry point to failure

### Fix
- Fix the root cause — not just the symptom
- Add a test that would have caught this bug
- Explain what the bug was, why it happened, and what the fix does

---

## Examples

```
/apex-class --new
/apex-class --new AccountService with getAccountsByIndustry and updateIndustry methods
/apex-class --review
/apex-class --review force-app/main/default/classes/OpportunityService.cls
/apex-class --refine AccountService add a method to bulk-update AnnualRevenue
/apex-class --bug-fix AccountService.processAccounts throws NullPointerException on update
```
