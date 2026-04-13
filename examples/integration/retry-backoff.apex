public class RetryableCalloutService implements Queueable, Database.AllowsCallouts {

    private String endpoint;
    private String method;
    private String body;
    private Integer retryCount;
    private Integer maxRetries;
    private Id recordId;

    private static final Integer BASE_DELAY_SECONDS = 1;
    private static final Integer MAX_DELAY_SECONDS = 32;

    public RetryableCalloutService(String endpoint, String method, String body, Id recordId) {
        this(endpoint, method, body, recordId, 0, 5);
    }

    private RetryableCalloutService(String endpoint, String method, String body,
                                     Id recordId, Integer retryCount, Integer maxRetries) {
        this.endpoint = endpoint; this.method = method; this.body = body;
        this.recordId = recordId; this.retryCount = retryCount; this.maxRetries = maxRetries;
    }

    public void execute(QueueableContext context) {
        try {
            HttpResponse res = ExternalApiService.callApi(endpoint, method, body);
            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                updateRecordStatus('Success', null);
            } else if (isRetryable(res.getStatusCode()) && retryCount < maxRetries) {
                scheduleRetry();
            } else {
                updateRecordStatus('Failed', 'HTTP ' + res.getStatusCode() + ': ' + res.getBody());
            }
        } catch (CalloutException e) {
            if (retryCount < maxRetries) { scheduleRetry(); }
            else { updateRecordStatus('Failed', 'Max retries exceeded: ' + e.getMessage()); }
        }
    }

    private Boolean isRetryable(Integer statusCode) {
        return statusCode == 408 || statusCode == 429 || statusCode == 500 ||
               statusCode == 502 || statusCode == 503 || statusCode == 504;
    }

    private void scheduleRetry() {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s (via Queueable chain)
        // Note: Queueable doesn't support true delays; use Schedulable for precise timing
        System.enqueueJob(new RetryableCalloutService(endpoint, method, body, recordId, retryCount + 1, maxRetries));
    }

    private void updateRecordStatus(String status, String errorMsg) {
        insert new Integration_Log__c(
            Record_Id__c = recordId, Status__c = status,
            Error_Message__c = errorMsg, Retry_Count__c = retryCount, Endpoint__c = endpoint
        );
    }
}
