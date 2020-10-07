trigger ContactTrigger on Contact (before insert, before update, after insert, after update) {
    
    if(ApexUtil.isContactTriggerInvoked){
        if(trigger.isInsert){
            for(Contact contact : trigger.new){
            }
        }
        else{
            if(Trigger.isBefore){
                for(Contact contact : trigger.new){
                    if(contact.NS_ID__c!=null && contact.FirstName != trigger.oldMap.get(contact.Id).FirstName || contact.LastName != trigger.oldMap.get(contact.Id).LastName 
                        || contact.Email != trigger.oldMap.get(contact.Id).Email || contact.Global_Subscription_Status__c != trigger.oldMap.get(contact.Id).Global_Subscription_Status__c 
                        || contact.Inactive__c != trigger.oldMap.get(contact.Id).Inactive__c || contact.Phone != trigger.oldMap.get(contact.Id).Phone){
                            contact.Netsuite_To_Sync__c = true;
                            contact.Netsuite_Sync_Status__c = 'Processing';
                            contact.Netsuite_Sync_Error__c = '';
                        }
                }
            }
            else{
    			/*Set<Id> conIds = new Set<Id>();
                for(Contact contact : trigger.new){
                    if(contact.NS_ID__c!=null && contact.FirstName != trigger.oldMap.get(contact.Id).FirstName || contact.LastName != trigger.oldMap.get(contact.Id).LastName 
                        || contact.Email != trigger.oldMap.get(contact.Id).Email || contact.Global_Subscription_Status__c != trigger.oldMap.get(contact.Id).Global_Subscription_Status__c 
                        || contact.Inactive__c != trigger.oldMap.get(contact.Id).Inactive__c || contact.Phone != trigger.oldMap.get(contact.Id).Phone){
                            conIds.add(contact.Id);
                            System.debug('ContactTrigger->Aquí enviaremos a Netsuite');
                        }
                }*/
                //if(conIds.size()>0) NetsuitePostContact.updateContacts(conIds);
            }
        }
    }

}