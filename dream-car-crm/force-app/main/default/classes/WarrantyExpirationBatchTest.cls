@IsTest
private class WarrantyExpirationBatchTest {

    @TestSetup
    static void setup() {

        Id ownerId = UserInfo.getUserId();

        List<Warranty__c> warranties = new List<Warranty__c>();

        for (Integer i = 0; i < 20; i++) {

            warranties.add(new Warranty__c(
                Warranty_Code__c = 'TEST-EXP-' + i,
                Start_Date__c = Date.today()
                    .addDays(-1)
                    .addMonths(-20),
                TERM__c = 20,
                Warranty_Status__c = 'Active',
                OwnerId = ownerId
            ));
        }

        for (Integer i = 0; i < 20; i++) {

            warranties.add(new Warranty__c(
                Warranty_Code__c = 'TEST-SOON-' + i,
                Start_Date__c = Date.today()
                    .addDays(10)
                    .addMonths(-20),
                TERM__c = 20,
                Warranty_Status__c = 'Active',
                OwnerId = ownerId
            ));
        }

        for (Integer i = 0; i < 10; i++) {

            warranties.add(new Warranty__c(
                Warranty_Code__c = 'TEST-ACTIVE-' + i,
                Start_Date__c = Date.today()
                    .addDays(60)
                    .addMonths(-20),
                TERM__c = 20,
                Warranty_Status__c = 'Active',
                OwnerId = ownerId
            ));
        }

        insert warranties;
    }


    @IsTest
    static void testBatchUpdatesStatusesCorrectly() {

        WarrantyExpirationBatch.testEnabled = true;

        Test.startTest();

        Database.executeBatch(
            new WarrantyExpirationBatch(),
            200
        );

        Test.stopTest();

        List<Warranty__c> warranties = [
            SELECT Id,
                   Warranty_Code__c,
                   Warranty_Status__c,
                   Start_Date__c,
                   End_Date__c
            FROM Warranty__c
            WHERE Warranty_Code__c LIKE 'TEST-%'
        ];

        System.assertEquals(
            50,
            warranties.size(),
            'Expected 50 test warranties.'
        );

        Integer expiredCount = 0;
        Integer expiringSoonCount = 0;
        Integer activeCount = 0;

        for (Warranty__c warranty : warranties) {

            if (warranty.Warranty_Code__c.startsWith('TEST-EXP-')) {

                System.assertEquals(
                    'Expired',
                    warranty.Warranty_Status__c,
                    'Expired test warranty should be Expired. End Date: '
                    + warranty.End_Date__c
                );

                expiredCount++;

            } else if (
                warranty.Warranty_Code__c.startsWith('TEST-SOON-')
            ) {

                System.assertEquals(
                    'Expiring Soon',
                    warranty.Warranty_Status__c,
                    'Expiring Soon test warranty should be Expiring Soon. End Date: '
                    + warranty.End_Date__c
                );

                expiringSoonCount++;

            } else if (
                warranty.Warranty_Code__c.startsWith('TEST-ACTIVE-')
            ) {

                System.assertEquals(
                    'Active',
                    warranty.Warranty_Status__c,
                    'Active test warranty should be Active. End Date: '
                    + warranty.End_Date__c
                );

                activeCount++;
            }
        }

        System.assertEquals(20, expiredCount);
        System.assertEquals(20, expiringSoonCount);
        System.assertEquals(10, activeCount);
    }


    @IsTest
    static void testSummaryEmailIsBatchedPerExecute() {

        WarrantyExpirationBatch.testEnabled = true;

        Test.startTest();

        Database.executeBatch(
            new WarrantyExpirationBatch(),
            200
        );

        Test.stopTest();

        System.assert(
            Limits.getEmailInvocations() <= 1,
            'Expected at most one email send invocation per execute() call.'
        );
    }


    @IsTest
    static void testNoDuplicateNotificationForAlreadyExpiringWarranty() {

        WarrantyExpirationBatch.testEnabled = true;

        Warranty__c warranty = [
            SELECT Id,
                   Warranty_Status__c,
                   End_Date__c
            FROM Warranty__c
            WHERE Warranty_Code__c = 'TEST-SOON-0'
            LIMIT 1
        ];

        System.assert(
            warranty.End_Date__c >= Date.today()
            && warranty.End_Date__c <= Date.today().addDays(30),
            'Warranty must expire within 30 days. Actual End Date: '
            + warranty.End_Date__c
        );

        warranty.Warranty_Status__c = 'Expiring Soon';
        update warranty;

        Test.startTest();

        Database.executeBatch(
            new WarrantyExpirationBatch(),
            200
        );

        Test.stopTest();

        Warranty__c warrantyAfter = [
            SELECT Id,
                   Warranty_Status__c
            FROM Warranty__c
            WHERE Id = :warranty.Id
        ];

        System.assertEquals(
            'Expiring Soon',
            warrantyAfter.Warranty_Status__c,
            'Already Expiring Soon warranty should remain Expiring Soon.'
        );
    }


    @IsTest
    static void testKillSwitchOffSkipsProcessing() {

        WarrantyExpirationBatch.testEnabled = false;

        List<Warranty__c> beforeRecords = [
            SELECT Id, Warranty_Status__c
            FROM Warranty__c
            ORDER BY Id
        ];

        Test.startTest();

        Database.executeBatch(
            new WarrantyExpirationBatch(),
            200
        );

        Test.stopTest();

        List<Warranty__c> afterRecords = [
            SELECT Id, Warranty_Status__c
            FROM Warranty__c
            ORDER BY Id
        ];

        System.assertEquals(
            beforeRecords.size(),
            afterRecords.size()
        );

        for (Integer i = 0; i < beforeRecords.size(); i++) {

            System.assertEquals(
                beforeRecords[i].Warranty_Status__c,
                afterRecords[i].Warranty_Status__c,
                'Kill switch OFF should leave warranties unchanged.'
            );
        }
    }


    @IsTest
    static void testSchedulerSchedulesDailyJob() {

        Test.startTest();

        String jobId =
            WarrantyExpirationScheduler.scheduleDaily();

        Test.stopTest();

        CronTrigger cron = [
            SELECT Id,
                   CronExpression,
                   TimesTriggered,
                   NextFireTime,
                   State
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(
            '0 0 2 * * ?',
            cron.CronExpression,
            'Scheduler should run daily at 02:00.'
        );

        System.assertEquals(
            'WAITING',
            cron.State,
            'Scheduled job should be waiting for its next execution.'
        );
    }


    @IsTest
    static void testSchedulerExecuteLaunchesBatch() {

        WarrantyExpirationBatch.testEnabled = true;

        Test.startTest();

        WarrantyExpirationScheduler scheduler =
            new WarrantyExpirationScheduler();

        scheduler.execute(null);

        Test.stopTest();

        List<AsyncApexJob> jobs = [
            SELECT Id,
                   JobType,
                   Status,
                   NumberOfErrors
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals(
            1,
            jobs.size(),
            'Scheduler should launch the WarrantyExpirationBatch.'
        );

        System.assertEquals(
            'BatchApex',
            jobs[0].JobType
        );

        System.assertEquals(
            0,
            jobs[0].NumberOfErrors,
            'The scheduled batch should not have errors.'
        );
    }
}