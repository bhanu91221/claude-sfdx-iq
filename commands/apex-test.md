---
description: Create or improve Apex test classes with coverage targeting and Salesforce best practices
argument-hint: "[--coverage [target%] | --bulk | --mock] [ClassName.cls or path]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# /apex-test

Create a new Apex test class, or improve coverage for an existing one, following Salesforce best practices.

## Usage

```
/apex-test MyClass.cls                  Find or create test class for MyClass
/apex-test --coverage MyClass.cls       Show current coverage + improve to 90%
/apex-test --coverage MyClass.cls 80%  Improve to specific target coverage level
/apex-test --bulk MyClass.cls          Focus on bulk (200+ record) test scenarios
/apex-test --mock MyClass.cls          Add HttpCalloutMock for all callout methods
```

---

## Workflow

### Step 1: Identify Target Class

- If a file path or class name is given, use that
- If none given, check `git diff --name-only HEAD` for changed `.cls` files (non-test)
- If no changed files, ask: "Which class would you like me to write tests for?"

### Step 2: Read Source + Find Existing Tests

1. Read the source class fully — understand all public methods, logic branches, error paths
2. Search for existing test class: `<ClassName>Test.cls` in `force-app/**/classes/`
3. If test class exists: read it and identify untested paths
4. If no test class: create from scratch

### Step 3: Analyze Coverage Gaps

For each public method in the source class:
- Identify: happy path, bulk path (200 records), null/empty input, negative/error path
- Check existing tests — which paths are already covered?
- For `--coverage`: note current % and identify the highest-impact untested lines

### Step 4: Generate / Improve Tests

**Test class standards:**

```apex
@isTest
private class AccountServiceTest {

    @TestSetup
    static void setup() {
        // Always use TestDataFactory for test data — never inline record creation
        List<Account> accounts = TestDataFactory.createAccounts(200, 'Test Corp');
        insert accounts;
    }

    @isTest
    static void testProcessAccounts_happyPath() {
        List<Account> accounts = [SELECT Id, Industry FROM Account LIMIT 10];
        
        Test.startTest();
        AccountService.processAccounts(new Map<Id, Account>(accounts).keySet());
        Test.stopTest();
        
        // Assert expected outcome
        List<Account> updated = [SELECT Id, Status__c FROM Account WHERE Id IN :accounts];
        for (Account acc : updated) {
            Assert.areEqual('Active', acc.Status__c, 'Status should be Active after processing');
        }
    }

    @isTest
    static void testProcessAccounts_bulk() {
        // Bulk test — always test with 200 records
        List<Account> accounts = [SELECT Id FROM Account]; // setup created 200
        Assert.areEqual(200, accounts.size(), 'Setup should create 200 accounts');
        
        Test.startTest();
        AccountService.processAccounts(new Map<Id, Account>(accounts).keySet());
        Test.stopTest();
        
        // Verify all 200 processed
        Integer processed = [SELECT COUNT() FROM Account WHERE Status__c = 'Active'];
        Assert.areEqual(200, processed, 'All 200 accounts should be processed');
    }

    @isTest
    static void testProcessAccounts_emptyInput() {
        Test.startTest();
        AccountService.processAccounts(new Set<Id>()); // Should not throw
        Test.stopTest();
        // No exception = pass
    }

    @isTest
    static void testProcessAccounts_nullInput() {
        Test.startTest();
        try {
            AccountService.processAccounts(null);
            Assert.fail('Should throw for null input');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('null'), 'Error message should mention null');
        }
        Test.stopTest();
    }
}
```

**Required test patterns:**

| Pattern | When to Apply |
|---------|--------------|
| `@TestSetup` | Always — shared test data setup |
| `TestDataFactory` | Always — never inline `new Account(Name='Test')` |
| `Test.startTest()` / `Test.stopTest()` | Always — resets governor limit counters for the unit under test |
| Bulk test with 200+ records | Always — one test per class minimum |
| `System.runAs(user)` | When testing sharing rules, field-level security, or user-context behavior |
| `HttpCalloutMock` | When class contains `Http.send()` or callout Queueable |
| `Assert.areEqual()` / `Assert.isTrue()` | Use Assert class (v56.0+), not `System.assertEquals` |

### Step 5: TestDataFactory Pattern

If `TestDataFactory.cls` exists, use it. If not, offer to create it:

```apex
@isTest
public class TestDataFactory {

    public static List<Account> createAccounts(Integer count, String namePrefix) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = namePrefix + ' ' + i,
                Industry = 'Technology',
                BillingCity = 'San Francisco'
            ));
        }
        return accounts;
    }

    public static User createUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        return new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@example.com'
        );
    }
}
```

### Step 6: HttpCalloutMock (for --mock flag or callout classes)

```apex
@isTest
global class MockHttpCallout implements HttpCalloutMock {
    private Integer statusCode;
    private String body;

    global MockHttpCallout(Integer statusCode, String body) {
        this.statusCode = statusCode;
        this.body = body;
    }

    global HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setBody(body);
        res.setHeader('Content-Type', 'application/json');
        return res;
    }
}

// Usage in test method:
// Test.setMock(HttpCalloutMock.class, new MockHttpCallout(200, '{"status":"ok"}'));
```

### Step 7: Run Tests + Show Coverage

After generating test class, run tests and show coverage:

```bash
# Run test class
sf apex run test --class-names <ClassNameTest> --target-org <org> --result-format human --code-coverage

# Get specific method coverage
sf apex get test --test-run-id <id> --target-org <org> --code-coverage

# Check org-wide coverage
sf apex run test --target-org <org> --result-format human --code-coverage --test-level RunLocalTests
```

For `--coverage` flag: show before/after:
```
Coverage improved:
  AccountService.cls: 45% → 91%  ✅ (target: 90%)
  Lines added: 23 test assertions covering processAccounts() edge cases
```

---

## Standards Summary

- **Target**: 90%+ coverage (minimum 75% for Salesforce deployment)
- **Test data**: Always via `TestDataFactory` — no inline record creation
- **Bulk test**: 200 records minimum in at least one test method
- **Governor limits**: `Test.startTest()`/`Test.stopTest()` always wraps the unit under test
- **Sharing tests**: `System.runAs(user)` for any sharing-sensitive code
- **Callout tests**: `Test.setMock()` before `Test.startTest()` for any class with callouts
- **Assertions**: Use `Assert.areEqual()`, `Assert.isTrue()`, `Assert.fail()` (v56.0+)
- **No `SeeAllData=true`** — always insert your own test data

---

## Examples

```
/apex-test AccountService.cls
/apex-test --coverage AccountService.cls
/apex-test --coverage AccountService.cls 85%
/apex-test --bulk AccountTriggerHandler.cls
/apex-test --mock ExternalApiService.cls
/apex-test force-app/main/default/classes/OpportunityService.cls
```
