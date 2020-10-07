trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    
    if(ApexUtil.isLeadTriggerInvoked){
        if(trigger.isInsert){
            for(Lead lead : trigger.new){
            }
        }
        else{
            if(Trigger.isBefore){
                for(Lead lead : trigger.new){
                    if(lead.NS_ID__c!=null && lead.LastName != trigger.oldMap.get(lead.Id).LastName || lead.NumberOfEmployees != trigger.oldMap.get(lead.Id).NumberOfEmployees 
                        || lead.Taxable__c != trigger.oldMap.get(lead.Id).Taxable__c || lead.Web_Approved_CB__c != trigger.oldMap.get(lead.Id).Web_Approved_CB__c 
                        || lead.Type_of_Customer__c != trigger.oldMap.get(lead.Id).Type_of_Customer__c || lead.Phone != trigger.oldMap.get(lead.Id).Phone 
                        || lead.Website != trigger.oldMap.get(lead.Id).Website || lead.OZlink_Bill_shipping_to_3rd__c != trigger.oldMap.get(lead.Id).OZlink_Bill_shipping_to_3rd__c 
                        || lead.OZlink_Billing_shipping_to_recip__c != trigger.oldMap.get(lead.Id).OZlink_Billing_shipping_to_recip__c 
                        || lead.Ozlink_Website__c != trigger.oldMap.get(lead.Id).Ozlink_Website__c || lead.CC_Processor__c != trigger.oldMap.get(lead.Id).CC_Processor__c 
                      	|| lead.LeadSource != trigger.oldMap.get(lead.Id).LeadSource  || lead.Price_Level__c != trigger.oldMap.get(lead.Id).Price_Level__c
                        || lead.Netsuite_Status__c != trigger.oldMap.get(lead.Id).Netsuite_Status__c || lead.Industry != trigger.oldMap.get(lead.Id).Industry){
                            lead.Netsuite_To_Sync__c = true;
                            lead.Netsuite_Sync_Status__c = 'Processing';
                            lead.Netsuite_Sync_Error__c = '';
                        }
                }
            }
            else{
    			/*Set<Id> leadIds = new Set<Id>();
                for(Lead lead : trigger.new){
                    if(lead.NS_ID__c!=null && lead.LastName != trigger.oldMap.get(lead.Id).LastName || lead.NumberOfEmployees != trigger.oldMap.get(lead.Id).NumberOfEmployees 
                        || lead.Taxable__c != trigger.oldMap.get(lead.Id).Taxable__c || lead.Web_Approved_CB__c != trigger.oldMap.get(lead.Id).Web_Approved_CB__c 
                        || lead.Type_of_Customer__c != trigger.oldMap.get(lead.Id).Type_of_Customer__c || lead.Phone != trigger.oldMap.get(lead.Id).Phone 
                        || lead.Website != trigger.oldMap.get(lead.Id).Website || lead.OZlink_Bill_shipping_to_3rd__c != trigger.oldMap.get(lead.Id).OZlink_Bill_shipping_to_3rd__c 
                        || lead.OZlink_Billing_shipping_to_recip__c != trigger.oldMap.get(lead.Id).OZlink_Billing_shipping_to_recip__c 
                        || lead.Ozlink_Website__c != trigger.oldMap.get(lead.Id).Ozlink_Website__c ){
                            leadIds.add(lead.Id);
                            System.debug('LeadTrigger->Aquí enviaremos a Netsuite');
                        }
                }
                if(leadIds.size()>0) NetsuitePostCustomer.postCustomersFromLeads(leadIds);*/
            }
        }
    }

}