---
description: Create, refine, or debug Salesforce integration Apex (REST/SOAP callouts, inbound REST/SOAP services)
---

# /integration-apex

Work with Salesforce integration code — outbound callouts (REST/SOAP) and inbound web services — using `--new`, `--refine`, or `--bug-fix`.

## Usage

```
/integration-apex --new          Create new integration Apex (callout class or inbound service)
/integration-apex --refine       Modify an existing integration class
/integration-apex --bug-fix      Diagnose and fix a bug in integration code
```

---

## --new: Create New Integration Apex

### Gather Requirements
Ask the user:
1. Direction? Outbound callout (Salesforce calls external) or Inbound service (external calls Salesforce)?
2. Protocol? REST or SOAP?
3. Authentication method? OAuth 2.0, API Key, JWT, Named Credential?
4. What operation? (sync account data, retrieve order status, POST event, etc.)
5. Does it need retry logic? Circuit breaker?
6. Synchronous or asynchronous execution context?

---

### Outbound REST Callout Pattern

```apex
public with sharing class ExternalApiService {

    private static final String NAMED_CREDENTIAL = 'ExternalApi'; // Always use Named Credentials

    public static ExternalApiResponse syncAccount(Id accountId) {
        Account acc = [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NAMED_CREDENTIAL + '/api/v1/accounts');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setBody(JSON.serialize(new AccountPayload(acc)));
        req.setTimeout(30000); // 30 second timeout

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            return (ExternalApiResponse) JSON.deserialize(res.getBody(), ExternalApiResponse.class);
        } else {
            throw new IntegrationException('API call failed: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }

    public class AccountPayload {
        public String name;
        public String industry;
        public AccountPayload(Account acc) {
            this.name = acc.Name;
            this.industry = acc.Industry;
        }
    }

    public class ExternalApiResponse {
        public String id;
        public String status;
    }

    public class IntegrationException extends Exception {}
}
```

**Callout Standards:**
- **Always use Named Credentials** — never hardcode endpoints, API keys, or credentials in Apex
- Named Credential syntax: `callout:<Named_Credential_Name>/path`
- Set `setTimeout()` — default is 10s; max is 120s
- Parse response body as typed class, not untyped Map when possible
- Callouts NOT allowed in trigger context — use Queueable with `Database.AllowsCallouts`

---

### Retry with Exponential Backoff

```apex
public static HttpResponse callWithRetry(HttpRequest req, Integer maxRetries) {
    Integer attempt = 0;
    Integer waitMs = 1000; // Start with 1 second

    while (attempt < maxRetries) {
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() < 500) return res; // Don't retry client errors
            attempt++;
            if (attempt < maxRetries) {
                // Note: System.sleep not available in Apex — use Queueable chaining for real backoff
                waitMs *= 2; // Exponential: 1s, 2s, 4s...
            }
        } catch (System.CalloutException e) {
            attempt++;
            if (attempt >= maxRetries) throw e;
        }
    }
    throw new IntegrationException('Max retries exceeded');
}
```

---

### Outbound SOAP Callout

```apex
// Generate from WSDL: Setup > Apex Classes > Generate from WSDL
// Then use the generated stub:
public with sharing class SoapIntegrationService {
    public static void syncRecord(Id recordId) {
        ExternalSoapService.SoapServicePort stub = new ExternalSoapService.SoapServicePort();
        // Named credential for auth:
        stub.endpoint_x = 'callout:ExternalSoapNC';
        ExternalSoapService.SyncResult result = stub.syncRecord(recordId);
        // handle result
    }
}
```

---

### Inbound REST Service

```apex
@RestResource(urlMapping='/accounts/*')
global with sharing class AccountRestService {

    @HttpGet
    global static AccountResponse doGet() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');

        if (String.isBlank(accountId)) {
            RestContext.response.statusCode = 400;
            return null;
        }

        List<Account> accounts = [SELECT Id, Name, Industry FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
        if (accounts.isEmpty()) {
            RestContext.response.statusCode = 404;
            return null;
        }
        return new AccountResponse(accounts[0]);
    }

    @HttpPost
    global static Id doPost(String name, String industry) {
        Account acc = new Account(Name = name, Industry = industry);
        insert as user acc; // Enforces CRUD
        return acc.Id;
    }

    global class AccountResponse {
        public String id;
        public String name;
        public String industry;
        public AccountResponse(Account acc) {
            this.id = acc.Id;
            this.name = acc.Name;
            this.industry = acc.Industry;
        }
    }
}
```

