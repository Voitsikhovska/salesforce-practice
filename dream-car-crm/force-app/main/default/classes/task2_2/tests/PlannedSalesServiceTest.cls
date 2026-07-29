@IsTest
public class PlannedSalesServiceTest {

    @TestSetup
    static void setup() {

        Id pbId = Test.getStandardPricebookId();

        Product2 product = TestDataFactory.createProduct(
            'BMW',
            'WBA12345678901234'
        );

        PricebookEntry pbe =
            TestDataFactory.createPricebookEntry(product, 100);

        Opportunity opp =
            TestDataFactory.createOpportunity(pbId);

        // Quantity must be 1 (Task 1 requirement)
        TestDataFactory.createOLI(
            opp,
            pbe,
            1
        );

        TestDataFactory.createPlannedSales(
            Date.today().year(),
            Date.today().month(),
            'New'
        );
    }


    @IsTest
    static void testClosedWonCalculation() {

        Opportunity opp = [
            SELECT Id, StageName
            FROM Opportunity
            LIMIT 1
        ];


        Test.startTest();

        opp.StageName = 'Closed Won';
        update opp;

        Test.stopTest();


        Planned_Sale__c ps = [
            SELECT 
                Count_of_Cars_Sold__c,
                Total_Amount_Earned__c
            FROM Planned_Sale__c
            LIMIT 1
        ];


        System.assertEquals(
            1,
            ps.Count_of_Cars_Sold__c
        );

        System.assertEquals(
            100,
            ps.Total_Amount_Earned__c
        );
    }



    @IsTest
    static void testDeleteOpportunity() {

        Opportunity opp = [
            SELECT Id, StageName
            FROM Opportunity
            LIMIT 1
        ];


        opp.StageName = 'Closed Won';
        update opp;


        Test.startTest();

        delete opp;

        Test.stopTest();



        Planned_Sale__c ps = [
            SELECT Count_of_Cars_Sold__c,
                   Total_Amount_Earned__c
            FROM Planned_Sale__c
            LIMIT 1
        ];


        System.assertEquals(
            0,
            ps.Count_of_Cars_Sold__c
        );

        System.assertEquals(
            0,
            ps.Total_Amount_Earned__c
        );
    }




    @IsTest
    static void testNoMatchingOpportunities() {


        delete [
            SELECT Id
            FROM Opportunity
        ];


        Planned_Sale__c ps =
            [
                SELECT Id
                FROM Planned_Sale__c
                LIMIT 1
            ];



        Test.startTest();


        update ps;


        Test.stopTest();



        Planned_Sale__c result = [
            SELECT Count_of_Cars_Sold__c,
                   Total_Amount_Earned__c
            FROM Planned_Sale__c
            LIMIT 1
        ];



        System.assertEquals(
            0,
            result.Count_of_Cars_Sold__c
        );


        System.assertEquals(
            0,
            result.Total_Amount_Earned__c
        );
    }





    @IsTest
    static void testBulkProcessing() {


        Id pbId = Test.getStandardPricebookId();


        Product2 product = TestDataFactory.createProduct(
            'Audi',
            'WAU12345678901234'
        );


        PricebookEntry pbe =
            TestDataFactory.createPricebookEntry(
                product,
                50
            );



        List<Account> accs = new List<Account>();

            for (Integer i = 0; i < 5; i++) {
                accs.add(new Account(
                    Name = 'Bulk Acc ' + i,
                    BillingStreet = 'Main Street ' + i,
                    BillingCity = 'Lviv',
                    BillingPostalCode = '79000',
                    BillingCountryCode = 'UA'
                ));
            }

            insert accs;



        List<Opportunity> opportunities =
            new List<Opportunity>();


        for(Integer i = 0; i < 5; i++) {


            opportunities.add(
                new Opportunity(
                    Name = 'Bulk Opportunity ' + i,
                    StageName = 'Prospecting',
                    CloseDate = Date.today(),
                    AccountId = accs[i].Id,
                    Pricebook2Id = pbId
                )
            );
        }


        insert opportunities;




        List<OpportunityLineItem> items =
            new List<OpportunityLineItem>();


        for(Opportunity opp : opportunities) {


            items.add(
                new OpportunityLineItem(
                    OpportunityId = opp.Id,
                    PricebookEntryId = pbe.Id,
                    Quantity = 1,
                    TotalPrice = 50
                )
            );
        }


        insert items;



        TestDataFactory.createPlannedSales(
            Date.today().year(),
            Date.today().month(),
            'Used'
        );



        Test.startTest();



        for(Opportunity opp : opportunities) {

            opp.StageName = 'Closed Won';

        }


        update opportunities;



        Test.stopTest();




        Planned_Sale__c ps = [
            SELECT Count_of_Cars_Sold__c,
                   Total_Amount_Earned__c
            FROM Planned_Sale__c
            WHERE Car_Type__c = 'New'
            LIMIT 1
        ];




        System.assertEquals(
            5,
            ps.Count_of_Cars_Sold__c
        );



        System.assertEquals(
            250,
            ps.Total_Amount_Earned__c
        );

    }



    @IsTest
    static void testPlannedSalesUpdateTrigger() {


        Planned_Sale__c ps =
            [
                SELECT Id,
                       Year__c,
                       Month__c,
                       Car_Type__c
                FROM Planned_Sale__c
                LIMIT 1
            ];



        Test.startTest();



        ps.Car_Type__c = 'Used';

        update ps;



        Test.stopTest();



        Planned_Sale__c result = [
            SELECT Count_of_Cars_Sold__c,
                   Total_Amount_Earned__c
            FROM Planned_Sale__c
            WHERE Id = :ps.Id
        ];



        System.assertEquals(
            0,
            result.Count_of_Cars_Sold__c
        );


        System.assertEquals(
            0,
            result.Total_Amount_Earned__c
        );
    }
}