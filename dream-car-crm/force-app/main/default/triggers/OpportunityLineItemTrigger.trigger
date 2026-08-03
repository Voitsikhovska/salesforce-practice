trigger OpportunityLineItemTrigger on OpportunityLineItem (
    before insert,
    before update,
    after insert,
    after update
) {

    if (Trigger.isBefore) {
        OpportunityLineItemHandler.handleBeforeInsertUpdate(Trigger.new);
    }

    if (Trigger.isAfter) {

        // залишаємо (як ти просила)
        OpportunityLineItemHandler.handleBeforeInsertUpdate(Trigger.new);

        // 🔥 нова логіка
        OpportunityLineItemHandler.handleAfterInsertUpdate(Trigger.new);
    }
}