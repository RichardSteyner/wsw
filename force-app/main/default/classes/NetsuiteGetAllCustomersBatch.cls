global class NetsuiteGetAllCustomersBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {
    
	public Integer size;
	public Integer offset;
	public Boolean hasMore; 
    
    global NetsuiteGetAllCustomersBatch(Integer size, Integer offset){
        this.size = size;
        this.offset = offset;
        hasMore = true;
    }
    
    global List<String> start(Database.BatchableContext BC){
        List<String> nsIds = new List<String>(); 
        try{
        	Date auxFecha = Date.valueOf('2020-08-19');
           	String filtroFecha = 'lastModifiedDate%20AFTER%20"' + auxFecha.month() + '/' + auxFecha.day() + '/' + auxFecha.year() + '"';
            NetsuiteListParser listCustomers = (NetsuiteListParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('customer', 'limit=' + size + '&offset=' + offset + '&q=' + filtroFecha), NetsuiteListParser.class);
            hasMore = listCustomers.hasMore;
            for(NetsuiteListParser.Item auxItem : listCustomers.items){
            	nsIds.add(auxItem.id);
            }
            offset = offset + size;
        }catch(Exception e){
            hasMore = false;
            System.debug('NetsuiteGetAllCustomersBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteCustomerParser customer;
        Lead objLead;
        Account objAccount;
        Account objSubsidiary;
        Map<String, Lead> leads = new Map<String, Lead>();
        Map<String, Account> accounts = new Map<String, Account>();
        Map<String, Account> parents = new Map<String, Account>();
        Map<String, Id> userIds = new Map<String, Id>();
        Map<String, Task> tasks = new Map<String, Task>();
    	for(String auxId : scope){
            System.debug(auxId);
        	try{
                customer = (NetsuiteCustomerParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('customer/' + auxId, ''), NetsuiteCustomerParser.class);
                /*System.debug('-----------CUSTOMER------------');
                System.debug(customer);
                System.debug('-----------CUSTOMER------------');*/
                objLead = new Lead(NS_ID__c=auxId, LastName=customer.companyName, Company=customer.companyName, Industry=customer.getIndustry(), 
                                   NumberOfEmployees=customer.custentity_esc_no_of_employees, Taxable__c=customer.taxable, Web_Approved_CB__c=customer.custentity_sc_web_approved,
                                   Type_of_Customer__c=customer.getTypeOfCustomer(), Attention_Address__c=customer.defaultAddress, LeadSource=customer.getLeadSource(), 
                                   WS_Prime__c=customer.getWSPrime(), Phone=customer.phone, CC_Processor__c=customer.getCCProcessor(), Price_Level__c=customer.getPriceLevel(), 
                                   Website=customer.url, Netsuite_Status__c=customer.geEntityStatus(), Parent_NS_ID__c=customer.getParentId(), 
                                   OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd, 
                                   OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip,
                                   Ozlink_Website__c=customer.custentity_ozlink_website,
                                   Owner_NS_ID__c=customer.getSalesRepId());
                leads.put(auxId, objLead);
                
                objAccount = new Account(NS_ID__c=auxId, Name=customer.companyName, Industry=customer.getIndustry(), 
                                   NumberOfEmployees=customer.custentity_esc_no_of_employees, Taxable__c=customer.taxable, Web_Approved_CB__c=customer.custentity_sc_web_approved,
                                   Type_of_Customer__c=customer.getTypeOfCustomer(), Attention_Address__c=customer.defaultAddress, AccountSource=customer.getLeadSource(), 
                                   WS_Prime__c=customer.getWSPrime(), Phone=customer.phone, CC_Processor__c=customer.getCCProcessor(), Price_Level__c=customer.getPriceLevel(), 
                                   Website=customer.url, Netsuite_Status__c=customer.geEntityStatus(), Parent_NS_ID__c=customer.getParentId(), 
                                   OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd, 
                                   OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip,
                                   Ozlink_Website__c=customer.custentity_ozlink_website,
                                   Owner_NS_ID__c=customer.getSalesRepId());
                accounts.put(auxId, objAccount);
                
                if(customer.getParentId()!=null){
                    objSubsidiary = new Account(NS_ID__c=customer.getParentId(), Name=customer.getParentName());
                    parents.put(customer.getParentId(), objSubsidiary);
                }
                if(customer.getSalesRepId()!=null){
                    userIds.put(customer.getSalesRepId(), null);
                }
                if(customer.custentity_exhibit_catalog || customer.custentity_firstorder_email || customer.custentity_resort_catalog){
                    tasks.put(auxId, new Task(Subject='Sent Welcome Packet', ActivityDate=Date.today(), Status='Completed', 
                                              Priority='Medium', Customer_NS_Id__c=auxId));
                }
           	}catch(Exception e){
            	System.debug('NetsuiteGetAllCustomersBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.UpsertResult> upsertResults;
        upsertResults = Database.upsert(parents.values(), Account.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetAllCustomersBatch - Parent Upsert Error: ' + upsertError.getMessage());
            }
        }
        
        for(User u : [select Id, NS_ID__c from User where NS_ID__c in: userIds.keySet()]) userIds.put(u.NS_ID__c, u.Id);
        
        for(Account ac : [select Id, NS_ID__c from Account where NS_ID__c in: accounts.keySet()]){
            leads.remove(ac.NS_ID__c);
            accounts.get(ac.NS_ID__c).Id=ac.Id;
        }
                
		for(Lead l : leads.values()){
			if(l.Parent_NS_ID__c!=null)
            {
            	if(parents.get(l.Parent_NS_ID__c)!=null && parents.get(l.Parent_NS_ID__c).Id!=null) 
                	l.Parent__c=parents.get(l.Parent_NS_ID__c).Id;
          	}
            if(l.Owner_NS_ID__c!=null){
                if(userIds.get(l.Owner_NS_ID__c)!=null) l.OwnerId=userIds.get(l.Owner_NS_ID__c);
                else System.debug('Lead->Cannot relate to Owner: ' + l.Owner_NS_ID__c);
            }
        }
        
		ApexUtil.isLeadTriggerInvoked = false;        
       	upsertResults = Database.upsert(leads.values(), Lead.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetAllCustomersBatch - Lead Upsert Error: ' + upsertError.getMessage());
            }
     	}
        
        for(Account a : accounts.values()){
            if(a.Id==null) accounts.remove(a.NS_ID__c);
        }
        
        for(Account a : accounts.values()){
			if(a.Parent_NS_ID__c!=null)
            {
            	if(parents.get(a.Parent_NS_ID__c)!=null && parents.get(a.Parent_NS_ID__c).Id!=null) 
                	a.ParentId=parents.get(a.Parent_NS_ID__c).Id;
          	}
            if(a.Owner_NS_ID__c!=null){
                if(userIds.get(a.Owner_NS_ID__c)!=null) 
                	a.OwnerId=userIds.get(a.Owner_NS_ID__c);
                else
                    System.debug('Account->Cannot relate to Owner: ' + a.Owner_NS_ID__c);
            }
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.SaveResult> updateResults;
        updateResults = Database.update(accounts.values(), false);
        for(Database.SaveResult saveResult:updateResults) {
            if(!saveResult.isSuccess()) {
                for(Database.Error updateError : saveResult.getErrors()) System.debug('NetsuiteGetAllCustomersBatch - Account Update Error: ' + updateError.getMessage());
            }
        }
        
        for(Task t : tasks.values()){
            if(leads.keySet().contains(t.Customer_NS_Id__c)){
                t.WhoId = leads.get(t.Customer_NS_Id__c).Id;
            }else if(accounts.keySet().contains(t.Customer_NS_Id__c)){
                t.WhatId = accounts.get(t.Customer_NS_Id__c).Id;
            } else
                System.debug('Algo anda mal.!');
        }
        
        upsertResults = Database.upsert(tasks.values(), Task.Customer_NS_Id__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetAllCustomersBatch - Task Upsert Error: ' + upsertError.getMessage());
            }
     	}
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetAllCustomersBatch');
        if(!Test.isRunningTest()){
            if(hasMore) Database.executeBatch(new NetsuiteGetAllCustomersBatch(size, offset), 30);
            else Database.executeBatch(new NetsuiteGetAllContactsBatch(size, 0), 30);
        }
    }
    
}