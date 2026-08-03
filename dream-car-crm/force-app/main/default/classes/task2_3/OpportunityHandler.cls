public class OpportunityHandler {

    public static void validateStageChange(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap
    ) {

        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        // 🔹 збираємо Opp де змінився Stage
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            if (oldOpp != null && opp.StageName != oldOpp.StageName) {
                oppIds.add(opp.Id);
                oppMap.put(opp.Id, opp);
            }
        }

        if (oppIds.isEmpty()) return;

        List<OpportunityLineItem> olis = [
            SELECT OpportunityId, Product2Id,
                   Product2.Car_Status__c,
                   Product2.Reserved_Opportunity__c
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
        ];

        for (OpportunityLineItem oli : olis) {

            if (oli.Product2Id == null) continue;

            String status = oli.Product2.Car_Status__c;
            Id ownerOppId = oli.Product2.Reserved_Opportunity__c;

            if (status == 'Reserved' || status == 'Sold') {

                // ❌ якщо це НЕ owner → блокуємо
                if (ownerOppId != null &&
                    oli.OpportunityId != ownerOppId) {

                    Opportunity opp = oppMap.get(oli.OpportunityId);

                    if (opp != null) {
                        opp.addError(
                            'This car is reserved/sold in another Opportunity. ' +
                            'Only the owner Opportunity can move forward.'
                        );
                    }
                }
            }
        }
    }
}