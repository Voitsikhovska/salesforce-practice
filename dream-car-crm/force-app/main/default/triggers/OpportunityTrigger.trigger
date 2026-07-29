trigger OpportunityTrigger on Opportunity (
    after update,
    after delete
) {

    if (TriggerControl.isOpportunityTriggerDisabled()) {
        return;
    }


    if (Trigger.isUpdate) {

        OpportunityTriggerHandler.handleAfterUpdate(
            Trigger.new,
            Trigger.oldMap
        );

    }


    if (Trigger.isDelete) {

        OpportunityTriggerHandler.handleAfterDelete(
            Trigger.old
        );

    }

}