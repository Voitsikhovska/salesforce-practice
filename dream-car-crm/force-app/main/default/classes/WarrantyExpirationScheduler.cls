public class WarrantyExpirationScheduler implements Schedulable {

    public static final Integer SCOPE_SIZE = 200;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WarrantyExpirationBatch(), SCOPE_SIZE);
    }

    public static String scheduleDaily() {
        String cronExpression = '0 0 2 * * ?';
        return System.schedule('Warranty Expiration Daily Batch', cronExpression, new WarrantyExpirationScheduler());
    }
}