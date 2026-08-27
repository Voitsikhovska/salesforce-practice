public class WarrantyExpirationBatch implements Database.Batchable<SObject>, Database.Stateful {

    private static final Integer EXPIRING_SOON_WINDOW_DAYS = 30;

    @TestVisible
    private static Boolean testEnabled;

    public Integer totalUpdated = 0;
    public Integer totalNotifiedOwners = 0;

    private Boolean isEnabled() {
        if (Test.isRunningTest() && testEnabled != null) {
            return testEnabled;
        }

        Warranty_Batch_Settings__mdt settings =
            Warranty_Batch_Settings__mdt.getInstance('Default');

        return settings != null && settings.Is_Enabled__c == true;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        if (!isEnabled()) {
            return Database.getQueryLocator([
                SELECT Id
                FROM Warranty__c
                WHERE Id = null
            ]);
        }

        return Database.getQueryLocator([
            SELECT Id,
                   Name,
                   End_Date__c,
                   Warranty_Status__c,
                   OwnerId,
                   Car__c,
                   Car__r.Name
            FROM Warranty__c
            WHERE End_Date__c != null
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Warranty__c> scope
    ) {
        Date today = Date.today();
        Date soonThreshold = today.addDays(EXPIRING_SOON_WINDOW_DAYS);

        List<Warranty__c> toUpdate = new List<Warranty__c>();

        Map<Id, List<Warranty__c>> newlyExpiringByOwner =
            new Map<Id, List<Warranty__c>>();

        for (Warranty__c warranty : scope) {

            String oldStatus = warranty.Warranty_Status__c;
            String newStatus;

            if (warranty.End_Date__c < today) {
                newStatus = 'Expired';
            } else if (warranty.End_Date__c <= soonThreshold) {
                newStatus = 'Expiring Soon';
            } else {
                newStatus = 'Active';
            }

            if (newStatus != oldStatus) {

                warranty.Warranty_Status__c = newStatus;
                toUpdate.add(warranty);

                Boolean justFlippedToExpiringSoon =
                    newStatus == 'Expiring Soon'
                    && oldStatus != 'Expiring Soon';

                if (justFlippedToExpiringSoon && warranty.OwnerId != null) {

                    if (!newlyExpiringByOwner.containsKey(warranty.OwnerId)) {
                        newlyExpiringByOwner.put(
                            warranty.OwnerId,
                            new List<Warranty__c>()
                        );
                    }

                    newlyExpiringByOwner.get(warranty.OwnerId).add(warranty);
                }
            }
        }

        if (!toUpdate.isEmpty()) {

            List<Database.SaveResult> results =
                Database.update(toUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {

                if (results[i].isSuccess()) {
                    totalUpdated++;
                } else {
                    System.debug(
                        LoggingLevel.ERROR,
                        'WarrantyExpirationBatch: failed to update '
                        + toUpdate[i].Id
                        + ' -> '
                        + results[i].getErrors()
                    );
                }
            }
        }

        if (!newlyExpiringByOwner.isEmpty()) {
            sendSummaryEmails(newlyExpiringByOwner);
            totalNotifiedOwners += newlyExpiringByOwner.size();
        }
    }

    private void sendSummaryEmails(
        Map<Id, List<Warranty__c>> byOwner
    ) {

        Map<Id, String> ownerEmailById = new Map<Id, String>();

        for (User user : [
            SELECT Id, Email
            FROM User
            WHERE Id IN :byOwner.keySet()
        ]) {
            ownerEmailById.put(user.Id, user.Email);
        }

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        for (Id ownerId : byOwner.keySet()) {

            String toAddress = ownerEmailById.get(ownerId);

            if (String.isBlank(toAddress)) {
                continue;
            }

            List<Warranty__c> warranties = byOwner.get(ownerId);

            String body =
                'The following warranties you own have just moved to '
                + '"Expiring Soon" status:\n\n';

            for (Warranty__c warranty : warranties) {

                body += '- ' + warranty.Name
                    + ' | Car: '
                    + (
                        warranty.Car__r != null
                        ? warranty.Car__r.Name
                        : 'N/A'
                    )
                    + ' | End Date: '
                    + warranty.End_Date__c.format()
                    + '\n';
            }

            body +=
                '\nPlease reach out to these customers regarding '
                + 'renewal or service options.';

            Messaging.SingleEmailMessage email =
                new Messaging.SingleEmailMessage();

            email.setToAddresses(new List<String>{ toAddress });

            email.setSubject(
                'Warranty Alert: '
                + warranties.size()
                + (
                    warranties.size() == 1
                    ? ' warranty is'
                    : ' warranties are'
                )
                + ' expiring soon'
            );

            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);

            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    public void finish(Database.BatchableContext bc) {

        System.debug(
            'WarrantyExpirationBatch finished. '
            + 'Records updated: ' + totalUpdated
            + ', Owners notified: ' + totalNotifiedOwners
        );
    }
}