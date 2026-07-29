public class OpportunityLineItemHandler {

    public static void handleBeforeInsertUpdate(List<OpportunityLineItem> newRecords) {
        for (OpportunityLineItem oli : newRecords) {

            // Default value
            if (oli.Quantity == null) {
                oli.Quantity = 1;
            }

            // Validation
            if (oli.Quantity != 1) {
                oli.addError('Quantity must be 1 for each Car.');
            }
        }
    }
}