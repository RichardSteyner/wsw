global class NetsuiteGetCustomersBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

    public String startDate;
    public Set<String> auxAccountIds;
    public Map<String,String> customSettingMap = new Map<String,String>();
    
    global NetsuiteGetCustomersBatch(String startDate, Set<String> auxAccountIds){
        this.startDate = startDate;
        this.auxAccountIds = auxAccountIds;
        
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl.Value__c);
    }
    
    global List<String> start(Database.BatchableContext BC){
        Set<String> auxScope = new Set<String>();
        for(String auxId: auxAccountIds){
            auxScope.add(auxId);
        }
        List<String> nsIds = new List<String>(); 
        try{
            NetsuiteGetIds getCustomers = new NetsuiteGetIds('customer');
			List<String> auxList = getCustomers.getUpdatedIds(startDate);
            for(String auxId : auxList){
            	auxScope.add(auxId);
            }
        }catch(Exception e){
            System.debug('NetsuiteGetCustomersBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        for(String i : auxScope){
        	nsIds.add(i);
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteCustomerParser customer;
        NetsuiteContactParser nsContact;
        NetsuiteAddressbookParser nsAddressbook;
        NetsuiteAddressbookParser.AddressBookDetail nsAddressbookDetail;
        NetsuiteAddressbookParser.AddressBookAddress nsAddressbooAddress;
        String jsonResponse;
        Lead objLead;
        Account objAccount;
        Account objSubsidiary;
        Map<String, Lead> leads = new Map<String, Lead>();
        Map<String, Account> accounts = new Map<String, Account>();
        Map<String, Account> parents = new Map<String, Account>();
        Map<String, Id> userIds = new Map<String, Id>();
        Map<String, Task> tasks = new Map<String, Task>();
        String contactLink;
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern MyPattern;
        Matcher MyMatcher;
        NetsuiteLead__c customLead;
		Map<String,NetsuiteLead__c> customLeadMap = new Map<String,NetsuiteLead__c>();
        for(String auxId : scope){
            jsonResponse = NetsuiteConnection.getNetsuiteObject('customer/' + auxId, '');
            if(jsonResponse!=null){
                customer = (NetsuiteCustomerParser) json.deserialize(jsonResponse, NetsuiteCustomerParser.class);
                System.debug('-----------CUSTOMER------------');
                //System.debug(customer);
                
                objAccount = new Account(NS_ID__c=auxId, Name=customer.companyName,
                                         NumberOfEmployees=customer.custentity_esc_no_of_employees, Taxable__c=customer.taxable, Web_Approved_CB__c=customer.custentity_sc_web_approved,
                                         Attention_Address__c=customer.defaultAddress,  WS_Prime__c=customer.getWSPrime(), Phone=customer.phone, Website=customer.url,
                                         Parent_NS_ID__c=customer.getParentId(), OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd, 
                                         OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip, Ozlink_Website__c=customer.custentity_ozlink_website,
                                         Owner_NS_ID__c=customer.getSalesRepId());
                objAccount.AccountSource = (customer.getLeadSource() != null ? customer.getLeadSource().subStringAfter('> ') : null);
                objAccount.CC_Processor__c = (customer.getCCProcessor() != null ? customer.getCCProcessor().subStringAfter('> ') : null);
                objAccount.Price_Level__c = (customer.getPriceLevel() != null ? customer.getPriceLevel().subStringAfter('> ') : null);
                objAccount.Netsuite_Status__c = (customer.geEntityStatus() != null ? customer.geEntityStatus().subStringAfter('> ') : null);
                objAccount.Industry = (customer.getIndustry() != null ? customer.getIndustry().subStringAfter('> ') : null);
                objAccount.Type_of_Customer__c = (customer.getTypeOfCustomer() != null ? customer.getTypeOfCustomer().subStringAfter('> ') : null);
                if(customer.getLeadSource() != null){
                    customLeadMap.put(
                        'leadsource-'+customer.getLeadSource().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'leadsource', Name = 'LeadSource-'+customer.getLeadSource().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getLeadSource().subStringBetween('<','>'),Value__c = customer.getLeadSource().subStringAfter('> ').trim())
                    );
                }
                if(customer.getCCProcessor() != null){
                    customLeadMap.put(
                        'ccprocessor-'+customer.getCCProcessor().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'CCProcessor', Name = 'ccprocessor-'+customer.getCCProcessor().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getCCProcessor().subStringBetween('<','>'),Value__c = customer.getCCProcessor().subStringAfter('> ').trim())
                    );
                }
                if(customer.getPriceLevel() != null){
                    customLeadMap.put(
                        'pricelevel-'+customer.getPriceLevel().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'PriceLevel', Name = 'pricelevel-'+customer.getPriceLevel().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getPriceLevel().subStringBetween('<','>'),Value__c = customer.getPriceLevel().subStringAfter('> ').trim())
                    );
                }
                if(customer.geEntityStatus() != null){
                    customLeadMap.put(
                        'entitystatus-'+customer.geEntityStatus().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'EntityStatus', Name = 'entitystatus-'+customer.geEntityStatus().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.geEntityStatus().subStringBetween('<','>'),Value__c = customer.geEntityStatus().subStringAfter('> ').trim())
                    );
                }
                if(customer.getIndustry() != null){
                    customLeadMap.put(
                        'industry-'+customer.getIndustry().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'Industry', Name = 'industry-'+customer.getIndustry().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getIndustry().subStringBetween('<','>'),Value__c = customer.getIndustry().subStringAfter('> ').trim())
                    );
                }
                if(customer.getTypeOfCustomer() != null){
                    customLeadMap.put(
                        'typeofcustomer-'+customer.getTypeOfCustomer().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'TypeOfCustomer', Name = 'typeofcustomer-'+customer.getTypeOfCustomer().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getTypeOfCustomer().subStringBetween('<','>'),Value__c = customer.getTypeOfCustomer().subStringAfter('> ').trim())
                    );
                }
                accounts.put(auxId, objAccount);
                
                contactLink = null;
                if(customer.contact != null && customer.contact.links != null){
                    for(NetsuiteCustomerParser.Link clink : customer.contact.links){
                        if(clink.href != null) contactLink = clink.href; break;
                    }
                    if(contactLink != null){
                        jsonResponse = NetsuiteConnection.getNetsuiteObject(contactLink.substringAfter('/v1/') , '');
                        if(jsonResponse!=null){
                            objLead = new Lead(NS_ID__c=auxId, Company=customer.companyName,NumberOfEmployees=customer.custentity_esc_no_of_employees, Taxable__c=customer.taxable,
                                               Web_Approved_CB__c=customer.custentity_sc_web_approved,Attention_Address__c=customer.defaultAddress, WS_Prime__c=customer.getWSPrime(),
                                               Website=customer.url, Parent_NS_ID__c=customer.getParentId(), OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd, 
                                               OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip,Ozlink_Website__c=customer.custentity_ozlink_website,
                                               Owner_NS_ID__c=customer.getSalesRepId());
                            
                            objLead.LeadSource = (customer.getLeadSource() != null ? customer.getLeadSource().subStringAfter('> ') : null);
                            objLead.CC_Processor__c = (customer.getCCProcessor() != null ? customer.getCCProcessor().subStringAfter('> ') : null);
                            objLead.Price_Level__c = (customer.getPriceLevel() != null ? customer.getPriceLevel().subStringAfter('> ') : null);
                            objLead.Netsuite_Status__c = (customer.geEntityStatus() != null ? customer.geEntityStatus().subStringAfter('> ') : null);
                            objLead.Industry = (customer.getIndustry() != null ? customer.getIndustry().subStringAfter('> ') : null);
                            objLead.Type_of_Customer__c = (customer.getTypeOfCustomer() != null ? customer.getTypeOfCustomer().subStringAfter('> ') : null);
                            
                            nsContact = (NetsuiteContactParser) json.deserialize(jsonResponse, NetsuiteContactParser.class);
                            if(nsContact != null){
                                objLead.NS_Contact_ID__c = nsContact.id;
                                objLead.LastName = (nsContact.entityId != null ? (nsContact.entityId.indexOf(' ') > 0 ? nsContact.entityId.subStringAfter(' ') : nsContact.entityId)  : nsContact.lastName);
                                objLead.FirstName = (nsContact.entityId != null ? (nsContact.entityId.indexOf(' ') > 0 ? nsContact.entityId.subStringBefore(' ') : null)  : nsContact.firstName);
                                objLead.Phone = nsContact.phone;
                                objLead.Inactive__c = nsContact.isinactive;
                                if(nsContact.email != null){
                                    MyPattern = Pattern.compile(emailRegex);
                                    MyMatcher = MyPattern.matcher(nsContact.email);
                                    if(MyMatcher.matches()) objLead.Email = nsContact.email;
                                }
                                if(nsContact.addressbook != null && nsContact.addressbook.links != null){
                                    for(NetsuiteContactParser.Link alink : nsContact.addressbook.links){
                                        if(alink.href != null){
                                            jsonResponse = NetsuiteConnection.getNetsuiteObject(alink.href.substringAfter('/v1/') , '');
                                            if(jsonResponse!=null){
                                                nsAddressbook = (NetsuiteAddressbookParser) json.deserialize(jsonResponse, NetsuiteAddressbookParser.class);
                                                if(nsAddressbook != null && nsAddressbook.items != null){
                                                    for(NetsuiteAddressbookParser.Item item : nsAddressbook.items){
                                                        for(NetsuiteAddressbookParser.Link ablink : item.links){
                                                            if(ablink.href != null){
                                                                system.debug(ablink.href.substringAfter('/v1/'));
                                                                jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') , '');
                                                                if(jsonResponse!=null){
                                                                    system.debug('enter');
                                                                    nsAddressbookDetail = (NetsuiteAddressbookParser.AddressBookDetail) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookDetail.class);
                                                                    if(nsAddressbookDetail != null && nsAddressbookDetail.defaultBilling != null && nsAddressbookDetail.defaultBilling == true){
                                                                        system.debug('enter2');
                                                                        jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') + '/addressbookaddress' , '');
                                                                        if(jsonResponse!=null){
                                                                            system.debug('enter3');
                                                                            nsAddressbooAddress = (NetsuiteAddressbookParser.AddressBookAddress) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookAddress.class);
                                                                            objLead.Street = (nsAddressbooAddress.addr1 != null ? nsAddressbooAddress.addr1 : null);
                                                                            objLead.Addressee__c = (nsAddressbooAddress.addressee != null ? nsAddressbooAddress.addressee : null);
                                                                            objLead.City = nsAddressbooAddress.city;
                                                                            objLead.State = nsAddressbooAddress.state;
                                                                            objLead.Country = nsAddressbooAddress.country;
                                                                            objLead.Country_Code__c = nsAddressbooAddress.country;
                                                                            objLead.PostalCode = nsAddressbooAddress.zip;
                                                                            objLead.Address_Phone__c = nsAddressbooAddress.addrPhone;
                                                                        }
                                                                        break;
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        break;
                                                    }
                                                }
                                            }
                                            break;
                                        }
                                    }
                                }
                            }
                            if(objLead.LastName != null) leads.put(auxId, objLead);
                        }
                    }
                }
                
                if(customer.getParentId()!=null){
                    objSubsidiary = new Account(NS_ID__c=customer.getParentId(), Name=customer.getParentName());
                    parents.put(customer.getParentId(), objSubsidiary);
                }
                if(customer.getSalesRepId()!=null) userIds.put(customer.getSalesRepId(), null);

                if(customer.custentity_exhibit_catalog || customer.custentity_firstorder_email || customer.custentity_resort_catalog){
                    tasks.put(auxId, new Task(Subject='Sent Welcome Packet', ActivityDate=Date.today(), Status='Completed', Priority='Medium', Customer_NS_Id__c=auxId));
                }
            }
        }

        //Custom Settings
        for(String key : customLeadMap.keySet()){
            if(customSettingMap.get(key) != null) customLeadMap.remove(key); else customSettingMap.put(key,customLeadMap.get(key).Value__c);
        }
        if(!customLeadMap.isEmpty()) insert customLeadMap.values();
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.UpsertResult> upsertResults;
        upsertResults = Database.upsert(parents.values(), Account.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Parent Upsert Error: ' + upsertError.getMessage());
            }
        }
        
        for(User u : [select Id, NS_ID__c from User where NS_ID__c in: userIds.keySet()]) userIds.put(u.NS_ID__c, u.Id);
        
        Map<String,Contact> contactMap = new Map<String,Contact>();
        for(Account ac : [select Id, NS_ID__c from Account where NS_ID__c in: accounts.keySet()]){
            if(leads.get(ac.NS_ID__c) != null){
                contactMap.put(
                    ac.NS_ID__c,
                    new Contact(
                        NS_ID__c = leads.get(ac.NS_ID__c).NS_Contact_ID__c,
                        FirstName = leads.get(ac.NS_ID__c).FirstName,
                        LastName = leads.get(ac.NS_ID__c).LastName,
                        Phone = leads.get(ac.NS_ID__c).Phone,
                        Email = leads.get(ac.NS_ID__c).Email,
                        Inactive__c = leads.get(ac.NS_ID__c).Inactive__c,
                        MailingStreet = leads.get(ac.NS_ID__c).Street,
                        Addressee__c = leads.get(ac.NS_ID__c).Addressee__c,
                        MailingCity = leads.get(ac.NS_ID__c).City,
                        MailingState = leads.get(ac.NS_ID__c).State,
                        MailingCountry = leads.get(ac.NS_ID__c).Country,
                        Country_Code__c = leads.get(ac.NS_ID__c).Country_Code__c,
                        MailingPostalCode = leads.get(ac.NS_ID__c).PostalCode,
                        Address_Phone__c = leads.get(ac.NS_ID__c).Address_Phone__c
                    )
                );
            }
            leads.remove(ac.NS_ID__c);
            accounts.get(ac.NS_ID__c).Id = ac.Id;
        }
                
        //leads
		for(Lead l : leads.values()){
			if(l.Parent_NS_ID__c != null && parents.get(l.Parent_NS_ID__c) != null && parents.get(l.Parent_NS_ID__c).Id != null) l.Parent__c=parents.get(l.Parent_NS_ID__c).Id;
            if(l.Owner_NS_ID__c != null && userIds.get(l.Owner_NS_ID__c) != null) l.OwnerId=userIds.get(l.Owner_NS_ID__c);
        }
        
		ApexUtil.isLeadTriggerInvoked = false;        
       	upsertResults = Database.upsert(leads.values(), Lead.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Lead Upsert Error: ' + upsertError.getMessage());
            }
     	}
        
        //accounts
        for(Account a : accounts.values()){
            if(a.Id == null) accounts.remove(a.NS_ID__c);
        }
        for(Account a : accounts.values()){
			if(a.Parent_NS_ID__c != null && parents.get(a.Parent_NS_ID__c) != null && parents.get(a.Parent_NS_ID__c).Id != null) a.ParentId = parents.get(a.Parent_NS_ID__c).Id;
            if(a.Owner_NS_ID__c != null && userIds.get(a.Owner_NS_ID__c) != null) a.OwnerId = userIds.get(a.Owner_NS_ID__c);
        }
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.SaveResult> updateResults;
        updateResults = Database.update(accounts.values(), false);
        for(Database.SaveResult saveResult:updateResults) {
            if(!saveResult.isSuccess()) {
                for(Database.Error updateError : saveResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Account Update Error: ' + updateError.getMessage());
            }
        }
        
        //contacts
        Map<String,Contact> contacts = new Map<String,Contact>();
        for(Account a : accounts.values()){
            if(a.Id != null && a.NS_ID__c != null && contactMap.get(a.NS_ID__c) != null && contactMap.get(a.NS_ID__c).NS_ID__c != null){
                contactMap.get(a.NS_ID__c).AccountId = a.Id;
                contacts.put(contactMap.get(a.NS_ID__c).NS_ID__c,contactMap.get(a.NS_ID__c));
            }
        }
        upsertResults = Database.upsert(contacts.values(), Contact.NS_ID__c, false);
        for(Database.UpsertResult saveResult:upsertResults) {
            if(!saveResult.isSuccess()) {
                for(Database.Error updateError : saveResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Contact Upsert Error: ' + updateError.getMessage());
            }
        }
        
        for(Task t : tasks.values()){
            if(leads.keySet().contains(t.Customer_NS_Id__c)){
                t.WhoId = leads.get(t.Customer_NS_Id__c).Id;
            }else if(accounts.keySet().contains(t.Customer_NS_Id__c)){
                t.WhatId = accounts.get(t.Customer_NS_Id__c).Id;
            }
        }
        
        upsertResults = Database.upsert(tasks.values(), Task.Customer_NS_Id__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Task Upsert Error: ' + upsertError.getMessage());
            }
     	}
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetCustomersBatch');
        if(!Test.isRunningTest()) Database.executeBatch(new NetsuiteGetContactsBatch(startDate), 10);
    }
    
}