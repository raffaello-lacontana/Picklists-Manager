public with sharing class PicklistsManagerSynchButtonCtrl {
    

    @AuraEnabled
    public static Id synch(Id recordId) {
        return PicklistsManagerUtils.synchronizePicklist(recordId);
    }
}
