public with sharing class EmailNotificationService {

    public static void sendServiceConfirmationEmails(List<Case> webServiceCases) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Case c : webServiceCases) {
            if (String.isBlank(c.SuppliedEmail)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ c.SuppliedEmail });
            email.setSubject('Your Car Service Appointment Request has been Received');
            email.setPlainTextBody(buildBody(c));
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (emails.isEmpty()) return;

        Messaging.sendEmail(emails, false);
    }

    private static String buildBody(Case c) {
        String customerName = String.isNotBlank(c.SuppliedName) ? c.SuppliedName : 'Customer';
        return 'Dear ' + customerName + ',\n\n'
            + 'Thank you for scheduling a service appointment with Dream Cars. '
            + 'We have received your request and will be in touch shortly to confirm the details.\n\n'
            + 'Details Submitted:\n'
            + '- Car Brand: ' + blankSafe(c.Car_Brand__c) + '\n'
            + '- Car Model: ' + blankSafe(c.Car_Model__c) + '\n'
            + '- Reason for Service: ' + blankSafe(c.Subject) + '\n\n'
            + 'If you have any further questions, feel free to reach out to us.\n\n'
            + 'Best regards,\n'
            + 'Dream Cars Service Team.';
    }

    private static String blankSafe(String val) {
        return String.isBlank(val) ? 'N/A' : val;
    }
}