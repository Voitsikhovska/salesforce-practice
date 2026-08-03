public with sharing class OpportunityTriggerHandler {

    public static void handleAfterUpdate(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap
    ) {

        Set<Id> closedWonOppIds = new Set<Id>();
        Set<Id> changedOppIds = new Set<Id>();

        for (Opportunity opp : newList) {

            Opportunity oldOpp = oldMap.get(opp.Id);

            if (
                opp.StageName == 'Closed Won' &&
                oldOpp.StageName != 'Closed Won'
            ) {
                closedWonOppIds.add(opp.Id);
            }

            if (opp.StageName != oldOpp.StageName) {
                changedOppIds.add(opp.Id);
            }
        }

        if (!closedWonOppIds.isEmpty()) {
            PlannedSalesService.recalculateFromOpportunities(
                closedWonOppIds
            );
        }

        if (!changedOppIds.isEmpty()) {

            Map<Id, Opportunity> filteredNewMap = new Map<Id, Opportunity>();
            Map<Id, Opportunity> filteredOldMap = new Map<Id, Opportunity>();

            for (Id oppId : changedOppIds) {
                filteredNewMap.put(oppId, 
                    (Opportunity) newMapByList(newList).get(oppId)
                );
                filteredOldMap.put(oppId, oldMap.get(oppId));
            }

            CarService.handleAfterUpdate(
                filteredNewMap,
                filteredOldMap
            );
        }
    }

    public static void handleAfterDelete(
        List<Opportunity> oldList
    ) {

        List<Opportunity> deletedClosedWon =
            new List<Opportunity>();

        for (Opportunity opp : oldList) {

            if (opp.StageName == 'Closed Won') {
                deletedClosedWon.add(opp);
            }
        }

        if (!deletedClosedWon.isEmpty()) {

            PlannedSalesService.recalculateFromDeletedOpportunities(
                deletedClosedWon
            );
        }
    }

    private static Map<Id, Opportunity> newMapByList(List<Opportunity> opps) {
        return new Map<Id, Opportunity>(opps);
    }
}