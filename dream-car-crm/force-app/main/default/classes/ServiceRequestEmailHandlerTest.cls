@isTest
private class ServiceRequestEmailHandlerTest {

    @TestSetup
static void setup() {
    insert new Product2(
        Name           = 'Test Car',
        VIN_Number__c  = 'VIN12345',
        IsActive       = true,
        Brand__c       = 'Toyota',     
        Model__c       = 'Corolla',    
        Condition__c   = 'New',        
        Mileage__c     = 0
    );
}

    @isTest
    static void testCaseCreatedWithMatchingVin() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        email.subject = 'VIN-VIN12345 - Engine noise';
        email.plainTextBody = 'Please check my car, it makes a strange noise.';
        email.fromName = 'John Doe';
        envelope.fromAddress = 'john.doe@example.com';

        Messaging.InboundEmail.BinaryAttachment att = new Messaging.InboundEmail.BinaryAttachment();
        att.body = Blob.valueOf('dummy file content');
        att.fileName = 'photo.jpg';
        att.mimeTypeSubType = 'image/jpeg';
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] { att };

        Test.startTest();
        new ServiceRequestEmailHandler().handleInboundEmail(email, envelope);
        Test.stopTest();

        Case c = [SELECT Id, Subject, Car_Service__c, Origin FROM Case WHERE SuppliedEmail = 'john.doe@example.com'];
        System.assertEquals('Email', c.Origin);
        System.assertNotEquals(null, c.Car_Service__c);

        Car_Service__c cs = [SELECT Id, Car__c FROM Car_Service__c WHERE Id = :c.Car_Service__c];
        System.assertNotEquals(null, cs.Car__c);

        Integer caseLinks = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id];
        System.assert(caseLinks > 0);

        Integer csLinks = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :cs.Id];
        System.assert(csLinks > 0);
    }

    @isTest
    static void testCaseCreatedWithoutMatchingVin() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        email.subject = 'VIN-NOTFOUND - Question about warranty';
        email.plainTextBody = 'Just a question, no attachment.';
        envelope.fromAddress = 'jane@example.com';

        Test.startTest();
        new ServiceRequestEmailHandler().handleInboundEmail(email, envelope);
        Test.stopTest();

        Case c = [SELECT Id, Car_Service__c FROM Case WHERE SuppliedEmail = 'jane@example.com'];
        System.assertEquals(null, c.Car_Service__c);
    }

    @isTest
    static void testCaseCreatedWithoutVinPattern() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        email.subject = 'General inquiry';
        email.plainTextBody = 'No VIN here.';
        envelope.fromAddress = 'ann@example.com';

        Test.startTest();
        new ServiceRequestEmailHandler().handleInboundEmail(email, envelope);
        Test.stopTest();

        Case c = [SELECT Id, Car_Service__c FROM Case WHERE SuppliedEmail = 'ann@example.com'];
        System.assertEquals(null, c.Car_Service__c);
    }
}