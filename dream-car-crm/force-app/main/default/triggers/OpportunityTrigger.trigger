trigger OpportunityTrigger on Opportunity (
    before update,
    after update,
    after delete
) {

    if (TriggerControl.isOpportunityTriggerDisabled()) {
        return;
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        OpportunityHandler.validateStageChange(
            Trigger.new,
            Trigger.oldMap
        );
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityTriggerHandler.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        OpportunityTriggerHandler.handleAfterDelete(
            Trigger.old
        );
    }
}