**Inbound REST Standards:**
- Class: `global with sharing`
- Use `WITH USER_MODE` or `insert as user` for CRUD/FLS enforcement
- Validate all inputs — return appropriate HTTP status codes (400, 404, 500)
- Never expose internal stack traces in error responses
- Authenticate callers using Connected App + OAuth or certificates

---

### Inbound SOAP Service

```apex
global with sharing class AccountSoapService {

    WebService static Id createAccount(String name, String industry) {
        Account acc = new Account(Name = name, Industry = industry);
        insert as user acc;
        return acc.Id;
    }
}
// Generate WSDL: Setup > Apex Classes > <ClassName> > Generate WSDL
```

---

### Integration Standards

**Named Credentials — Architecture:**
```
External Credential (authentication method)
├── OAuth 2.0 client credentials: client_id + client_secret
├── JWT: private key + audience
└── Named Principal or Per-User principal

Named Credential (endpoint + auth reference)
└── callout:<NamedCredential>/path/to/resource
```

**Security:**
- Named Credentials only — no hardcoded URLs, API keys, or passwords
- `global` classes only where inbound SOAP/REST requires it
- Always use `with sharing` or `WITH USER_MODE`
- Validate and sanitize all inbound parameters

**Platform Events (Alternative to Direct Callouts):**
```apex
// Publish event from trigger (no callout limit)
ExternalSync__e event = new ExternalSync__e(
    AccountId__c = acc.Id,
    Operation__c = 'SYNC'
);
EventBus.publish(event);
// Subscriber (e.g., Flow or Apex trigger on event) handles async callout
```

**Test Pattern for Callouts:**
```apex
@IsTest
static void testSyncAccount_success() {
    Test.setMock(HttpCalloutMock.class, new MockHttpSuccess());
    Test.startTest();
    ExternalApiService.syncAccount(someAccountId);
    Test.stopTest();
    // Assert side effects
}

@IsTest
global class MockHttpSuccess implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setBody('{"id":"ext-123","status":"synced"}');
        res.setHeader('Content-Type', 'application/json');
        return res;
    }
}
```

### Generate Output
Create:
1. `force-app/main/default/classes/<ServiceName>.cls` — integration class
2. `force-app/main/default/classes/<ServiceName>.cls-meta.xml`
3. `force-app/main/default/classes/<ServiceName>Test.cls` — tests with `HttpCalloutMock`
4. `force-app/main/default/classes/<ServiceName>Test.cls-meta.xml`
5. Note any Named Credentials that need to be created in the target org

---

## --refine: Modify an Existing Integration Class

1. Read the class completely
2. Understand the Named Credential it uses and the auth pattern
3. Apply the change (add endpoint, change payload, add retry logic)
4. Update the mock and test class to cover the new behavior

---

## --bug-fix: Diagnose and Fix Integration Bugs

### Common Integration Issues

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `Callout not allowed` | Callout in trigger or after DML | Move to Queueable with `Database.AllowsCallouts` |
| `Unauthorized (401)` | Named Credential misconfigured | Verify credential in Setup, check token expiry |
| `Read timed out` | `setTimeout()` too short or service slow | Increase timeout, add retry logic |
| `JSON deserialization error` | Response format changed | Log raw response, update response class |
| `Too many callouts (100)` | Callout in a loop | Collect IDs, make one batched API call |
| `UNABLE_TO_LOCK_ROW` in test | Concurrent DML in test | Use `@TestSetup` isolation |

### Process
1. Gather: error message, HTTP status code if available, which endpoint
2. Diagnose using symptom table
3. Fix and add regression test covering the failure scenario

---

## Examples

```
/integration-apex --new
/integration-apex --new REST callout to sync Account records to Salesforce external API
/integration-apex --new inbound REST service to receive webhook events from payment provider
/integration-apex --refine ExternalApiService add retry with exponential backoff
/integration-apex --bug-fix ExternalApiService throwing CalloutException after DML in trigger
```
