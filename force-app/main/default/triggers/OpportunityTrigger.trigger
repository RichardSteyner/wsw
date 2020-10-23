trigger OpportunityTrigger on Opportunity (before insert, before update, after update) {
    if(ApexUtil.isOpportunityTriggerInvoked){
        if(trigger.isBefore){
            if(trigger.isInsert){
                for(Opportunity opp : trigger.new){
                    if(opp.StageName == 'Estimate' && opp.Estimate_Date__c == null) opp.Estimate_Date__c = system.today();
                }
            }
            else{
                for(Opportunity opp : trigger.new){
                    if(opp.NS_ID__c!=null && opp.Name != trigger.oldMap.get(opp.Id).Name || opp.StageName != trigger.oldMap.get(opp.Id).StageName 
                       || opp.Balance__c != trigger.oldMap.get(opp.Id).Balance__c || opp.Web_Order_Number__c != trigger.oldMap.get(opp.Id).Web_Order_Number__c
                       || opp.Order_Detail__c != trigger.oldMap.get(opp.Id).Order_Detail__c || opp.Order__c != trigger.oldMap.get(opp.Id).Order__c
                       || opp.Warehouse_Notes__c != trigger.oldMap.get(opp.Id).Warehouse_Notes__c || opp.Art_file_by_email__c != trigger.oldMap.get(opp.Id).Art_file_by_email__c
                       || opp.Email__c != trigger.oldMap.get(opp.Id).Email__c || opp.Discount_Total__c != trigger.oldMap.get(opp.Id).Discount_Total__c
                       || opp.Ship_Date__c != trigger.oldMap.get(opp.Id).Ship_Date__c || opp.Ship_Method__c != trigger.oldMap.get(opp.Id).Ship_Method__c
                       || opp.Shipping_Cost__c != trigger.oldMap.get(opp.Id).Shipping_Cost__c || opp.Netsuite_Status__c != trigger.oldMap.get(opp.Id).Netsuite_Status__c
                       || opp.Subtotal__c != trigger.oldMap.get(opp.Id).Subtotal__c || opp.Tax_Total__c != trigger.oldMap.get(opp.Id).Tax_Total__c
                       || opp.Transaction_Date__c != trigger.oldMap.get(opp.Id).Transaction_Date__c || opp.Document_Number__c != trigger.oldMap.get(opp.Id).Document_Number__c){
                           //opp.Netsuite_To_Sync__c = true;
                           //opp.Netsuite_Sync_Status__c = 'Processing';
                           //opp.Netsuite_Sync_Error__c = '';
                       }
                    //if(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient') != null && account.recordtypeId.equals(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId()) && (account.LastName != trigger.oldMap.get(account.Id).LastName || account.PersonEmail != trigger.oldMap.get(account.Id).PersonEmail)) account.Authorize_To_Sync__c = true;
                }
            }
        }else{     
            if(trigger.isUpdate){
                Set<String> createOppIds = new Set<String>();
                Set<String> updateOppIds = new Set<String>();
                Set<String> convertOppIds = new Set<String>();  
                for(Opportunity opp : trigger.new){
                    if(opp.NS_Estimate_ID__c == null && opp.AccountId != null && opp.StageName == 'Estimate') createOppIds.add(opp.Id);
                    if(opp.NS_Estimate_ID__c != null && opp.StageName == 'Purchase Order' && (trigger.oldMap.get(opp.Id).StageName == 'Estimate' || opp.Netsuite_Sync_Status__c == 'Error')) updateOppIds.add(opp.Id);
                    if(opp.NS_Estimate_ID__c != null && opp.NS_ID__c == null && opp.StageName == 'Sales' && (trigger.oldMap.get(opp.Id).StageName == 'Purchase Order' || opp.Netsuite_Sync_Status__c == 'Error')) convertOppIds.add(opp.Id);
                }
                if(!createOppIds.isEmpty()) NetsuiteMethods.createEstimate(createOppIds);
                if(!updateOppIds.isEmpty()) NetsuiteMethods.updateEstimate(updateOppIds);
                if(!convertOppIds.isEmpty()) NetsuiteMethods.convertSale(convertOppIds);
            }
        }
        
    }
}