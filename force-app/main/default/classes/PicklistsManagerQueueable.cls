public class PicklistsManagerQueueable implements Queueable, Database.AllowsCallouts {

    private Map<String, String> picklistValuesToInsert;
    private List<Picklist_Field__c> picklistFields;

    public PicklistsManagerQueueable(Map<String, String> picklistValuesToInsert, List<Picklist_Field__c> picklistFields){
        this.picklistValuesToInsert = picklistValuesToInsert;
        this.picklistFields = picklistFields;   
    }

    public void execute(QueueableContext context) {
        PicklistsManagerUtils.updateValueSet(picklistValuesToInsert, picklistFields.get(0).Object_Developer_Name__c, picklistFields.get(0).Field_Developer_Name__c);
        
        if(picklistFields.size() > 1) {
            picklistFields.remove(0);
            System.enqueueJob(new PicklistsManagerQueueable(picklistValuesToInsert, picklistFields));
        }
    }
}