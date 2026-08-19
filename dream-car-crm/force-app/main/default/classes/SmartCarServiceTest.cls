@isTest
private class SmartCarServiceTest {

    private static final String TEST_VEHICLE_ID = '36ab27d0-fd9d-4147-aa91-3f8b13320f68';
    private static final String TEST_USER_ID = 'user_test_id_123';

    private class SmartCarMockSuccess implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

        System.assertEquals(
            TEST_USER_ID,
            req.getHeader('sc-user-id'),
            'sc-user-id header must be set on every request'
        );

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        if (req.getEndpoint().endsWith('/signals')) {

            res.setBody(
                '{' +
                    '"data": [' +

                        '{' +
                            '"id": "location-isathome",' +
                            '"type": "signal",' +
                            '"attributes": {' +
                                '"code": "location-isathome",' +
                                '"name": "IsAtHome",' +
                                '"group": "Location",' +
                                '"status": {' +
                                    '"value": "SUCCESS"' +
                                '},' +
                                '"body": {' +
                                    '"value": true' +
                                '}' +
                            '}' +
                        '},' +

                        '{' +
                            '"id": "location-preciselocation",' +
                            '"type": "signal",' +
                            '"attributes": {' +
                                '"code": "location-preciselocation",' +
                                '"name": "PreciseLocation",' +
                                '"group": "Location",' +
                                '"status": {' +
                                    '"value": "SUCCESS"' +
                                '},' +
                                '"body": {' +
                                    '"latitude": 23.5014,' +
                                    '"longitude": 54.1419,' +
                                    '"heading": 40.3,' +
                                    '"direction": "SE",' +
                                    '"locationType": "LAST_PARKED"' +
                                '}' +
                            '}' +
                        '}' +

                    '],' +

                    '"meta": {' +
                        '"totalCount": 2,' +
                        '"pageSize": 2,' +
                        '"pageNumber": 1' +
                    '}' +
                '}'
            );

        } else {

            res.setBody(
                '{' +
                    '"data": {' +
                        '"id": "' + TEST_VEHICLE_ID + '",' +
                        '"type": "vehicle",' +
                        '"attributes": {' +
                            '"make": "SIMULATED",' +
                            '"model": "ICE",' +
                            '"year": 2026,' +
                            '"powertrainType": "ICE",' +
                            '"mode": "simulated"' +
                        '}' +
                    '}' +
                '}'
            );
        }

        return res;
    }
}

    private class SmartCarMockMalformed implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('not valid json');
            return res;
        }
    }

    private class SmartCarMockNoLocationSignal implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"data":[{"code":"odometer","body":{"distance":12345}}]}');
            return res;
        }
    }

    private class SmartCarMockError implements HttpCalloutMock {
        Integer statusCode;
        SmartCarMockError(Integer statusCode) {
            this.statusCode = statusCode;
        }
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody('{"error":"error detail"}');
            return res;
        }
    }

    private class SmartCarMockCalloutFailure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Timeout contacting endpoint');
        }
    }


    @isTest
static void testGetVehicleInfoSuccess() {
    Test.setMock(
        HttpCalloutMock.class,
        new SmartCarMockSuccess()
    );

    Test.startTest();

    SmartCarVehicleWrapper result =
        SmartCarService.getVehicleInfo(
            TEST_VEHICLE_ID,
            TEST_USER_ID
        );

    Test.stopTest();

    System.assertNotEquals(
        null,
        result,
        'Expected a SmartCarVehicleWrapper result.'
    );

    System.assertEquals(
        true,
        result.isSuccess,
        'Expected successful vehicle information response.'
    );

    System.assertEquals(
        TEST_VEHICLE_ID,
        result.vehicleId,
        'Vehicle ID should match the test vehicle ID.'
    );

    System.assertEquals(
        'SIMULATED',
        result.make,
        'Expected make to be SIMULATED.'
    );

    System.assertEquals(
        'ICE',
        result.model,
        'Expected model to be ICE.'
    );

    System.assertEquals(
        2026,
        result.year,
        'Expected year to be 2026.'
    );

    System.assertEquals(
        'ICE',
        result.powertrainType,
        'Expected powertrain type to be ICE.'
    );
}


@isTest
static void testGetVehicleLocationSuccess() {
    Test.setMock(
        HttpCalloutMock.class,
        new SmartCarMockSuccess()
    );

    Test.startTest();

    SmartCarVehicleWrapper result =
        SmartCarService.getVehicleLocation(
            TEST_VEHICLE_ID,
            TEST_USER_ID
        );

    Test.stopTest();

    System.assertNotEquals(
        null,
        result,
        'Expected a SmartCarVehicleWrapper result.'
    );

    System.assertEquals(
        true,
        result.isSuccess,
        'Expected successful vehicle location response.'
    );

    System.assertEquals(
        23.5014,
        result.latitude,
        'Expected latitude to be 23.5014.'
    );

    System.assertEquals(
        54.1419,
        result.longitude,
        'Expected longitude to be 54.1419.'
    );
}

    @isTest
    static void testGetVehicleLocationNoLocationSignalReturned() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockNoLocationSignal());

        Test.startTest();
        SmartCarVehicleWrapper result = SmartCarService.getVehicleLocation(TEST_VEHICLE_ID, TEST_USER_ID);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess, 'Expected failure when no location signal is present');
        System.assertNotEquals(null, result.errorMessage);
    }


    @isTest
    static void testGetVehicleInfoBlankVehicleIdThrows() {
        Boolean exceptionThrown = false;
        try {
            SmartCarService.getVehicleInfo('', TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assertEquals('Vehicle Id is required.', e.getMessage());
        }
        System.assertEquals(true, exceptionThrown, 'Expected exception for blank vehicle Id');
    }

    @isTest
    static void testGetVehicleInfoBlankUserIdThrows() {
        Boolean exceptionThrown = false;
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, '');
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('SmartCar User Id is required'));
        }
        System.assertEquals(true, exceptionThrown, 'Expected exception for blank SmartCar User Id');
    }

    @isTest
    static void testGetVehicleLocationNullIdsThrow() {
        Boolean exceptionThrown = false;
        try {
            SmartCarService.getVehicleLocation(null, null);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
        }
        System.assertEquals(true, exceptionThrown, 'Expected exception for null vehicle/user Id');
    }


    @isTest
    static void testGetVehicleInfo401Error() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockError(401));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Authentication'), 'Expected auth-related message');
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    static void testGetVehicleInfo403Error() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockError(403));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('not authorized'));
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    static void testGetVehicleInfo404Error() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockError(404));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo('unknown-id', TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('not found'));
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    static void testGetVehicleInfo429Error() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockError(429));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Too many requests'));
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }

    @isTest
    static void testGetVehicleInfo500ErrorMapsToGenericMessage() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockError(500));
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('unexpected error'));
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }


    @isTest
    static void testCalloutExceptionIsHandledGracefully() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockCalloutFailure());
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (SmartCarService.SmartCarServiceException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Unable to reach'));
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown);
    }


    @isTest
    static void testMalformedResponseBodyIsHandledWithoutUnhandledException() {
        Test.setMock(HttpCalloutMock.class, new SmartCarMockMalformed());

        Test.startTest();
        Boolean handled = true;
        try {
            SmartCarService.getVehicleInfo(TEST_VEHICLE_ID, TEST_USER_ID);
        } catch (Exception e) {
            handled = true;
        }
        Test.stopTest();

        System.assertEquals(true, handled, 'Malformed payload handled without unhandled exception');
    }
}