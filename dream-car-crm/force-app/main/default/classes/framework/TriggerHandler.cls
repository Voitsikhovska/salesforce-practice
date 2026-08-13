public virtual class TriggerHandler {

    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
    }

    private String handlerName;

    public TriggerHandler() {
        this.handlerName = getHandlerName();
        if (!loopCountMap.containsKey(handlerName)) {
            loopCountMap.put(handlerName, new LoopCount());
        }
    }

    public void run() {
        if (!validateRun()) return;

        addToLoopCount();

        if (Trigger.isBefore) {
            if (Trigger.isInsert) beforeInsert();
            else if (Trigger.isUpdate) beforeUpdate();
            else if (Trigger.isDelete) beforeDelete();
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) afterInsert();
            else if (Trigger.isUpdate) afterUpdate();
            else if (Trigger.isDelete) afterDelete();
            else if (Trigger.isUndelete) afterUndelete();
        }
    }

    private Boolean validateRun() {
        if (!Trigger.isExecuting || Trigger.operationType == null) {
            throw new TriggerHandlerException('Trigger handler called outside of trigger execution');
        }
        return !bypassedHandlers.contains(handlerName);
    }

    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    private void addToLoopCount() {
        LoopCount lc = loopCountMap.get(handlerName);
        if (!lc.increment()) {
            throw new TriggerHandlerException('Max loop count reached for handler: ' + handlerName);
        }
    }

    private String getHandlerName() {
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    public static void bypass(String handlerName) { bypassedHandlers.add(handlerName); }
    public static void clearBypass(String handlerName) { bypassedHandlers.remove(handlerName); }

    private class LoopCount {
        private Integer max;
        private Integer count;
        public LoopCount() { this.max = 15; this.count = 0; }
        public Boolean increment() { this.count++; return this.count <= this.max; }
    }

    public class TriggerHandlerException extends Exception {}
}