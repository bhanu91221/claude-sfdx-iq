public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private List<String> recordIds;
    private String operation;

    public AccountSyncQueueable(List<String> recordIds, String operation) {
        this.recordIds = recordIds;
        this.operation = operation;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [
            SELECT Id, Name, Industry, BillingStreet, BillingCity, BillingState
            FROM Account WHERE Id IN :recordIds
        ];

        for (Account acc : accounts) {
            try {
                HttpResponse res = ExternalApiService.callApi(
                    '/accounts/' + acc.Id,
                    this.operation == 'CREATE' ? 'POST' : 'PATCH',
                    JSON.serialize(acc)
                );
                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    acc.Sync_Status__c = 'Synced';
                    acc.Last_Sync_Date__c = DateTime.now();
                } else {
                    acc.Sync_Status__c = 'Error';
                    acc.Sync_Error__c = 'HTTP ' + res.getStatusCode();
                }
            } catch (Exception e) {
                acc.Sync_Status__c = 'Error';
                acc.Sync_Error__c = e.getMessage();
            }
        }

        update accounts;
    }
}
