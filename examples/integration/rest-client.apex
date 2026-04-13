public class RestApiClient {

    public static final Integer DEFAULT_TIMEOUT = 30000;

    public static Map<String, Object> doGet(String endpoint) {
        HttpRequest req = buildRequest(endpoint, 'GET', null);
        HttpResponse res = sendRequest(req);
        return parseResponse(res);
    }

    public static Map<String, Object> doPost(String endpoint, Map<String, Object> payload) {
        HttpRequest req = buildRequest(endpoint, 'POST', JSON.serialize(payload));
        HttpResponse res = sendRequest(req);
        return parseResponse(res);
    }

    public static Map<String, Object> doPatch(String endpoint, Map<String, Object> payload) {
        HttpRequest req = buildRequest(endpoint, 'PATCH', JSON.serialize(payload));
        HttpResponse res = sendRequest(req);
        return parseResponse(res);
    }

    private static HttpRequest buildRequest(String endpoint, String method, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(DEFAULT_TIMEOUT);
        if (String.isNotBlank(body)) { req.setBody(body); }
        return req;
    }

    private static HttpResponse sendRequest(HttpRequest req) {
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() >= 400) {
            throw new CalloutException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
        }
        return res;
    }

    private static Map<String, Object> parseResponse(HttpResponse res) {
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }
}
