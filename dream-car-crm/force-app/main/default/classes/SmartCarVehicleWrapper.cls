public with sharing class SmartCarVehicleWrapper {

    @AuraEnabled public String vehicleId;
    @AuraEnabled public String make;
    @AuraEnabled public String model;
    @AuraEnabled public Integer year;
    @AuraEnabled public String powertrainType;

    @AuraEnabled public Double latitude;
    @AuraEnabled public Double longitude;

    @AuraEnabled public Boolean isSuccess;
    @AuraEnabled public String errorMessage;

    public static SmartCarVehicleWrapper parseVehicleInfo(HttpResponse res) {

        SmartCarVehicleWrapper wrapper = new SmartCarVehicleWrapper();

        try {

            String rawBody = res.getBody();

            Map<String, Object> root =
                (Map<String, Object>) JSON.deserializeUntyped(rawBody);

            if (root == null || !root.containsKey('data')) {
                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'SmartCar response does not contain vehicle data.';
                return wrapper;
            }

            Map<String, Object> data =
                (Map<String, Object>) root.get('data');

            if (data == null) {
                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'SmartCar returned empty vehicle data.';
                return wrapper;
            }

            if (data.containsKey('id') && data.get('id') != null) {
                wrapper.vehicleId =
                    String.valueOf(data.get('id'));
            }

            if (!data.containsKey('attributes') ||
                !(data.get('attributes') instanceof Map<String, Object>)) {

                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'SmartCar response does not contain vehicle attributes.';
                return wrapper;
            }

            Map<String, Object> attributes =
                (Map<String, Object>) data.get('attributes');

            if (attributes.containsKey('make') &&
                attributes.get('make') != null) {

                wrapper.make =
                    String.valueOf(attributes.get('make'));
            }

            if (attributes.containsKey('model') &&
                attributes.get('model') != null) {

                wrapper.model =
                    String.valueOf(attributes.get('model'));
            }

            if (attributes.containsKey('year') &&
                attributes.get('year') != null) {

                wrapper.year =
                    Integer.valueOf(
                        String.valueOf(attributes.get('year'))
                    );
            }

            if (attributes.containsKey('powertrainType') &&
                attributes.get('powertrainType') != null) {

                wrapper.powertrainType =
                    String.valueOf(attributes.get('powertrainType'));
            }

            wrapper.isSuccess = true;

        } catch (Exception e) {

            wrapper.isSuccess = false;

            wrapper.errorMessage =
                'Unable to parse SmartCar vehicle information: ' +
                e.getMessage();
        }

        return wrapper;
    }

    public static SmartCarVehicleWrapper parseVehicleLocation(HttpResponse res) {

        SmartCarVehicleWrapper wrapper =
            new SmartCarVehicleWrapper();

        try {

            String rawBody = res.getBody();

            Map<String, Object> root =
                (Map<String, Object>) JSON.deserializeUntyped(rawBody);

            if (root == null || !root.containsKey('data')) {

                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'SmartCar response does not contain signal data.';

                return wrapper;
            }

            Object dataObject = root.get('data');

            if (!(dataObject instanceof List<Object>)) {

                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'SmartCar signal response has an unexpected format.';

                return wrapper;
            }

            List<Object> signals =
                (List<Object>) dataObject;

            if (signals == null || signals.isEmpty()) {

                wrapper.isSuccess = false;
                wrapper.errorMessage =
                    'This vehicle has no signals available yet. ' +
                    'In the SmartCar Simulator, open this vehicle and ' +
                    'set a Location signal value, then try again. ' +
                    'Raw response: ' +
                    truncate(rawBody);

                return wrapper;
            }

            for (Object signalObj : signals) {

                if (!(signalObj instanceof Map<String, Object>)) {
                    continue;
                }

                Map<String, Object> signal =
                    (Map<String, Object>) signalObj;

                if (!signal.containsKey('attributes') ||
                    !(signal.get('attributes')
                        instanceof Map<String, Object>)) {

                    continue;
                }

                Map<String, Object> attributes =
                    (Map<String, Object>) signal.get('attributes');

                String code = null;
                String name = null;
                String group1 = null;

                if (attributes.containsKey('code') &&
                    attributes.get('code') != null) {

                    code = String.valueOf(attributes.get('code'));
                }

                if (attributes.containsKey('name') &&
                    attributes.get('name') != null) {

                    name = String.valueOf(attributes.get('name'));
                }

                if (attributes.containsKey('group1') &&
                    attributes.get('group1') != null) {

                    group1 = String.valueOf(attributes.get('group1'));
                }


                Boolean isLocationSignal =
                    (group1 != null &&
                     group1.equalsIgnoreCase('Location')) ||

                    (code != null &&
                     code.toLowerCase().contains('location')) ||

                    (name != null &&
                     name.equalsIgnoreCase('PreciseLocation'));


                if (!isLocationSignal) {
                    continue;
                }


                if (!attributes.containsKey('body') ||
                    !(attributes.get('body')
                        instanceof Map<String, Object>)) {

                    continue;
                }

                Map<String, Object> body =
                    (Map<String, Object>) attributes.get('body');


                if (!body.containsKey('latitude') ||
                    !body.containsKey('longitude')) {

                    continue;
                }


                Object latValue = body.get('latitude');
                Object lngValue = body.get('longitude');


                if (latValue == null || lngValue == null) {
                    continue;
                }


                Double latitude =
                    parseDoubleSafe(String.valueOf(latValue));

                Double longitude =
                    parseDoubleSafe(String.valueOf(lngValue));


                if (latitude == null || longitude == null) {
                    continue;
                }


                wrapper.latitude = latitude;
                wrapper.longitude = longitude;
                wrapper.isSuccess = true;

                return wrapper;
            }

            wrapper.isSuccess = false;

            wrapper.errorMessage =
                'No precise Location signal with latitude and ' +
                'longitude was found for this vehicle. ' +
                'Raw response: ' +
                truncate(rawBody);

        } catch (Exception e) {

            wrapper.isSuccess = false;

            wrapper.errorMessage =
                'Unable to parse vehicle location: ' +
                e.getMessage();
        }

        return wrapper;
    }

    private static Double parseDoubleSafe(String rawValue) {

        try {

            if (String.isBlank(rawValue)) {
                return null;
            }

            return Double.valueOf(rawValue);

        } catch (Exception e) {

            return null;
        }
    }

    private static String truncate(String body) {

        if (body == null) {
            return '';
        }

        Integer maxLength = 500;

        if (body.length() > maxLength) {
            return body.substring(0, maxLength) + '...';
        }

        return body;
    }
}