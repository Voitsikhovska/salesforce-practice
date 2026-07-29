public class PlannedSalesTriggerHandler {

    public static void handle(List<Planned_Sale__c> records) {
        PlannedSalesService.recalculateFromPlannedSales(records);
    }
}