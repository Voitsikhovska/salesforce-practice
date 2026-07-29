public class TriggerControl {
    public static Boolean isOpportunityTriggerDisabled() {
        return System.Label.Disable_Opportunity_Trigger == 'true';
    }

    public static Boolean isPlannedSalesTriggerDisabled() {
        return System.Label.Disable_Planned_Sales_Trigger == 'true';
    }
}