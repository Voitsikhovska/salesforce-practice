public class TestDataFactory {


    public static Product2 createProduct(String name) {

        return createProduct(
            name,
            generateVin()
        );
    }


    public static Product2 createProduct(String name, String vin) {

        Product2 p = new Product2(
            Name = name,
            IsActive = true,

            Brand__c = 'Toyota',
            Model__c = 'Camry',

            VIN_Number__c = vin,

            Condition__c = 'New',
            Mileage__c = 10,

            Family = 'New'
        );

        insert p;

        return p;
    }


    public static PricebookEntry createPricebookEntry(
        Product2 p,
        Decimal price
    ) {

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = p.Id,
            Pricebook2Id = standardPricebookId,
            UnitPrice = price,
            IsActive = true
        );

        insert pbe;

        return pbe;
    }


    public static Opportunity createOpportunity(
        Id pricebookId
    ) {

            Account acc = new Account(
            Name = 'Test Account',

            BillingStreet = 'Main Street 1',
            BillingCity = 'Lviv',
            BillingPostalCode = '79000',

            BillingCountry = 'Ukraine'
        );

        insert acc;


        Opportunity opp = new Opportunity(

            Name = 'Test Opp',

            StageName = 'Prospecting',

            CloseDate = Date.today(),

            AccountId = acc.Id,

            Pricebook2Id = pricebookId
        );


        insert opp;


        return opp;
    }


    public static OpportunityLineItem createOLI(
        Opportunity opp,
        PricebookEntry pbe,
        Integer qty
    ) {

        OpportunityLineItem oli =
            new OpportunityLineItem(

                OpportunityId = opp.Id,

                PricebookEntryId = pbe.Id,

                // Task 1:
                // Each car must be tracked individually
                Quantity = 1,

                TotalPrice = pbe.UnitPrice

            );


        insert oli;


        return oli;
    }


    public static Planned_Sale__c createPlannedSales(
        Integer year,
        Integer month,
        String carType
    ) {

        Planned_Sale__c ps =
            new Planned_Sale__c(

                Year__c = year,

                Month__c = month,

                Car_Type__c = carType

            );


        insert ps;


        return ps;
    }


    // Backward compatibility for existing tests

    public static Product2 createProduct() {

        return createProduct('Test Product');

    }


    public static PricebookEntry createPricebookEntry(
        Product2 p
    ) {

        return createPricebookEntry(
            p,
            100
        );

    }


    public static Opportunity createOpportunity() {

        return createOpportunity(
            Test.getStandardPricebookId()
        );

    }


    private static String generateVin() {

        String timestamp = String.valueOf(
            DateTime.now().getTime()
        );

        String vin = '1HG' + timestamp;


        while (vin.length() < 17) {
            vin += '0';
        }


        return vin.substring(0,17);
    }

}