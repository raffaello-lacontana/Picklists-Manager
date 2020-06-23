// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

/*Map<String, String> picklistValuesToInsert = new Map<String, String>();
picklistValuesToInsert.put('FI', 'Firenze');
picklistValuesToInsert.put('FG', 'Foggia');

PicklistsManagerUtils.updateValueSet(picklistValuesToInsert, 'Account', 'Provincia__c');*/

PicklistsManagerUtils.synchronizePicklist('a001j000005LGn5AAG');