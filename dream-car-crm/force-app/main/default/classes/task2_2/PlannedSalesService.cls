public class PlannedSalesService {

    private static Boolean isRunning = false;


    public static void recalculateFromOpportunities(
        Set<Id> opportunityIds
    ) {

        if (
            isRunning ||
            opportunityIds == null ||
            opportunityIds.isEmpty()
        ) {
            return;
        }


        try {

            isRunning = true;


            List<Opportunity> opportunities = [
                SELECT Id,
                       CloseDate
                FROM Opportunity
                WHERE Id IN :opportunityIds
            ];


            recalculateByOpportunities(opportunities);


        } finally {

            isRunning = false;

        }

    }




    public static void recalculateFromDeletedOpportunities(
        List<Opportunity> deletedOpportunities
    ) {

        if (
            isRunning ||
            deletedOpportunities == null ||
            deletedOpportunities.isEmpty()
        ) {
            return;
        }


        try {

            isRunning = true;


            recalculateByOpportunities(
                deletedOpportunities
            );


        } finally {

            isRunning = false;

        }

    }





    public static void recalculateFromPlannedSales(
        List<Planned_Sale__c> plannedSales
    ) {

        if (
            isRunning ||
            plannedSales == null ||
            plannedSales.isEmpty()
        ) {
            return;
        }


        try {

            isRunning = true;


            recalculate(plannedSales);


        } finally {

            isRunning = false;

        }

    }





    private static void recalculateByOpportunities(
        List<Opportunity> opportunities
    ) {


        Set<Integer> years = new Set<Integer>();
        Set<Integer> months = new Set<Integer>();


        for (Opportunity opp : opportunities) {


            if (opp.CloseDate != null) {

                years.add(
                    opp.CloseDate.year()
                );

                months.add(
                    opp.CloseDate.month()
                );

            }

        }


        if (years.isEmpty()) {
            return;
        }




        List<Planned_Sale__c> plannedSales = [

            SELECT Id,
                   Year__c,
                   Month__c,
                   Car_Type__c

            FROM Planned_Sale__c

            WHERE Year__c IN :years

            AND Month__c IN :months

        ];



        recalculate(plannedSales);

    }






    private static void recalculate(
        List<Planned_Sale__c> plannedSales
    ) {


        if (
            plannedSales == null ||
            plannedSales.isEmpty()
        ) {
            return;
        }




        Set<Integer> years = new Set<Integer>();
        Set<Integer> months = new Set<Integer>();



        for (Planned_Sale__c ps : plannedSales) {


            years.add(
                Integer.valueOf(ps.Year__c)
            );


            months.add(
                Integer.valueOf(ps.Month__c)
            );

        }





        List<OpportunityLineItem> lineItems = [

            SELECT Quantity,
                   TotalPrice,
                   Opportunity.CloseDate,
                   PricebookEntry.Product2.Condition__c

            FROM OpportunityLineItem

            WHERE Opportunity.StageName = 'Closed Won'

            AND CALENDAR_YEAR(Opportunity.CloseDate) IN :years

            AND CALENDAR_MONTH(Opportunity.CloseDate) IN :months

        ];






        Map<String, Decimal> countMap =
            new Map<String, Decimal>();


        Map<String, Decimal> amountMap =
            new Map<String, Decimal>();





        for (OpportunityLineItem oli : lineItems) {


            if (
                oli.Opportunity.CloseDate == null ||
                oli.PricebookEntry.Product2.Condition__c == null
            ) {
                continue;
            }




            String key =
                oli.Opportunity.CloseDate.year()
                + '-'
                + oli.Opportunity.CloseDate.month()
                + '-'
                + oli.PricebookEntry.Product2.Condition__c;





            Decimal count =
                countMap.containsKey(key)
                ? countMap.get(key)
                : 0;




            Decimal amount =
                amountMap.containsKey(key)
                ? amountMap.get(key)
                : 0;




            countMap.put(
                key,
                count + oli.Quantity
            );



            amountMap.put(
                key,
                amount + oli.TotalPrice
            );

        }







        List<Planned_Sale__c> updates =
            new List<Planned_Sale__c>();





        for (Planned_Sale__c ps : plannedSales) {


            String key =
                Integer.valueOf(ps.Year__c)
                + '-'
                + Integer.valueOf(ps.Month__c)
                + '-'
                + ps.Car_Type__c;





            updates.add(
                new Planned_Sale__c(

                    Id = ps.Id,


                    Count_of_Cars_Sold__c =
                        countMap.containsKey(key)
                        ? countMap.get(key)
                        : 0,



                    Total_Amount_Earned__c =
                        amountMap.containsKey(key)
                        ? amountMap.get(key)
                        : 0

                )
            );

        }






        if (
            Schema.sObjectType.Planned_Sale__c.isUpdateable()
            &&
            !updates.isEmpty()
        ) {

            update updates;

        }


    }

}