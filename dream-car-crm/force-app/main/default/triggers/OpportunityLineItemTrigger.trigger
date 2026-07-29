trigger OpportunityLineItemTrigger on OpportunityLineItem (
    before insert,
    before update
) {
    OpportunityLineItemHandler.handleBeforeInsertUpdate(Trigger.new);
}