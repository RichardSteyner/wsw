trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    
    if(ApexUtil.isAccountTriggerInvoked){
        if(trigger.isInsert){
            for(Account account : trigger.new){
            }
        }
        else{
            if(Trigger.isBefore){
                for(Account account : trigger.new){
                    if(account.NS_ID__c!=null && (account.Name != trigger.oldMap.get(account.Id).Name || account.NumberOfEmployees != trigger.oldMap.get(account.Id).NumberOfEmployees 
                        || account.Taxable__c != trigger.oldMap.get(account.Id).Taxable__c || account.Web_Approved_CB__c != trigger.oldMap.get(account.Id).Web_Approved_CB__c 
                        || account.Type_of_Customer__c != trigger.oldMap.get(account.Id).Type_of_Customer__c || account.Phone != trigger.oldMap.get(account.Id).Phone 
                        || account.Website != trigger.oldMap.get(account.Id).Website || account.OZlink_Bill_shipping_to_3rd__c != trigger.oldMap.get(account.Id).OZlink_Bill_shipping_to_3rd__c 
                        || account.OZlink_Billing_shipping_to_recip__c != trigger.oldMap.get(account.Id).OZlink_Billing_shipping_to_recip__c 
                        || account.Ozlink_Website__c != trigger.oldMap.get(account.Id).Ozlink_Website__c || account.CC_Processor__c != trigger.oldMap.get(account.Id).CC_Processor__c 
                      	|| account.AccountSource != trigger.oldMap.get(account.Id).AccountSource  || account.Price_Level__c != trigger.oldMap.get(account.Id).Price_Level__c
                        || account.Netsuite_Status__c != trigger.oldMap.get(account.Id).Netsuite_Status__c || account.Industry != trigger.oldMap.get(account.Id).Industry)){
                            account.Netsuite_To_Sync__c = true;
                            account.Netsuite_Sync_Status__c = 'Processing';
                            account.Netsuite_Sync_Error__c = '';
                        }
                }
            }
            else{
    			/*Set<Id> accIds = new Set<Id>();
                for(Account account : trigger.new){
                    if(account.NS_ID__c!=null && account.Name != trigger.oldMap.get(account.Id).Name || account.NumberOfEmployees != trigger.oldMap.get(account.Id).NumberOfEmployees 
                        || account.Taxable__c != trigger.oldMap.get(account.Id).Taxable__c || account.Web_Approved_CB__c != trigger.oldMap.get(account.Id).Web_Approved_CB__c 
                        || account.Type_of_Customer__c != trigger.oldMap.get(account.Id).Type_of_Customer__c || account.Phone != trigger.oldMap.get(account.Id).Phone 
                        || account.Website != trigger.oldMap.get(account.Id).Website || account.OZlink_Bill_shipping_to_3rd__c != trigger.oldMap.get(account.Id).OZlink_Bill_shipping_to_3rd__c 
                        || account.OZlink_Billing_shipping_to_recip__c != trigger.oldMap.get(account.Id).OZlink_Billing_shipping_to_recip__c 
                        || account.Ozlink_Website__c != trigger.oldMap.get(account.Id).Ozlink_Website__c ){
                            accIds.add(account.Id);
                            System.debug('AccountTrigger->Aquí enviaremos a Netsuite');
                        }
                }
                if(accIds.size()>0) NetsuitePostCustomer.postCustomersFromAccounts(accIds);*/
            }
        }
    }

}