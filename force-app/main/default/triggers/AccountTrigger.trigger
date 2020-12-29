trigger AccountTrigger on Account (after insert, after update) {
    
    if(ApexUtil.isAccountTriggerInvoked){
        Set<String> createAccountIds = new Set<String>();
        Map<String,Account> accountAddressIds = new Map<String,Account>();
        if(trigger.isInsert){
            for(Account account : trigger.new){
                createAccountIds.add(account.Id);
                if(account.ShippingStreet != null || account.ShippingCity != null || account.ShippingState != null || account.ShippingPostalCode != null || account.ShippingCountry != null) accountAddressIds.put(account.Id,account);
                if(account.BillingStreet != null || account.BillingCity != null || account.BillingState != null || account.BillingPostalCode != null || account.BillingCountry != null) accountAddressIds.put(account.Id,account);
            }
        }else{
            for(Account account : trigger.new){
                createAccountIds.add(account.Id);
                if(account.ShippingStreet != trigger.oldMap.get(account.Id).ShippingStreet || 
                   account.ShippingCity != trigger.oldMap.get(account.Id).ShippingCity || 
                   account.ShippingState != trigger.oldMap.get(account.Id).ShippingState || 
                   account.ShippingPostalCode != trigger.oldMap.get(account.Id).ShippingPostalCode || 
                   account.ShippingCountry != trigger.oldMap.get(account.Id).ShippingCountry) 
                    accountAddressIds.put(account.Id,account);
                
                if(account.BillingStreet != trigger.oldMap.get(account.Id).BillingStreet || 
                   account.BillingCity != trigger.oldMap.get(account.Id).BillingCity || 
                   account.BillingState != trigger.oldMap.get(account.Id).BillingState || 
                   account.BillingPostalCode != trigger.oldMap.get(account.Id).BillingPostalCode || 
                   account.BillingCountry != trigger.oldMap.get(account.Id).BillingCountry) 
                    accountAddressIds.put(account.Id,account);
            }
        }
        
        if(!accountAddressIds.isEmpty()){
            List<Address__c> addressAuxList;
            Map<String,List<Address__c>> addressAuxMap = new Map<String,List<Address__c>>();
            for(Address__c addr : [SELECT Id, Address_1__c, City__c, Country__c, State__c, Zip__c, Customer__c FROM Address__c WHERE Customer__c IN: accountAddressIds.keySet()]){
                addressAuxList = addressAuxMap.get(addr.Customer__c) != null ? addressAuxMap.get(addr.Customer__c) : new List<Address__c>();
                addressAuxList.add(addr);
                addressAuxMap.put(addr.Customer__c,addressAuxList.clone());
            }
            
            List<Address__c> addressList = new List<Address__c>();
            Boolean isNoneShipping;
            Boolean isNoneBilling;
            for(Account account : accountAddressIds.values()){
                isNoneShipping = false;
                isNoneBilling = false;
                if(addressAuxMap.get(account.Id) != null){
                    for(Address__c addr : addressAuxMap.get(account.Id)){
                        if(addr.Address_1__c == account.ShippingStreet && addr.City__c == account.ShippingCity && addr.State__c == account.ShippingState && 
                           ((addr.Country__c == account.ShippingCountry) || (addr.Country__c == 'US' && account.ShippingCountry == 'United States' || (addr.Country__c == 'United States' && account.ShippingCountry == 'US'))) && 
                           addr.Zip__c == account.ShippingPostalCode){
                               addr.Default_Shipping__c = true;
                               isNoneShipping = true;
                           }else{
                               addr.Default_Shipping__c = false;
                           }
                        
                        if(addr.Address_1__c == account.BillingStreet && addr.City__c == account.BillingCity && addr.State__c == account.BillingState && 
                           ((addr.Country__c == account.BillingCountry) || (addr.Country__c == 'US' && account.BillingCountry == 'United States' || (addr.Country__c == 'United States' && account.BillingCountry == 'US'))) && 
                           addr.Zip__c == account.BillingPostalCode){
                               addr.Default_Billing__c = true;
                               isNoneBilling = true;
                           }else{
                               addr.Default_Billing__c = false;
                           }
                        addressList.add(addr);
                    }
                }
                if(!isNoneShipping){
                    addressList.add(new Address__c(Customer__c = account.Id, Default_Shipping__c = true, Address_1__c = account.ShippingStreet, City__c = account.ShippingCity, State__c = account.ShippingState, Zip__c = account.ShippingPostalCode, Country__c = account.ShippingCountry));
                }
                if(!isNoneBilling){
                    addressList.add(new Address__c(Customer__c = account.Id, Default_Billing__c = true, Address_1__c = account.BillingStreet, City__c = account.BillingCity, State__c = account.BillingState, Zip__c = account.BillingPostalCode, Country__c = account.BillingCountry));
                }
            }
            
            ApexUtil.isAddressTriggerInvoked = false;
            if(!addressList.isEmpty()) upsert addressList;
        }
        
        if(!createAccountIds.isEmpty()) NetsuiteMethods.upsertCustomer(createAccountIds);
    }
}