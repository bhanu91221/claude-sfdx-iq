public class CircuitBreaker {

    public enum State { CLOSED, OPEN, HALF_OPEN }

    public static Boolean isOpen(String serviceName) {
        Circuit_Breaker_State__c state = getState(serviceName);
        if (state == null || state.State__c == 'CLOSED') return false;
        if (state.State__c == 'OPEN') {
            if (DateTime.now() > state.Last_Failure__c.addMinutes((Integer) state.Cooldown_Minutes__c)) {
                state.State__c = 'HALF_OPEN'; update state;
                return false; // Allow one test request
            }
            return true; // Still in cooldown
        }
        return false;
    }

    public static void recordSuccess(String serviceName) {
        Circuit_Breaker_State__c state = getOrCreateState(serviceName);
        state.State__c = 'CLOSED'; state.Failure_Count__c = 0; state.Last_Success__c = DateTime.now();
        update state;
    }

    public static void recordFailure(String serviceName) {
        Circuit_Breaker_State__c state = getOrCreateState(serviceName);
        state.Failure_Count__c = (state.Failure_Count__c == null ? 0 : state.Failure_Count__c) + 1;
        state.Last_Failure__c = DateTime.now();
        Circuit_Breaker_Config__mdt config = Circuit_Breaker_Config__mdt.getInstance(serviceName);
        if (state.Failure_Count__c >= config.Failure_Threshold__c) state.State__c = 'OPEN';
        update state;
    }

    public static HttpResponse makeCallout(String serviceName, HttpRequest req) {
        if (isOpen(serviceName)) {
            throw new CalloutException('Circuit breaker OPEN for: ' + serviceName);
        }
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() < 500) { recordSuccess(serviceName); }
            else { recordFailure(serviceName); }
            return res;
        } catch (CalloutException e) {
            recordFailure(serviceName); throw e;
        }
    }

    private static Circuit_Breaker_State__c getState(String serviceName) {
        List<Circuit_Breaker_State__c> states = [
            SELECT Id, State__c, Failure_Count__c, Last_Failure__c, Last_Success__c, Cooldown_Minutes__c
            FROM Circuit_Breaker_State__c WHERE Service_Name__c = :serviceName LIMIT 1
        ];
        return states.isEmpty() ? null : states[0];
    }

    private static Circuit_Breaker_State__c getOrCreateState(String serviceName) {
        Circuit_Breaker_State__c state = getState(serviceName);
        if (state == null) {
            state = new Circuit_Breaker_State__c(Service_Name__c = serviceName, State__c = 'CLOSED',
                                                  Failure_Count__c = 0, Cooldown_Minutes__c = 5);
            insert state;
        }
        return state;
    }
}
