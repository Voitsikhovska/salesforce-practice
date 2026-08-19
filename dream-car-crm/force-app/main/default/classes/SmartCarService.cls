public with sharing class SmartCarService {

    private static final String NAMED_CREDENTIAL = 'callout:SmartCar_API';
    private static final String API_VERSION = 'v3';

    public class SmartCarServiceException extends Exception {}

    @AuraEnabled
    public static SmartCarVehicleWrapper getVehicleInfo(String vehicleId, String scUserId) {
        validateVehicleId(vehicleId);
        validateUserId(scUserId);

        String endpoint = NAMED_CREDENTIAL + '/' + API_VERSION + '/vehicles/' + EncodingUtil.urlEncode(vehicleId, 'UTF-8');

        HttpResponse res = makeCallout(endpoint, 'GET', scUserId);

        return SmartCarVehicleWrapper.parseVehicleInfo(res);
    }

    @AuraEnabled
    public static SmartCarVehicleWrapper getVehicleLocation(String vehicleId, String scUserId) {
        validateVehicleId(vehicleId);
        validateUserId(scUserId);

        String endpoint = NAMED_CREDENTIAL + '/' + API_VERSION + '/vehicles/' + EncodingUtil.urlEncode(vehicleId, 'UTF-8') + '/signals';

        HttpResponse res = makeCallout(endpoint, 'GET', scUserId);

        return SmartCarVehicleWrapper.parseVehicleLocation(res);
    }

    private static void validateVehicleId(String vehicleId) {
        if (String.isBlank(vehicleId)) {
            throw new SmartCarServiceException('Vehicle Id is required.');
        }
    }

    private static void validateUserId(String scUserId) {
        if (String.isBlank(scUserId)) {
            throw new SmartCarServiceException('SmartCar User Id is required. This is obtained once per user via SmartCar Connect.');
        }
    }

    private static HttpResponse makeCallout(String endpoint, String method, String scUserId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('sc-user-id', scUserId);
        req.setTimeout(20000);

        HttpResponse res;
        try {
            res = http.send(req);
        } catch (System.CalloutException ce) {
            logError('Callout failure: ' + ce.getMessage(), endpoint);
            throw new SmartCarServiceException('Unable to reach SmartCar API. Please try again later.');
        }

        if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
            return res;
        }

        logError('SmartCar API returned ' + res.getStatusCode() + ': ' + res.getBody(), endpoint);
        throw new SmartCarServiceException(mapErrorMessage(res.getStatusCode()));
    }

    private static String mapErrorMessage(Integer statusCode) {
        switch on statusCode {
            when 400 {
                return 'The request to SmartCar was invalid.';
            }
            when 401 {
                return 'Authentication with SmartCar failed. Please check the Named Credential configuration.';
            }
            when 403 {
                return 'Access to this vehicle is not authorized.';
            }
            when 404 {
                return 'Vehicle not found.';
            }
            when 429 {
                return 'Too many requests to SmartCar API. Please try again shortly.';
            }
            when else {
                return 'An unexpected error occurred while contacting SmartCar.';
            }
        }
    }

    private static void logError(String message, String endpoint) {
        System.debug(LoggingLevel.ERROR, 'SmartCarService Error: ' + message + ' | Endpoint: ' + endpoint);
    }
}