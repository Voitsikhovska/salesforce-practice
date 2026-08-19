public with sharing class ServiceRequestEmailHandler implements Messaging.InboundEmailHandler {

    private static final Pattern VIN_PATTERN = Pattern.compile('VIN-([A-Za-z0-9]+)');

    public Messaging.InboundEmailResult handleInboundEmail(
        Messaging.InboundEmail email,
        Messaging.InboundEnvelope envelope
    ) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        result.success = true;

        Case newCase;

        try {
            newCase = new Case(
                Subject       = email.subject,
                Description   = String.isNotBlank(email.plainTextBody) ? email.plainTextBody : email.htmlBody,
                Origin        = 'Email',
                SuppliedEmail = envelope.fromAddress,
                SuppliedName  = email.fromName
            );
            insert newCase;
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to create Case: ' + e.getMessage();
            return result;
        }

        List<ContentVersion> caseAttachments = new List<ContentVersion>();
        try {
            caseAttachments = createContentVersions(email, newCase.Id);
        } catch (Exception e) {
            System.debug('Attachment creation failed for Case ' + newCase.Id + ': ' + e.getMessage());
        }

        try {
            processVinAndCarService(email, newCase, caseAttachments);
        } catch (Exception e) {
            System.debug('VIN/Car Service processing failed for Case ' + newCase.Id + ': ' + e.getMessage());
        }

        return result;
    }

    private void processVinAndCarService(
        Messaging.InboundEmail email,
        Case newCase,
        List<ContentVersion> caseAttachments
    ) {
        if (String.isBlank(email.subject)) return;

        Matcher m = VIN_PATTERN.matcher(email.subject);
        if (!m.find()) return;

        String vinCode = m.group(1);

        Product2 car = findCarByVin(vinCode);
        if (car == null) return; 

        Car_Service__c cs = new Car_Service__c(
            Car__c          = car.Id,
            Service_Date__c = Date.today(),
            Service_Name__c = email.subject,
            Description__c  = newCase.Description
        );
        insert cs;

        newCase.Car_Service__c = cs.Id;
        update newCase;

        if (!caseAttachments.isEmpty()) {
            attachFilesToCarService(caseAttachments, cs.Id);
        }
    }

    private List<ContentVersion> createContentVersions(Messaging.InboundEmail email, Id caseId) {
        List<ContentVersion> versions = new List<ContentVersion>();

        if (email.binaryAttachments != null) {
            for (Messaging.InboundEmail.BinaryAttachment att : email.binaryAttachments) {
                versions.add(new ContentVersion(
                    Title                  = att.fileName,
                    PathOnClient           = att.fileName,
                    VersionData            = att.body,
                    FirstPublishLocationId = caseId
                ));
            }
        }
        if (email.textAttachments != null) {
            for (Messaging.InboundEmail.TextAttachment att : email.textAttachments) {
                versions.add(new ContentVersion(
                    Title                  = att.fileName,
                    PathOnClient           = att.fileName,
                    VersionData            = Blob.valueOf(att.body),
                    FirstPublishLocationId = caseId
                ));
            }
        }
        if (!versions.isEmpty()) {
            insert versions;
        }
        return versions;
    }

    private void attachFilesToCarService(List<ContentVersion> caseVersions, Id carServiceId) {
        Set<Id> versionIds = new Set<Id>();
        for (ContentVersion cv : caseVersions) versionIds.add(cv.Id);

        List<ContentVersion> versionsWithDocs = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id IN :versionIds
        ];

        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (ContentVersion cv : versionsWithDocs) {
            links.add(new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId    = carServiceId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            ));
        }
        if (!links.isEmpty()) {
            insert links;
        }
    }

    private Product2 findCarByVin(String vin) {
        List<Product2> cars = [
            SELECT Id, VIN_Number__c
            FROM Product2
            WHERE VIN_Number__c = :vin
            LIMIT 1
        ];
        return cars.isEmpty() ? null : cars[0];
    }
}