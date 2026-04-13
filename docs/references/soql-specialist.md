# SOQL Specialist Reference

Reference document for the `apex-code-reviewer` agent. Consult this when reviewing complex SOQL scenarios: large data volumes (LDV), query selectivity, dynamic SOQL safety, or aggregate queries.

## Query Selectivity & Indexing

**Selective filters** (use an index — preferred):
- `WHERE Id = :someId` or `WHERE Id IN :idSet` — always indexed
- Standard indexed fields: `OwnerId`, `CreatedDate`, `LastModifiedDate`, `RecordTypeId`, `Name` (on most objects), master-detail relationship fields
- Custom fields with custom index configured in org

**Non-selective filters** (flag as HIGH risk on large objects):
- Custom text fields without custom index: `WHERE Custom_Text__c = :val`
- Negative operators: `WHERE Status__c != 'Closed'`
- Leading wildcards: `WHERE Name LIKE '%Corp'` (cannot use index)
- Null checks on non-indexed fields: `WHERE Custom_Field__c = null`
- OR conditions mixing indexed and non-indexed fields

**Rule of thumb:** A query is selective if it returns < 10% of records (or < 200K records on objects with > 2M records). Non-selective queries on large objects cause full table scans and will hit `SOQL query row limit exceeded` or timeout.

## Large Data Volume (LDV) Patterns

**Avoid on objects with >100K records:**
- `WHERE` on custom fields without custom indexes
- `ORDER BY` on non-indexed fields (sorts entire dataset)
- `OFFSET` pagination (full scan to each offset)

**LDV-safe patterns:**
```apex
// Keyset pagination instead of OFFSET
List<Account> page1 = [SELECT Id, Name, CreatedDate FROM Account ORDER BY Id LIMIT 200];
Id lastId = page1[page1.size()-1].Id;
List<Account> page2 = [SELECT Id, Name FROM Account WHERE Id > :lastId ORDER BY Id LIMIT 200];

// Use QueryLocator in Batch for LDV — not heap-based queries
global Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator('SELECT Id FROM Account WHERE Industry = \'Technology\'');
}

// Skinny tables: for frequently queried fields on high-volume objects,
// request Salesforce Support to create a skinny table (custom index + denormalized subset)
```

## Query Plan Analysis

When `System.debug([EXPLAIN query])` or SOQL Query Plan tool is available:
- **TableScan** cost > 0.5 is a warning; > 0.9 is critical
- **Index** cost < 0.3 is good
- **Cost** = estimated fraction of table scanned (0 = perfect index use, 1 = full scan)

Flag any production query with `TableScan` on objects you know have > 50K records.

## Dynamic SOQL Safety

**Injection risk patterns:**
```apex
// CRITICAL — never do this
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';

// SAFE — bind variables
String name = userInput;
List<Account> accounts = [SELECT Id FROM Account WHERE Name = :name];

// SAFE — queryWithBinds (API v57.0+) for fully dynamic fields
Map<String, Object> binds = new Map<String, Object>{'name' => userInput};
List<Account> accounts = Database.queryWithBinds(
    'SELECT Id FROM Account WHERE Name = :name', binds, AccessLevel.USER_MODE);

// ACCEPTABLE — escapeSingleQuotes for legacy dynamic SOQL
String safeInput = String.escapeSingleQuotes(userInput);
```

**When reviewing dynamic SOQL:**
1. Check if `Database.query()` uses string concatenation with any variable
2. Ensure all user-controlled values go through bind variables or `escapeSingleQuotes()`
3. Prefer `Database.queryWithBinds()` for new code — it binds at the SOQL level

## Aggregate Queries

```apex
// COUNT with GROUP BY
List<AggregateResult> results = [
    SELECT Industry, COUNT(Id) cnt
    FROM Account
    WHERE Industry != null
    GROUP BY Industry
    HAVING COUNT(Id) > 10
    ORDER BY COUNT(Id) DESC
    LIMIT 50
];
for (AggregateResult ar : results) {
    String industry = (String) ar.get('Industry');
    Integer count = (Integer) ar.get('cnt');
}

// Aggregate queries return AggregateResult — not SObject lists
// LIMIT in aggregate queries applies to number of groups, not records
// Aggregate queries count against SOQL limit (1 query per SELECT)
```

## SOQL Anti-Patterns

| Anti-Pattern | Risk | Fix |
|-------------|------|-----|
| SOQL in loop | Governor limit violation | Move query before loop, use Map |
| SELECT * equivalent (SELECT Id, ...) with 50+ fields | Heap bloat | Select only needed fields |
| Missing LIMIT on unbounded query | Heap + row limit risk | Add LIMIT unless in Batch start() |
| OFFSET > 2000 on large objects | Full table scan | Use keyset pagination |
| Filtering on formula fields | Formula fields are not indexed | Filter on underlying fields |
| `LIKE '%value'` (leading wildcard) | Cannot use index | Redesign or use custom search |
| Non-selective filter on custom object > 100K | Full table scan | Add custom index or redesign |
| Dynamic SOQL with string concatenation | SOQL injection | Use bind variables |

## SOQL in Test Classes

- `@isTest` classes: use `[SELECT ... FROM ... LIMIT 1]` for setup verification
- Never use `SeeAllData=true` — always insert test data
- Use `Test.startTest()`/`Test.stopTest()` to get fresh governor limits for the unit being tested
- Mock `Database.queryWithBinds()` results using `Test.setFixedSearchResults()` if needed

## Field Security in SOQL

```apex
// WITH USER_MODE — enforces FLS + object access at query time (throws on violation)
List<Account> accounts = [SELECT Id, Name, AnnualRevenue FROM Account WITH USER_MODE LIMIT 10];

// WITH SECURITY_ENFORCED — same but strips inaccessible fields instead of throwing
List<Account> accounts = [SELECT Id, Name, AnnualRevenue FROM Account WITH SECURITY_ENFORCED LIMIT 10];

// Security.stripInaccessible — for DML (insert/update) with user-supplied data
SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, queryResults);
List<Account> safe = (List<Account>) decision.getRecords();
```

Prefer `WITH USER_MODE` for `@AuraEnabled` controller queries — it throws a clear error if FLS is violated, which is easier to debug than silently stripped fields.
