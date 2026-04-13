// ── Publish Platform Events ───────────────────────────────────────────────────
public class OrderEventPublisher {
    public static void publishOrderCreated(List<Order__c> orders) {
        List<Order_Event__e> events = new List<Order_Event__e>();
        for (Order__c order : orders) {
            events.add(new Order_Event__e(
                Order_Id__c = order.Id,
                Action__c = 'CREATED',
                Account_Id__c = order.Account__c,
                Total_Amount__c = order.Total_Amount__c
            ));
        }
        List<Database.SaveResult> results = EventBus.publish(events);
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Event publish failed for Order ' + orders[i].Id + ': ' + err.getMessage());
                }
            }
        }
    }
}

// ── Subscribe to Platform Events (Apex Trigger) ───────────────────────────────
trigger OrderEventTrigger on Order_Event__e (after insert) {
    OrderEventHandler handler = new OrderEventHandler();
    handler.handleEvents(Trigger.new);
}

public class OrderEventHandler {
    public void handleEvents(List<Order_Event__e> events) {
        List<Task> tasksToCreate = new List<Task>();
        for (Order_Event__e event : events) {
            if (event.Action__c == 'CREATED') {
                tasksToCreate.add(new Task(
                    Subject = 'Process Order: ' + event.Order_Id__c,
                    WhatId = event.Account_Id__c,
                    Status = 'Not Started',
                    Priority = event.Total_Amount__c > 100000 ? 'High' : 'Normal'
                ));
            }
        }
        if (!tasksToCreate.isEmpty()) {
            Database.SaveResult[] results = Database.insert(tasksToCreate, false);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'DML Error: ' + err.getMessage());
                    }
                }
            }
        }
        // Set resume checkpoint for high-volume events
        if (!events.isEmpty()) {
            EventBus.TriggerContext.currentContext().setResumeCheckpoint(events[events.size() - 1].ReplayId);
        }
    }
}
