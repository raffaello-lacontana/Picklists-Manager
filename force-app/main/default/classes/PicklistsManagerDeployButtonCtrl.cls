public with sharing class PicklistsManagerDeployButtonCtrl {

    @AuraEnabled
    public static Id deploy(Id recordId) {
        Id jobId;
        if(recordId.getSobjectType() == Schema.Picklist__c.SObjectType) {
            jobId = PicklistsManagerUtils.deployPicklist(recordId);
            
        }
        else if(recordId.getSobjectType() == Schema.Picklist_Dependency__c.SObjectType) {
            jobId = PicklistsManagerUtils.deployPicklistDependency(recordId);
        }
        return jobId;
    }
}