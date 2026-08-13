public with sharing class CaseTriggerHandler extends TriggerHandler {

    private List<Case> newCases;

    public CaseTriggerHandler() {
        this.newCases = (List<Case>) Trigger.new;
    }

    protected override void afterInsert() {
        List<Case> webServiceCases = new List<Case>();
        for (Case c : newCases) {
            if (c.Origin == 'Web Car Service') {
                webServiceCases.add(c);
            }
        }
        if (webServiceCases.isEmpty()) return;

        CarServiceRecordService.createCarServiceRecords(webServiceCases);
        EmailNotificationService.sendServiceConfirmationEmails(webServiceCases);
    }
}