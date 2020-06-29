public with sharing class PicklistsManagerDeployButtonCtrl {
    

    @AuraEnabled
    public static Id deploy(Id recordId) {
        return PicklistsManagerUtils.deployPicklist(recordId);
    }
}