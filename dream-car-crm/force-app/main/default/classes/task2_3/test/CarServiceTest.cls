@isTest
public class CarServiceTest {

    private static Product2 createTestCar(String name) {
        Product2 car = new Product2(
            Name = name,
            Brand__c = 'Audi',
            Model__c = 'A6',
            VIN_Number__c = 'VIN-' + name,
            Condition__c = 'Used',
            Mileage__c = 50000,
            IsActive = true
        );
        insert car;
        return car;
    }

    private static Opportunity createOpportunityWithProduct(Product2 car, Decimal price) {

    Id stdPbId = Test.getStandardPricebookId();

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = stdPbId,
        Product2Id = car.Id,
        UnitPrice = price,
        IsActive = true
    );
    insert pbe;

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
        Pricebook2Id = stdPbId
    );
    insert opp;

    OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = opp.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = price
    );
    insert oli;

    return opp;
}

    @isTest
    static void testCarStatusClosedWon() {

        Product2 car = createTestCar('Car1');
        Opportunity opp = createOpportunityWithProduct(car, 100);

        Test.startTest();
        opp.StageName = 'Closed Won';
        update opp;
        Test.stopTest();

        Product2 updated = [
            SELECT Car_Status__c FROM Product2 WHERE Id = :car.Id
        ];

        System.assertEquals('Sold', updated.Car_Status__c);
    }

    @isTest
    static void testCarStatusReserved() {

        Product2 car = createTestCar('Car2');
        Opportunity opp = createOpportunityWithProduct(car, 200);

        Test.startTest();
        opp.StageName = 'Contract Sent';
        update opp;
        Test.stopTest();

        Product2 updated = [
            SELECT Car_Status__c FROM Product2 WHERE Id = :car.Id
        ];

        System.assertEquals('Reserved', updated.Car_Status__c);
    }

    @isTest
    static void testCarStatusClosedLost() {

        Product2 car = createTestCar('Car3');
        Opportunity opp = createOpportunityWithProduct(car, 300);

        opp.StageName = 'Contract Sent';
        update opp;

        Test.startTest();
        opp.StageName = 'Closed Lost';
        update opp;
        Test.stopTest();

        Product2 updated = [
            SELECT Car_Status__c FROM Product2 WHERE Id = :car.Id
        ];

        System.assertEquals('Available', updated.Car_Status__c);
    }
}