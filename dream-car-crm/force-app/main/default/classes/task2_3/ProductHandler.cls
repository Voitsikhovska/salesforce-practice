public class ProductHandler {

    public static Boolean isRunning = false;

    public static void handleAfterUpdate(
        List<Product2> newList,
        Map<Id, Product2> oldMap
    ) {

        if (isRunning) return;
        isRunning = true;

        try {

            Set<Id> productIds = new Set<Id>();

            for (Product2 p : newList) {
                Product2 oldP = oldMap.get(p.Id);

                if (p.Car_Status__c == 'Reserved' || p.Car_Status__c == 'Sold'
                    || oldP.Car_Status__c != p.Car_Status__c) {

                    productIds.add(p.Id);
                }
            }

            if (productIds.isEmpty()) return;

            Map<Id, List<OpportunityLineItem>> productToOLI = new Map<Id, List<OpportunityLineItem>>();

            for (OpportunityLineItem oli : [
                SELECT Product2Id, OpportunityId, Opportunity.CreatedDate
                FROM OpportunityLineItem
                WHERE Product2Id IN :productIds
                ORDER BY Opportunity.CreatedDate ASC
            ]) {

                if (!productToOLI.containsKey(oli.Product2Id)) {
                    productToOLI.put(oli.Product2Id, new List<OpportunityLineItem>());
                }

                productToOLI.get(oli.Product2Id).add(oli);
            }

            List<Product2> toUpdate = new List<Product2>();

            for (Id productId : productIds) {

                List<OpportunityLineItem> olis = productToOLI.get(productId);

                Id newOwnerOppId = null;

                if (olis != null && !olis.isEmpty()) {
                    newOwnerOppId = olis[0].OpportunityId;
                }

                toUpdate.add(new Product2(
                    Id = productId,
                    Reserved_Opportunity__c = newOwnerOppId
                ));
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }

        } finally {
            isRunning = false;
        }
    }
}