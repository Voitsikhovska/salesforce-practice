trigger PlannedSalesTrigger on Planned_Sale__c (after insert, after update) {
    if (TriggerControl.isPlannedSalesTriggerDisabled()) {
        return;
    }

    try {
        if (Trigger.isAfter) {
            PlannedSalesTriggerHandler.handle(Trigger.new);
        }
    } catch (Exception e) {
        System.debug('Error in PlannedSalesTrigger: ' + e.getMessage());
        throw e;
    }
}