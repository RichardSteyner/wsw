trigger OpportunityLineItemTrigger on OpportunityLineItem (after insert, after update, after delete) {
    if(ApexUtil.isOliTriggerInvoked){
        Set<String> oppIds = new Set<String>();
        if(trigger.isInsert){
            for(OpportunityLineItem oli : trigger.new) oppIds.add(oli.OpportunityId);
        }else if(trigger.isUpdate){
            for(OpportunityLineItem oli : trigger.new){ if(oli.Quantity != trigger.oldMap.get(oli.Id).Quantity || oli.UnitPrice != trigger.oldMap.get(oli.Id).UnitPrice || oli.NS_Price_Code__c != trigger.oldMap.get(oli.Id).NS_Price_Code__c || oli.Description != trigger.oldMap.get(oli.Id).Description) oppIds.add(oli.OpportunityId);}
        }else{ for(OpportunityLineItem oli : trigger.old) oppIds.add(oli.OpportunityId);}
        
        if(!oppIds.isEmpty()){
            List<Opportunity> oppList = new List<Opportunity>();
            for(Opportunity opp : [SELECT Id,Update_Items__c FROM Opportunity WHERE Id IN: oppIds]){
                opp.Update_Items__c = true;
                oppList.add(opp);
            }    
            ApexUtil.isOpportunityTriggerInvoked = false;
            if(!oppList.isEmpty()) update oppList;
            ApexUtil.isOpportunityTriggerInvoked = true;
        }
    }
}