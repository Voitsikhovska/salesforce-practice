trigger ProductTrigger on Product2 (after update) {

    ProductHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);

}