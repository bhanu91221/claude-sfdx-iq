@RestResource(urlMapping='/api/accounts/*')
global with sharing class AccountRestResource {

    @HttpGet
    global static AccountResponse getAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        try {
            Account acc = [SELECT Id, Name, Industry, AnnualRevenue FROM Account WHERE Id = :accountId WITH USER_MODE LIMIT 1];
            return new AccountResponse(true, acc, null);
        } catch (QueryException e) {
            RestContext.response.statusCode = 404;
            return new AccountResponse(false, null, 'Account not found');
        }
    }

    @HttpPost
    global static AccountResponse createAccount() {
        RestRequest req = RestContext.request;
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            Account acc = new Account(Name = (String) body.get('name'), Industry = (String) body.get('industry'));
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Account>{ acc });
            insert decision.getRecords();
            RestContext.response.statusCode = 201;
            return new AccountResponse(true, (Account) decision.getRecords()[0], null);
        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            return new AccountResponse(false, null, e.getMessage());
        }
    }

    @HttpPatch
    global static AccountResponse updateAccount() {
        RestRequest req = RestContext.request;
        String accountId = req.requestURI.substringAfterLast('/');
        try {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            Account acc = new Account(Id = accountId);
            if (body.containsKey('name')) acc.Name = (String) body.get('name');
            if (body.containsKey('industry')) acc.Industry = (String) body.get('industry');
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Account>{ acc });
            update decision.getRecords();
            return new AccountResponse(true, (Account) decision.getRecords()[0], null);
        } catch (Exception e) {
            RestContext.response.statusCode = 400;
            return new AccountResponse(false, null, e.getMessage());
        }
    }

    global class AccountResponse {
        public Boolean success;
        public Account data;
        public String error;
        public AccountResponse(Boolean success, Account data, String error) {
            this.success = success; this.data = data; this.error = error;
        }
    }
}
