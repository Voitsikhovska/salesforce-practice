public with sharing class CarService {

    /*
     * AFTER UPDATE
     */
    public static void handleAfterUpdate(
        Map<Id, Opportunity> newMap,
        Map<Id, Opportunity> oldMap
    ) {

        if (newMap.isEmpty()) return;

        List<OpportunityLineItem> olis = [
            SELECT Id, OpportunityId, Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId IN :newMap.keySet()
        ];

        if (olis.isEmpty()) return;

        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oli : olis) {
            productIds.add(oli.Product2Id);
        }

        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Car_Status__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Map<Id, List<Product2>> oppToProducts = new Map<Id, List<Product2>>();

        for (OpportunityLineItem oli : olis) {
            if (!oppToProducts.containsKey(oli.OpportunityId)) {
                oppToProducts.put(oli.OpportunityId, new List<Product2>());
            }
            oppToProducts.get(oli.OpportunityId).add(products.get(oli.Product2Id));
        }

        List<Product2> toUpdate = new List<Product2>();

        for (Opportunity opp : newMap.values()) {

            Opportunity oldOpp = oldMap.get(opp.Id);

            if (oldOpp == null) continue;
            if (!oppToProducts.containsKey(opp.Id)) continue;

            for (Product2 prod : oppToProducts.get(opp.Id)) {

                String newStatus;

                if (opp.StageName == 'Contract Sent') {
                    newStatus = 'Reserved';

                } else if (opp.StageName == 'Closed Won') {
                    newStatus = 'Sold';

                } else if (opp.StageName == 'Closed Lost') {
                    newStatus = 'Available';

                } else if (
                    oldOpp.StageName == 'Contract Sent' &&
                    opp.StageName != 'Closed Won' &&
                    opp.StageName != 'Closed Lost'
                ) {
                    newStatus = 'Available';
                }

                if (newStatus != null && prod.Car_Status__c != newStatus) {
                    prod.Car_Status__c = newStatus;
                    toUpdate.add(prod);
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /*
     * BEFORE UPDATE VALIDATION
     */
    public static void validateBeforeUpdate(List<Opportunity> newList) {

        if (newList.isEmpty()) return;

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : newList) {
            oppIds.add(opp.Id);
        }

        List<OpportunityLineItem> olis = [
            SELECT OpportunityId, Product2Id
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        if (olis.isEmpty()) return;

        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oli : olis) {
            productIds.add(oli.Product2Id);
        }

        Map<Id, Product2> products = new Map<Id, Product2>([
            SELECT Id, Car_Status__c
            FROM Product2
            WHERE Id IN :productIds
        ]);

        Map<Id, Set<Id>> productToOpps = new Map<Id, Set<Id>>();

        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product2Id
            FROM OpportunityLineItem
            WHERE Product2Id IN :productIds
        ]) {
            if (!productToOpps.containsKey(oli.Product2Id)) {
                productToOpps.put(oli.Product2Id, new Set<Id>());
            }
            productToOpps.get(oli.Product2Id).add(oli.OpportunityId);
        }

        for (Opportunity opp : newList) {

            for (OpportunityLineItem oli : olis) {

                if (oli.OpportunityId != opp.Id) continue;

                Product2 prod = products.get(oli.Product2Id);
                if (prod == null) continue;

                if (prod.Car_Status__c == 'Sold') {
                    opp.addError(
                        'This car is already sold and cannot be used in another opportunity.'
                    );
                }

                if (prod.Car_Status__c == 'Reserved') {

                    Set<Id> relatedOpps = productToOpps.get(prod.Id);

                    if (relatedOpps != null && relatedOpps.size() > 1) {
                        opp.addError(
                            'This car is reserved in another opportunity.'
                        );
                    }
                }
            }
        }
    }
}