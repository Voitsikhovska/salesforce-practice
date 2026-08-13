public with sharing class CarServiceRecordService {

    public static void createCarServiceRecords(List<Case> webServiceCases) {
        // 1. Collect VINs (bulk, single pass)
        Set<String> vinCodes = new Set<String>();
        for (Case c : webServiceCases) {
            if (String.isNotBlank(c.Car_VIN_Code__c)) {
                vinCodes.add(c.Car_VIN_Code__c);
            }
        }
        if (vinCodes.isEmpty()) return;

        // 2. Single SOQL query for matching Cars (Product2, labeled "Car")
        Map<String, Product2> vinToCar = new Map<String, Product2>();
        for (Product2 car : [
            SELECT Id, VIN_Number__c
            FROM Product2
            WHERE VIN_Number__c IN :vinCodes
        ]) {
            vinToCar.put(car.VIN_Number__c, car);
        }
        if (vinToCar.isEmpty()) return;

        // 3. Build Car_Service__c records (bulk)
        List<Car_Service__c> servicesToInsert = new List<Car_Service__c>();
        Map<Integer, Case> serviceIndexToCase = new Map<Integer, Case>();

        for (Case c : webServiceCases) {
            Product2 matchedCar = String.isNotBlank(c.Car_VIN_Code__c) ? vinToCar.get(c.Car_VIN_Code__c) : null;
            if (matchedCar == null) continue;

            Car_Service__c cs = new Car_Service__c(
                Car__c = matchedCar.Id,
                Service_Date__c = Date.today(),
                Service_Name__c = c.Subject,
                Description__c = c.Description
            );
            serviceIndexToCase.put(servicesToInsert.size(), c);
            servicesToInsert.add(cs);
        }
        if (servicesToInsert.isEmpty()) return;

        // 4. Single bulk insert
        insert servicesToInsert;

        // 5. Link the Case back to the new Car Service record (single bulk update)
        List<Case> casesToUpdate = new List<Case>();
        for (Integer i = 0; i < servicesToInsert.size(); i++) {
            Case relatedCase = serviceIndexToCase.get(i);
            casesToUpdate.add(new Case(
                Id = relatedCase.Id,
                Car_Service__c = servicesToInsert[i].Id
            ));
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
}