trigger AccountChangeEventTrigger on AccountChangeEvent (after insert) {
    AccountCdcHandler handler = new AccountCdcHandler();
    handler.handleChanges(Trigger.new);
}

public class AccountCdcHandler {
    public void handleChanges(List<AccountChangeEvent> events) {
        for (AccountChangeEvent event : events) {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            String changeType = header.getChangeType();
            List<String> changedFields = header.getChangedFields();
            List<String> recordIds = header.getRecordIds();

            switch on changeType {
                when 'CREATE' { handleCreate(recordIds, event); }
                when 'UPDATE' { handleUpdate(recordIds, changedFields, event); }
                when 'DELETE' { handleDelete(recordIds); }
                when 'UNDELETE' { handleUndelete(recordIds); }
            }
        }
    }

    private void handleCreate(List<String> recordIds, AccountChangeEvent event) {
        System.enqueueJob(new AccountSyncQueueable(recordIds, 'CREATE'));
    }

    private void handleUpdate(List<String> recordIds, List<String> changedFields, AccountChangeEvent event) {
        // Only sync if relevant fields changed
        Set<String> relevantFields = new Set<String>{ 'Name', 'Industry', 'BillingAddress' };
        Set<String> changed = new Set<String>(changedFields);
        changed.retainAll(relevantFields);
        if (!changed.isEmpty()) {
            System.enqueueJob(new AccountSyncQueueable(recordIds, 'UPDATE'));
        }
    }

    private void handleDelete(List<String> recordIds) {
        System.enqueueJob(new AccountSyncQueueable(recordIds, 'DELETE'));
    }

    private void handleUndelete(List<String> recordIds) {
        System.enqueueJob(new AccountSyncQueueable(recordIds, 'CREATE'));
    }
}
