// Named Credential Architecture (API v60.0+):
//
// External Credential
// ├── Authentication Protocol (OAuth 2.0, JWT, Custom, etc.)
// ├── Principal(s) (Named Principal or Per-User Principal)
// │   └── Authentication Parameters (client_id, client_secret, etc.)
// └── Permission Set Mapping
//
// Named Credential
// ├── URL (endpoint base URL)
// └── External Credential Reference

public class ExternalApiService {

    private static final String NAMED_CREDENTIAL = 'callout:MyExternalService';

    public static HttpResponse callApi(String endpoint, String method, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000); // 30 second timeout

        if (String.isNotBlank(body)) {
            req.setBody(body);
        }

        Http http = new Http();
        return http.send(req);
    }
}
