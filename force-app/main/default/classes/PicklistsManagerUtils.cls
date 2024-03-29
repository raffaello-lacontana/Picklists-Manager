public with sharing class PicklistsManagerUtils {

    /* Deploy picklists */
    public static Id deployPicklist(Id recordId) {
        Map<String, Picklist_Value__c> picklistValuesToInsert = getPicklistValuesToInsert(recordId);
        List<Picklist_Field__c> picklistFields = getPicklistFields(recordId);
        Id jobId = System.enqueueJob(new PicklistsManagerQueueable(recordId, picklistValuesToInsert, picklistFields));
        return jobId;
    }

    /* Deploy picklist dependencies */
    public static Id deployPicklistDependency(Id recordId) {
        Picklist_Dependency__c pd = [SELECT Object_Developer_Name__c, Controlling_Field_Developer_Name__c, Dependent_Field_Developer_Name__c FROM Picklist_Dependency__c WHERE Id = :recordId];
        List<Picklist_Dependency_Value__c> pdvs = [SELECT Controlling_Field_Value__c, Dependent_Field_Value__c  FROM Picklist_Dependency_Value__c WHERE Picklist_dependency__c = :pd.Id];
        Id jobId = System.enqueueJob(new PicklistsManagerQueueable(recordId, pd, pdvs));
        return jobId;
    }

    private static Map<String, Picklist_Value__c> getPicklistValuesToInsert(Id recordId) {
        Map<String, Picklist_Value__c> retValue = new Map<String, Picklist_Value__c>();
        for(Picklist_Value__c pv : [SELECT API_Name__c, Label__c, Default__c, Is_Active__c FROM Picklist_Value__c WHERE Picklist__c = :recordId]) {
            retValue.put(pv.API_Name__c, pv);
        }
        return retValue;
    }

    private static List<Picklist_Field__c> getPicklistFields(Id recordId) {
        return [SELECT Object_Developer_Name__c, Field_Developer_Name__c FROM Picklist_Field__c WHERE Picklist__c = :recordId];
    }
    
    /* Utilizza la libreria apex-mdapi (https://github.com/financialforcedev/apex-mdapi) per inserire o aggiornare i valori di una picklist */
    //@future(callout = true)
    public static void updateValueSet(Map<String, Picklist_Value__c> picklistValuesToInsert, String sObjectDeveloperName, String fieldDeveloperName ) {
        List<MetadataService.Metadata> metaDataToUpdate = new List<MetadataService.Metadata>();
        MetadataService.MetadataPort mdapi = new MetadataService.MetadataPort();
        mdapi.SessionHeader = new MetadataService.SessionHeader_element();
        mdapi.SessionHeader.sessionId = UserInfo.getSessionId();
        
        MetadataService.CustomField fieldMetadata = getFieldMetadata(picklistValuesToInsert, sObjectDeveloperName, fieldDeveloperName, mdapi);
        List<MetadataService.RecordType> recordTypeMetadata = getRecordTypeMetadata(picklistValuesToInsert, sObjectDeveloperName, fieldDeveloperName, mdapi);
     
        metaDataToUpdate.add(fieldMetadata);
        if(recordTypeMetadata != null) {
            metaDataToUpdate.addAll(recordTypeMetadata);
        }
        

        mdapi.updateMetadata(metaDataToUpdate);
    }

    public static void updatePicklistDependency(Picklist_Dependency__c pd, List<Picklist_Dependency_Value__c> pdvs) {
        List<MetadataService.Metadata> metaDataToUpdate = new List<MetadataService.Metadata>();
        MetadataService.MetadataPort mdapi = new MetadataService.MetadataPort();
        mdapi.SessionHeader = new MetadataService.SessionHeader_element();
        mdapi.SessionHeader.sessionId = UserInfo.getSessionId();

        MetadataService.CustomField fieldMetadataDependency = getFieldMetadataDependency(pdvs, pd.Object_Developer_Name__c, pd.Controlling_Field_Developer_Name__c, pd.Dependent_Field_Developer_Name__c, mdapi);
        metaDataToUpdate.add(fieldMetadataDependency);
        mdapi.updateMetadata(metaDataToUpdate);
    }

    private static MetadataService.CustomField getFieldMetadataDependency(List<Picklist_Dependency_Value__c> pdvs, String sObjectDeveloperName, String controllingFieldDeveloperName, String dependentFieldDeveloperName, MetadataService.MetadataPort mdapi) {
        
        // Map Dependent Value -> List Controlling Values
        Map<String, List<String>> valuesMap = new Map<String, List<String>>();
        for(Picklist_Dependency_Value__c pdv : pdvs) {
            if(valuesMap.get(pdv.Dependent_Field_Value__c) == null) {
                valuesMap.put(pdv.Dependent_Field_Value__c, new List<String>());
            }
            valuesMap.get(pdv.Dependent_Field_Value__c).add(pdv.Controlling_Field_Value__c);
        }
        
        MetadataService.CustomField customField = (MetadataService.CustomField)mdapi.readMetadata('CustomField', new List<String>{ sObjectDeveloperName + '.' + dependentFieldDeveloperName }).getRecords()[0];
        System.debug('MIODEBUG1 CustomField: ' + customField);
        System.debug('MIODEBUG1 CustomField.fullName: ' + customField.fullName);
        System.debug('MIODEBUG2 CustomField.valueSet.controllingField: ' + customField.valueSet.controllingField);
        System.debug('MIODEBUG2 CustomField.valueSet.restricted: ' + customField.valueSet.restricted);

        customField.valueSet.controllingField = controllingFieldDeveloperName; // Es. Comune__c

        List<MetadataService.ValueSettings> valueSettings = new List<MetadataService.ValueSettings>();
        for(String dependentFieldValue : valuesMap.keySet()) {
            MetadataService.ValueSettings valueSetting = new MetadataService.ValueSettings();
            valueSetting.valueName = dependentFieldValue;
            valueSetting.controllingFieldValue = new List<String>();
            for(String controllingFieldValue : valuesMap.get(dependentFieldValue)) {
                valueSetting.controllingFieldValue.add(controllingFieldValue);    
            }
            valueSettings.add(valueSetting);
        }

        customField.valueSet.valueSettings = valueSettings;
        for(MetadataService.ValueSettings valueSetting: customField.valueSet.valueSettings) {
            System.debug('MIODEBUG3 CustomField.valueSet.valueSetName.valueSetting.valueName: ' + valueSetting.valueName); // Es. MI
            for(String controllingFieldValue : valueSetting.controllingFieldValue) {
                System.debug('MIODEBUG4 controllingFieldValue: ' + controllingFieldValue); // Es. Abbiategrasso
            }
        }

        return customField;
    }

    private static MetadataService.CustomField getFieldMetadata(Map<String, Picklist_Value__c> picklistValuesToInsert, String sObjectDeveloperName, String fieldDeveloperName, MetadataService.MetadataPort mdapi) {
        Map<String, Picklist_Value__c> picklistValues = picklistValuesToInsert.clone();
        MetadataService.CustomField fieldMetadata = (MetadataService.CustomField)mdapi.readMetadata('CustomField', new List<String>{ sObjectDeveloperName + '.' + fieldDeveloperName }).getRecords()[0];

        for(MetadataService.CustomValue existing : fieldMetadata.valueSet.valueSetDefinition.value) {

            // Caso in cui è presente un valore di picklist ma non è presente un corrispondente record di Valore_di_picklist__c
            if (picklistValues.get(existing.fullName) == null) {
                picklistValues.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            } 
            
            // Caso in cui è presente un valore di picklist ma il record di Valore_di_picklist__c è uguale per valore ed etichetta
            else if(picklistValues.keySet().contains(existing.fullName) && picklistValues.get(existing.fullName).Label__c == existing.label) {
                picklistValues.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            }
            
            // Caso in cui è presente un valore di picklist ma il record di Valore_di_picklist__c è diverso per etichetta ma non per valore
            else if(picklistValues.keySet().contains(existing.fullName) && picklistValues.get(existing.fullName).Label__c != existing.label) {
                existing.label = picklistValues.get(existing.fullName).Label__c; // Aggiorno l'esistente
                picklistValues.remove(existing.fullName); // Rimuove dalla lista dei valori da inserire
            }
        }
        
        for(String key : picklistValues.keySet()) {
            MetadataService.CustomValue value = new MetadataService.CustomValue();
            value.fullName = key;
            value.label = picklistValues.get(key).Label__c;
            //value.default_x = false;
            //value.isActive = true;
            value.default_x = picklistValues.get(key).Default__c;
            value.isActive = picklistValues.get(key).Is_Active__c;
            
            fieldMetadata.valueSet.valueSetDefinition.value.add(value);
        }

        return fieldMetadata;
    }

    private static List<MetadataService.RecordType> getRecordTypeMetadata(Map<String, Picklist_Value__c> picklistValuesToInsert, String sObjectDeveloperName, String fieldDeveloperName, MetadataService.MetadataPort mdapi) {        
        List<MetadataService.RecordType> recordTypeMetadata = null;
        List<String> recordTypes = new List<String>();

        // Check if record types exist
        for(RecordType rt : [SELECT DeveloperName FROM RecordType WHERE SobjectType = :sObjectDeveloperName]) {
            recordTypes.add(sObjectDeveloperName + '.' + rt.DeveloperName);
        }

        if(!recordTypes.isEmpty()) {
            recordTypeMetadata = (List<MetadataService.RecordType>)mdapi.readMetadata('RecordType', recordTypes).getRecords();

            // Cycle on RecordTypes
            for(MetadataService.RecordType rt : recordTypeMetadata) {

                // Cycle on RecordTypePicklistValues
                for(MetadataService.RecordTypePicklistValue rtpv : rt.picklistValues) {
                    if(rtpv.picklist == fieldDeveloperName) {

                        List<String> existingPicklistValue = new List<String>();

                        // Cycle and store existing PicklistValues
                        for(MetadataService.PicklistValue pv : rtpv.values) {
                            existingPicklistValue.add(pv.fullName);
                        }

                        // Add PicklistValues to upsert to metadata
                        for(String picklistValue : picklistValuesToInsert.keySet()) {
                            // Add new values
                            if(!existingPicklistValue.contains(picklistValue)) {
                                MetadataService.PicklistValue newPv = new MetadataService.PicklistValue();
                                newPv.fullName = picklistValue;
                                newPv.default_x = false;
                                rtpv.values.add(newPv);
                            }
                        }
                    }
                }
            }
        }

        return recordTypeMetadata;
    }
}
