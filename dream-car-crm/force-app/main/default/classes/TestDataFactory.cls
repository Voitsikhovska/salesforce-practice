public class TestDataFactory {

    public static Product2 createProduct() {
        Product2 p = new Product2(
            Name = 'Test Car',
            IsActive = true,

            Brand__c = 'Toyota',
            Model__c = 'Camry',

            VIN_Number__c = 'VIN12345678901234',

            Condition__c = 'New',
            Mileage__c = 10
        );
        insert p;
        return p;
    }

    public static PricebookEntry createPricebookEntry(Product2 p) {

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = p.Id,
            Pricebook2Id = standardPricebookId,
            UnitPrice = 10000,
            IsActive = true
        );

        insert pbe;
        return pbe;
    }

    public static Opportunity createOpportunity() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert opp;

        return opp;
    }
}