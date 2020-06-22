public with sharing class PicklistsManagerUtils {
    
    /* Utilizza la libreria apex-mdapi (https://github.com/financialforcedev/apex-mdapi) per inserire o aggiornare i valori di una picklist */
    @future(callout = true)
    public static void updateValueSet(Map<String, String> picklistValuesToInsert, String sObjectDeveloperName, String fieldDeveloperName ) {
        MetadataService.MetadataPort mdapi = new MetadataService.MetadataPort();
        mdapi.SessionHeader = new MetadataService.SessionHeader_element();
        mdapi.SessionHeader.sessionId = UserInfo.getSessionId();
        
        MetadataService.CustomField fieldMdApi = (MetadataService.CustomField)mdapi.readMetadata('CustomField', new List<String>{ sObjectDeveloperName + '.' + fieldDeveloperName }).getRecords()[0];

        List<String> recordTypes = new List<String>();
        for(RecordType rt : [SELECT DeveloperName FROM RecordType WHERE SobjectType = :sObjectDeveloperName]) {
            recordTypes.add(sObjectDeveloperName + '.' + rt.DeveloperName);
        }

        List<MetadataService.RecordType> recordTypeMd = (List<MetadataService.RecordType>)mdapi.readMetadata('RecordType', recordTypes).getRecords();
        for(MetadataService.RecordType rt : recordTypeMd) {
            System.debug('MIODEB RECORDTYPE: ' + rt.fullName);
            System.debug('MIODEB RECORDTYPE: ' + rt);
        }

        for(MetadataService.RecordTypePicklistValue rtpv : recordTypeMd.get(0).picklistValues) {
            if(rtpv.picklist == fieldDeveloperName) {
                System.debug('MIODEB RECORDTYPEPICKLISTVALUE: ' + rtpv.picklist);

                List<String> existingPicklistValue = new List<String>();
                for(MetadataService.PicklistValue pv : rtpv.values) {
                    existingPicklistValue.add(pv.fullName);
                    System.debug('MIODEB PICKLISTVALUE: ' + pv.fullName);
                    System.debug('MIODEB PICKLISTVALUE: ' + pv);
                }
                for(String picklistValue : picklistValuesToInsert.keySet()) {
                    if(!existingPicklistValue.contains(picklistValue)) {
                        MetadataService.PicklistValue newPv = new MetadataService.PicklistValue();
                        newPv.fullName = picklistValue;
                        newPv.default_x = false;
                        rtpv.values.add(newPv);
                    }
                }
            }
        }
            
        for(MetadataService.CustomValue existing : fieldMdApi.valueSet.valueSetDefinition.value) {

            // Caso in cui è presente un valore di picklist ma non è presente un corrispondente record di Valore_di_picklist__c
            if (picklistValuesToInsert.get(existing.fullName) == null) {
                picklistValuesToInsert.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            } 
            
            // Caso in cui è presente un valore di picklist ma il record di Valore_di_picklist__c è uguale per valore ed etichetta
            else if(picklistValuesToInsert.keySet().contains(existing.fullName) && picklistValuesToInsert.get(existing.fullName) == existing.label) {
                picklistValuesToInsert.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            }
            
            // Caso in cui è presente un valore di picklist ma il record di Valore_di_picklist__c è diverso per etichetta ma non per valore
            else if(picklistValuesToInsert.keySet().contains(existing.fullName) && picklistValuesToInsert.get(existing.fullName) != existing.label) {
                existing.label = picklistValuesToInsert.get(existing.fullName); // Aggiorno l'esistente
                picklistValuesToInsert.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            }
        }
        
        for(String key : picklistValuesToInsert.keySet()) {
            MetadataService.CustomValue value = new MetadataService.CustomValue();
            value.fullName = key;
            value.label = picklistValuesToInsert.get(key);
            value.default_x = false ;
            value.isActive = true;
            
            fieldMdApi.valueSet.valueSetDefinition.value.add(value);
        }

        /*for(MetadataUtils.RecordType recordType : recordTypeMd){

            for(MetadataService.RecordTypePicklistValue picklist : recordType.picklistValues){
                
                MetadataService.RecordTypePicklistValue rtPicklist = new GVS_MetadataUtils.RecordTypePicklistValue();

                    Map<String, GVS_MetadataUtils.PicklistValue> mapValues = new Map<String, GVS_MetadataUtils.PicklistValue>();
                    for(GVS_MetadataUtils.PicklistValue picklistValue : picklist.values){
                        // mapValues.put(picklistValue.fullName, picklistValue);
                        mapValues.put(EncodingUtil.urlDecode(picklistValue.fullName, 'UTF-8'), picklistValue);
                    }
                    for(GVS_MetadataUtils.CustomValue value : mapGlobalValueSetMD.get(mapRecordTypePicklist.get(recordType.fullName).get(picklist.picklist)).customValue){
                        if(value.isActive != false){
                        if(mapValues.containsKey(value.fullName)){
                            mapValues.get(value.fullName).isActive = value.isActive;
                        } else {
                            GVS_MetadataUtils.PicklistValue pv = new GVS_MetadataUtils.PicklistValue();
                            pv.fullName = value.fullName;
                            pv.isActive = value.isActive;
                            pv.description = value.description;
                            pv.default_x = value.default_x;
                            picklist.values.add(pv);
                            mapValues.put(pv.fullName, pv);
                        }
                        }
                    }
                    rt.picklistValues.add(picklist);     
                //}
              }
              updateRecordType.add(rt);
            }
          }*/
        
        
        List<MetadataService.Metadata> metaDataToUpdate = new List<MetadataService.Metadata>();
        metaDataToUpdate.add(fieldMdApi);
        metaDataToUpdate.addAll(recordTypeMd);
        mdapi.updateMetadata(metaDataToUpdate);
    }
}
