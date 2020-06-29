public class PicklistsManagerQueueable implements Queueable, Database.AllowsCallouts {

    private Id recordId;

    /* Variables for deploy Picklist__c */
    private Map<String, Picklist_Value__c> picklistValuesToInsert;
    private List<Picklist_Field__c> picklistFields;

    /* Variables for deploy Picklist_Dependency__c */
    private Picklist_Dependency__c pd;
    private List<Picklist_Dependency_Value__c> pdvs;

    /* Constructor for deploy Picklist__c */
    public PicklistsManagerQueueable(Id recordId, Map<String, Picklist_Value__c> picklistValuesToInsert, List<Picklist_Field__c> picklistFields){
        this.recordId = recordId;
        this.picklistValuesToInsert = picklistValuesToInsert;
        this.picklistFields = picklistFields;
    }

    /* Constructor for deploy Picklist_Dependency__c */
    public PicklistsManagerQueueable(Id recordId, Picklist_Dependency__c pd, List<Picklist_Dependency_Value__c> pdvs){
        this.recordId = recordId;
        this.pd = pd;
        this.pdvs = pdvs;
    }

    public void execute(QueueableContext context) {

        if(recordId.getSobjectType() == Schema.Picklist__c.SObjectType) {
            PicklistsManagerUtils.updateValueSet(picklistValuesToInsert, picklistFields.get(0).Object_Developer_Name__c, picklistFields.get(0).Field_Developer_Name__c);
            if(picklistFields.size() > 1) {
                picklistFields.remove(0);
                System.enqueueJob(new PicklistsManagerQueueable(recordId, picklistValuesToInsert, picklistFields));
            }
        }
        else if(recordId.getSobjectType() == Schema.Picklist_Dependency__c.SObjectType) {
            PicklistsManagerUtils.updatePicklistDependency(pd, pdvs);
        }


        
    }
}