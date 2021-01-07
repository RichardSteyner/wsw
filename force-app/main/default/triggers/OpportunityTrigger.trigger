trigger OpportunityTrigger on Opportunity (after update) {
    if(ApexUtil.isOpportunityTriggerInvoked){ 
        Set<String> createOppIds = new Set<String>();
        Set<String> updateOppIds = new Set<String>();
        Set<String> convertOppIds = new Set<String>();
        Set<String> updateSalesOppIds = new Set<String>();
        for(Opportunity opp : trigger.new){
            if(opp.NS_Estimate_ID__c == null && opp.AccountId != null && opp.StageName == 'Estimate') createOppIds.add(opp.Id);
            if(opp.NS_Estimate_ID__c != null && opp.NS_ID__c == NULL && (opp.StageName == 'Purchase Order' || opp.Update_Items__c == true || trigger.oldMap.get(opp.Id).StageName == 'Estimate' || opp.Netsuite_Sync_Status__c == 'Error')) updateOppIds.add(opp.Id);
            if(opp.NS_Estimate_ID__c != null && opp.NS_ID__c == null && opp.StageName == 'Sales' && ( trigger.oldMap.get(opp.Id).StageName == 'Estimate' || trigger.oldMap.get(opp.Id).StageName == 'Purchase Order' || opp.Netsuite_Sync_Status__c == 'Error')) convertOppIds.add(opp.Id);
            if((trigger.oldMap.get(opp.Id).StageName != opp.StageName || opp.Netsuite_Sync_Status__c == 'Error') && (opp.StageName != 'Estimate' && opp.StageName != 'Purchase Order' && opp.StageName != 'Sales')){
                if(opp.NS_ID__c != null) updateSalesOppIds.add(opp.Id); else convertOppIds.add(opp.Id);
            }
            if((opp.Update_Items__c == true || trigger.oldMap.get(opp.Id).Shipping_Address__c != opp.Shipping_Address__c || trigger.oldMap.get(opp.Id).Blind_Ship__c != opp.Blind_Ship__c || trigger.oldMap.get(opp.Id).Ozlink__c != opp.Ozlink__c || 
                trigger.oldMap.get(opp.Id).Art_file_by_email__c != opp.Art_file_by_email__c || trigger.oldMap.get(opp.Id).In_Han_Date__c != opp.In_Han_Date__c || trigger.oldMap.get(opp.Id).Web_Order_Number__c != opp.Web_Order_Number__c || 
                trigger.oldMap.get(opp.Id).Order_processed_By__c != opp.Order_processed_By__c || trigger.oldMap.get(opp.Id).Graphics_Designer__c != opp.Graphics_Designer__c || 
                trigger.oldMap.get(opp.Id).Use_Art_Files_from_other_orders__c != opp.Use_Art_Files_from_other_orders__c) 
               && opp.StageName != 'Estimate' && opp.StageName != 'Purchase Order' && opp.NS_ID__c != null) updateSalesOppIds.add(opp.Id);
            if(opp.NS_Estimate_ID__c == null && opp.NS_ID__c == null && (opp.StageName != 'Estimate' && opp.StageName != 'Purchase Order')) convertOppIds.add(opp.Id);
        }
        if(!createOppIds.isEmpty()) NetsuiteMethods.createEstimate(createOppIds);
        if(!updateOppIds.isEmpty()) NetsuiteMethods.updateEstimate(updateOppIds);
        if(!convertOppIds.isEmpty()) NetsuiteMethods.convertSale(convertOppIds);
        if(!updateSalesOppIds.isEmpty()) NetsuiteMethods.updateSale(updateSalesOppIds);
    }
}