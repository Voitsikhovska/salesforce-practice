public class OpportunityLineItemHandler {

    // 🔹 BEFORE логіка (твоя існуюча)
    public static void handleBeforeInsertUpdate(List<OpportunityLineItem> newRecords) {

        Set<Id> productIds = new Set<Id>();

        for (OpportunityLineItem oli : newRecords) {

            if (oli.Quantity == null) {
                oli.Quantity = 1;
            }

            if (oli.Quantity != 1) {
                oli.addError('Quantity must be 1 for each Car.');
            }

            if (oli.Product2Id != null) {
                productIds.add(oli.Product2Id);
            }
        }

        if (productIds.isEmpty()) return;

        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Car_Status__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        for (OpportunityLineItem oli : newRecords) {

            Product2 prod = products.get(oli.Product2Id);
            if (prod == null) continue;

            if (prod.Car_Status__c == 'Sold') {
                oli.addError(
                    'This car is already sold and cannot be added to another opportunity.'
                );
            }
        }
    }


    // 🔥 AFTER логіка (owner)
    public static void handleAfterInsertUpdate(List<OpportunityLineItem> newRecords) {

        Set<Id> productIds = new Set<Id>();
        Map<Id, Id> productToOpp = new Map<Id, Id>();

        for (OpportunityLineItem oli : newRecords) {
            if (oli.Product2Id != null) {
                productIds.add(oli.Product2Id);
                productToOpp.put(oli.Product2Id, oli.OpportunityId);
            }
        }

        if (productIds.isEmpty()) return;

        List<Product2> products = [
            SELECT Id, Car_Status__c, Reserved_Opportunity__c
            FROM Product2
            WHERE Id IN :productIds
        ];

        List<Product2> toUpdate = new List<Product2>();

        for (Product2 p : products) {

            if ((p.Car_Status__c == 'Reserved' || p.Car_Status__c == 'Sold')
                && p.Reserved_Opportunity__c == null) {

                p.Reserved_Opportunity__c = productToOpp.get(p.Id);
                toUpdate.add(p);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}