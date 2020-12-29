trigger AddressTrigger on Address__c (after insert, after update) {
    if(ApexUtil.isAddressTriggerInvoked){
        Set<String> customerIds = new Set<String>();
        Map<String,String> customerShippingIds = new Map<String,String>();
        Map<String,String> customerBillingIds = new Map<String,String>();
        if(trigger.isInsert){
            for(Address__c a : trigger.new){
                if(a.Customer__c != null){
                    customerIds.add(a.Customer__c);
                    if(a.Default_Shipping__c == true) customerShippingIds.put(a.Customer__c,a.Id);
                    if(a.Default_Billing__c == true) customerBillingIds.put(a.Customer__c,a.Id);
                }               
            }
        }else{
            for(Address__c a : trigger.new){
                if(a.Customer__c != null){
                    customerIds.add(a.Customer__c);
                    if(a.Default_Shipping__c == true && a.Default_Shipping__c != trigger.oldMap.get(a.Id).Default_Shipping__c) customerShippingIds.put(a.Customer__c,a.Id);
                    if(a.Default_Billing__c == true && a.Default_Billing__c != trigger.oldMap.get(a.Id).Default_Billing__c) customerBillingIds.put(a.Customer__c,a.Id);
                }
            }
        }
        if(!customerIds.isEmpty()){            
            List<Address__c> addressList = new List<Address__c>();
            if(!customerShippingIds.isEmpty() || !customerBillingIds.isEmpty()){
                for(Address__c aRecord : [SELECT Id, Customer__c FROM Address__c WHERE Customer__c IN: customerShippingIds.keySet() OR Customer__c IN: customerBillingIds.keySet()]){
                    if(customerShippingIds.get(aRecord.Customer__c) != null && customerShippingIds.get(aRecord.Customer__c) != aRecord.Id) aRecord.Default_Shipping__c = false;
                    if(customerBillingIds.get(aRecord.Customer__c) != null && customerBillingIds.get(aRecord.Customer__c) != aRecord.Id) aRecord.Default_Billing__c = false;
                    addressList.add(aRecord);
                }
            }
            
            ApexUtil.isAddressTriggerInvoked = false;
            if(!addressList.isEmpty()) update addressList;
            update [SELECT Id FROM Account WHERE Id IN: customerIds];
        }
    }
}