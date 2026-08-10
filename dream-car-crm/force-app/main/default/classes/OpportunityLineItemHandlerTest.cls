@isTest
public class OpportunityLineItemHandlerTest {

    @testSetup
    static void setup() {

        Product2 availableCar = TestDataFactory.createProduct();
        Product2 soldCar = TestDataFactory.createProduct();
        Product2 reservedCar = TestDataFactory.createProduct();

        availableCar.Car_Status__c = 'Available';
        soldCar.Car_Status__c = 'Sold';
        reservedCar.Car_Status__c = 'Reserved';

        update new List<Product2>{availableCar, soldCar, reservedCar};

        TestDataFactory.createPricebookEntry(availableCar);
        TestDataFactory.createPricebookEntry(soldCar);
        TestDataFactory.createPricebookEntry(reservedCar);

        TestDataFactory.createOpportunity();
    }

    @isTest
    static void testAllScenarios() {

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, PricebookEntry> pbes = new Map<String, PricebookEntry>();

        for (PricebookEntry pbe : [
            SELECT Id, Product2.Car_Status__c, UnitPrice
            FROM PricebookEntry
        ]) {
            pbes.put(pbe.Product2.Car_Status__c, pbe);
        }

        // -------------------------------
        // ✅ 1. Quantity default = 1
        // -------------------------------
        OpportunityLineItem oli1 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbes.get('Available').Id,
            UnitPrice = pbes.get('Available').UnitPrice
        );

        insert oli1;

        OpportunityLineItem inserted = [
            SELECT Quantity FROM OpportunityLineItem WHERE Id = :oli1.Id
        ];
        System.assertEquals(1, inserted.Quantity);

        // -------------------------------
        // ❌ 2. Quantity > 1 → ERROR
        // -------------------------------
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbes.get('Available').Id,
            Quantity = 2,
            UnitPrice = pbes.get('Available').UnitPrice
        );

        try {
            insert oli2;
            System.assert(false, 'Should fail on quantity');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Quantity must be 1'));
        }

        // -------------------------------
        // ❌ 3. SOLD → BLOCK
        // -------------------------------
        OpportunityLineItem oli3 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbes.get('Sold').Id,
            Quantity = 1,
            UnitPrice = pbes.get('Sold').UnitPrice
        );

        try {
            insert oli3;
            System.assert(false, 'Should fail for sold car');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('already sold'));
        }

        // -------------------------------
        // ⚠️ 4. RESERVED → ALLOWED
        // -------------------------------
        OpportunityLineItem oli4 = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbes.get('Reserved').Id,
            Quantity = 1,
            UnitPrice = pbes.get('Reserved').UnitPrice
        );

        insert oli4;

        System.assertNotEquals(null, oli4.Id);

        // -------------------------------
        // 🚀 5. BULK
        // -------------------------------
        List<OpportunityLineItem> bulkList = new List<OpportunityLineItem>();

        for (Integer i = 0; i < 50; i++) {
            bulkList.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbes.get('Available').Id,
                UnitPrice = pbes.get('Available').UnitPrice
            ));
        }

        insert bulkList;

        List<OpportunityLineItem> insertedBulk = [
            SELECT Quantity FROM OpportunityLineItem
        ];

        for (OpportunityLineItem oli : insertedBulk) {
            System.assertEquals(1, oli.Quantity);
        }
    }
}