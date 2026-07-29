@isTest
public class OpportunityLineItemHandlerTest {

    @testSetup
    static void setup() {
        Product2 product = TestDataFactory.createProduct();
        TestDataFactory.createPricebookEntry(product);
        TestDataFactory.createOpportunity();
    }

    @isTest
    static void testQuantityDefaultsToOne() {

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            UnitPrice = pbe.UnitPrice
        );

        insert oli;

        OpportunityLineItem insertedOli = [
            SELECT Quantity FROM OpportunityLineItem LIMIT 1
        ];
        System.assertEquals(1, insertedOli.Quantity);
    }

    @isTest
    static void testQuantityCannotBeMoreThanOne() {

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = pbe.UnitPrice
        );

        try {
            insert oli;
            System.assert(false, 'Exception should have been thrown');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Quantity must be 1'));
        }
    }

    @isTest
    static void testBulkInsert() {

        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        for (Integer i = 0; i < 200; i++) {
            olis.add(new OpportunityLineItem(
                OpportunityId = opp.Id,
                PricebookEntryId = pbe.Id,
                UnitPrice = pbe.UnitPrice
            ));
        }

        insert olis;

        List<OpportunityLineItem> inserted = [
            SELECT Quantity FROM OpportunityLineItem
        ];

        for (OpportunityLineItem oli : inserted) {
            System.assertEquals(1, oli.Quantity);
        }
    }
}