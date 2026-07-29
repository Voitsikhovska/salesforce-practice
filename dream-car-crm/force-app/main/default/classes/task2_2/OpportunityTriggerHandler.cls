public class OpportunityTriggerHandler {


    public static void handleAfterUpdate(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap
    ) {


        Set<Id> opportunityIds = new Set<Id>();


        for (Opportunity opp : newList) {


            Opportunity oldOpp = oldMap.get(opp.Id);


            if (
                opp.StageName == 'Closed Won'
                &&
                oldOpp.StageName != 'Closed Won'
            ) {

                opportunityIds.add(opp.Id);

            }

        }



        if (!opportunityIds.isEmpty()) {

            PlannedSalesService.recalculateFromOpportunities(
                opportunityIds
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

}