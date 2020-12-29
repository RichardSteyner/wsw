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
        List<String> nsIds = new List<String>(); 
        for(String auxId: auxAccountIds) nsIds.add(auxId);
        try{
            NetsuiteGetIds getCustomers = new NetsuiteGetIds('customer');
			List<String> auxList = getCustomers.getUpdatedIds(startDate);
            nsIds.addAll(auxList);
        }catch(Exception e){
            System.debug('NetsuiteGetCustomersBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
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
        Address__c addressRecord;
        List<Address__c> addressList = new List<Address__c>();
		Map<String,NetsuiteLead__c> customLeadMap = new Map<String,NetsuiteLead__c>();
        for(String auxId : scope){
            jsonResponse = NetsuiteConnection.getNetsuiteObject('customer/' + auxId, '');
            system.debug('auxId: ' + auxId);
            if(jsonResponse!=null){
                customer = (NetsuiteCustomerParser) json.deserialize(jsonResponse, NetsuiteCustomerParser.class);
                if(customer != null){
                    objAccount = new Account(NS_ID__c = auxId);
                    objAccount.Name=customer.companyName;
                    objAccount.NumberOfEmployees=customer.custentity_esc_no_of_employees;
                    objAccount.Taxable__c=customer.taxable;
                    objAccount.Web_Approved_CB__c=customer.custentity_sc_web_approved;
                    objAccount.WS_Prime__c=customer.getWSPrime();
                    objAccount.Phone=customer.phone;
                    objAccount.Website=customer.url;
                    objAccount.Parent_NS_ID__c=customer.getParentId();
                    objAccount.OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd;
                    objAccount.OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip;
                    objAccount.Ozlink_Website__c=customer.custentity_ozlink_website;
                    objAccount.Owner_NS_ID__c=customer.getSalesRepId();
                    objAccount.AccountSource = (customer.getLeadSource() != null ? customer.getLeadSource().subStringAfter('> ') : null);
                    objAccount.CC_Processor__c = (customer.getCCProcessor() != null ? customer.getCCProcessor().subStringAfter('> ') : null);
                    objAccount.Price_Level__c = (customer.getPriceLevel() != null ? customer.getPriceLevel().subStringAfter('> ') : null);
                    objAccount.Netsuite_Status__c = (customer.geEntityStatus() != null ? customer.geEntityStatus().subStringAfter('> ') : null);
                    objAccount.Industry = (customer.getIndustry() != null ? customer.getIndustry().subStringAfter('> ') : null);
                    objAccount.Type_of_Customer__c = (customer.getTypeOfCustomer() != null ? customer.getTypeOfCustomer().subStringAfter('> ') : null);
                    objAccount.Sales_Order_Notes__c = customer.custentitysalesordernotes;
                    objAccount.Phone = customer.phone;
                    objAccount.Office_Phone__c = customer.altPhone;
                    objAccount.Fax = customer.fax;
                    objAccount.Email__c = customer.email;
                    objAccount.Alt_Contact__c = customer.custentity_invoice_email;
                    objAccount.Alt_Email__c = customer.custentity_order_conf_email;
                    objAccount.Annual_Revenue__c = customer.custentity_esc_annual_revenue;
                    objAccount.ASI__c = customer.custentity9;
                    objAccount.ASI_Number__c = customer.custentity25;
                    objAccount.Credit_Limit__c = customer.creditLimit;
                    objAccount.Tax_Number__c = customer.vatRegNumber;
                    objAccount.Resale_Number__c = customer.resaleNumber;
                    objAccount.Resale_Cert_File_Path__c = customer.custentity_resale_cert_newuser;
                    objAccount.Sale_Rep__c = null;
                    if(customer.salesRep != null && customer.salesRep.refName != null){
                        objAccount.Sale_Rep__c = customer.salesRep.refName;
                        customLeadMap.put(
                            'salesrep-'+customer.salesRep.id,
                            new NetsuiteLead__c(Type__c = 'SalesRep', Name = 'salesrep-'+customer.salesRep.id, ID__c = customer.salesRep.id,Value__c = customer.salesRep.refName)
                        );
                    }
                    objAccount.How_Did_You_Hear__c = null;
                    if(customer.custentitylead_survey != null && customer.custentitylead_survey.refName != null){
                        objAccount.How_Did_You_Hear__c = customer.custentitylead_survey.refName;
                        customLeadMap.put(
                            'howdidyourhear-'+customer.custentitylead_survey.id,
                            new NetsuiteLead__c(Type__c = 'HowDidYourHear', Name = 'howdidyourhear-'+customer.custentitylead_survey.id, ID__c = customer.custentitylead_survey.id,Value__c = customer.custentitylead_survey.refName)
                        );
                    }
                    objAccount.How_Did_You_Hear_Trade_Shows__c = null;
                    if(customer.custentitylead_survey_tradeshow_value != null && customer.custentitylead_survey_tradeshow_value.refName != null){
                        objAccount.How_Did_You_Hear_Trade_Shows__c = customer.custentitylead_survey_tradeshow_value.refName;
                        customLeadMap.put(
                            'howdidyourheartrade-'+customer.custentitylead_survey_tradeshow_value.id,
                            new NetsuiteLead__c(Type__c = 'HowDidYourHearTradeShow', Name = 'howdidyourheartrade-'+customer.custentitylead_survey_tradeshow_value.id, ID__c = customer.custentitylead_survey_tradeshow_value.id,Value__c = customer.custentitylead_survey_tradeshow_value.refName)
                        );
                    }
                    objAccount.Certificate_Approved_By__c = null;
                    if(customer.custentitycustentity_certificate_app_by != null && customer.custentitycustentity_certificate_app_by.refName != null){
                        objAccount.Certificate_Approved_By__c = customer.custentitycustentity_certificate_app_by.refName;
                        customLeadMap.put(
                            'employee-'+customer.custentitycustentity_certificate_app_by.id,
                            new NetsuiteLead__c(Type__c = 'Employee', Name = 'employee-'+customer.custentitycustentity_certificate_app_by.id, ID__c = customer.custentitycustentity_certificate_app_by.id,Value__c = customer.custentitycustentity_certificate_app_by.refName)
                        );
                    }
                    objAccount.Dedicated_Resort_Extrusion_Rep__c = null;
                    if(customer.custentity45 != null && customer.custentity45.refName != null){
                        objAccount.Dedicated_Resort_Extrusion_Rep__c = customer.custentity45.refName;
                        customLeadMap.put(
                            'employee-'+customer.custentity45.id,
                            new NetsuiteLead__c(Type__c = 'Employee', Name = 'employee-'+customer.custentity45.id, ID__c = customer.custentity45.id,Value__c = customer.custentity45.refName)
                        );
                    }
                    objAccount.Tax_Item__c = null;
                    if(customer.taxItem != null && customer.taxItem.refName != null){
                        objAccount.Tax_Item__c = customer.taxItem.refName;
                        customLeadMap.put(
                            'taxitem-'+customer.taxItem.id,
                            new NetsuiteLead__c(Type__c = 'TaxItem', Name = 'taxitem-'+customer.taxItem.id, ID__c = customer.taxItem.id,Value__c = customer.taxItem.refName)
                        );
                    }
                    objAccount.Terms__c = null;
                    if(customer.terms != null && customer.terms.refName != null){
                        objAccount.Terms__c = customer.terms.refName;
                        customLeadMap.put(
                            'terms-'+customer.terms.id,
                            new NetsuiteLead__c(Type__c = 'Terms', Name = 'terms-'+customer.terms.id, ID__c = customer.terms.id,Value__c = customer.terms.refName)
                        );
                    }
                    objAccount.Account_Approval_Process__c = null;
                    if(customer.custentity_ws_accnt_aprvl_prcs != null && customer.custentity_ws_accnt_aprvl_prcs.refName != null){
                        objAccount.Account_Approval_Process__c = customer.custentity_ws_accnt_aprvl_prcs.refName;
                        customLeadMap.put(
                            'approvalprocess-'+customer.custentity_ws_accnt_aprvl_prcs.id,
                            new NetsuiteLead__c(Type__c = 'ApprovalProcess', Name = 'approvalprocess-'+customer.custentity_ws_accnt_aprvl_prcs.id, ID__c = customer.custentity_ws_accnt_aprvl_prcs.id,Value__c = customer.custentity_ws_accnt_aprvl_prcs.refName)
                        );
                    }
                    objAccount.Partner__c = null;
                    if(customer.partner != null && customer.partner.refName != null){
                        objAccount.Partner__c = customer.partner.refName;
                        customLeadMap.put(
                            'partner-'+customer.partner.id,
                            new NetsuiteLead__c(Type__c = 'Partner', Name = 'partner-'+customer.partner.id, ID__c = customer.partner.id,Value__c = customer.partner.refName)
                        );
                    }
                    objAccount.Association__c = null;
                    if(customer.custentity2 != null && customer.custentity2.links != null){
                        for(NetsuiteCustomerParser.Link aLink : customer.custentity2.links){
                            if(aLink.href != null){
                                jsonResponse = NetsuiteConnection.getNetsuiteObject(aLink.href.substringAfter('/v1/') , '');
                                NetsuiteCustomerParser.Association associationCustomer = (NetsuiteCustomerParser.Association) json.deserialize(jsonResponse, NetsuiteCustomerParser.Association.class);
                                if(associationCustomer != null && associationCustomer.items != null){
                                    for(NetsuiteCustomerParser.AssocItem item : associationCustomer.items){
                                        if(item.refName != null){
                                            objAccount.Association__c = (objAccount.Association__c != null ? objAccount.Association__c + ';' : '') + item.refName;
                                            customLeadMap.put(
                                                'association-'+item.id,
                                                new NetsuiteLead__c(Type__c = 'Association', Name = 'association-'+item.Id, ID__c = item.id,Value__c = item.refName)
                                            );
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
                    if(customer.addressBook != null && customer.addressBook.links != null){
                        for(NetsuiteCustomerParser.Link alink : customer.addressBook.links){
                            if(alink.href != null){
                                jsonResponse = NetsuiteConnection.getNetsuiteObject(alink.href.substringAfter('/v1/') , '');
                                if(jsonResponse!=null){
                                    nsAddressbook = (NetsuiteAddressbookParser) json.deserialize(jsonResponse, NetsuiteAddressbookParser.class);
                                    if(nsAddressbook != null && nsAddressbook.items != null){
                                        for(NetsuiteAddressbookParser.Item item : nsAddressbook.items){
                                            for(NetsuiteAddressbookParser.Link ablink : item.links){
                                                if(ablink.href != null){
                                                    jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') , '');
                                                    if(jsonResponse!=null){
                                                        nsAddressbookDetail = (NetsuiteAddressbookParser.AddressBookDetail) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookDetail.class);
                                                        if(nsAddressbookDetail != null){
                                                            addressRecord = new Address__c();
                                                            addressRecord.NS_ID__c = nsAddressbookDetail.id;
                                                            addressRecord.Customer__c = objAccount.Id;
                                                            addressRecord.Default_Billing__c = nsAddressbookDetail.defaultBilling;
                                                            addressRecord.Default_Shipping__c = nsAddressbookDetail.defaultShipping;
                                                            jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') + '/addressbookaddress' , '');
                                                            if(jsonResponse!=null){
                                                                nsAddressbooAddress = (NetsuiteAddressbookParser.AddressBookAddress) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookAddress.class);
                                                                if(nsAddressbooAddress != null){
                                                                    addressRecord.Address_1__c = nsAddressbooAddress.addr1;
                                                                    addressRecord.Address_2__c = nsAddressbooAddress.addr2;
                                                                    addressRecord.Addressee__c = nsAddressbooAddress.addressee;
                                                                    addressRecord.Attention__c = nsAddressbooAddress.attention;
                                                                    addressRecord.City__c = nsAddressbooAddress.city;
                                                                    addressRecord.State__c = nsAddressbooAddress.state;
                                                                    addressRecord.Country__c = nsAddressbooAddress.country;
                                                                    addressRecord.Zip__c = nsAddressbooAddress.zip;
                                                                    addressRecord.Phone__c = nsAddressbooAddress.addrPhone;
                                                                    if(addressRecord.Default_Billing__c == true){
                                                                        objAccount.Address_Phone__c = nsAddressbooAddress.addrPhone;
                                                                        objAccount.Address_1__c = nsAddressbooAddress.addr1;
                                                                        objAccount.Address_2__c = nsAddressbooAddress.addr2;
                                                                        objAccount.Attention_Address__c = nsAddressbooAddress.attention;
                                                                        objAccount.BillingStreet = nsAddressbooAddress.addr1;
                                                                        objAccount.BillingState = nsAddressbooAddress.state;
                                                                        objAccount.BillingCity = nsAddressbooAddress.city;
                                                                        objAccount.BillingCountry = nsAddressbooAddress.country;
                                                                        objAccount.BillingPostalCode = nsAddressbooAddress.zip;
                                                                    }
                                                                    if(addressRecord.Default_Shipping__c == true){
                                                                        objAccount.ShippingStreet = nsAddressbooAddress.addr1;
                                                                        objAccount.ShippingState = nsAddressbooAddress.state;
                                                                        objAccount.ShippingCity = nsAddressbooAddress.city;
                                                                        objAccount.ShippingCountry = nsAddressbooAddress.country;
                                                                        objAccount.ShippingPostalCode = nsAddressbooAddress.zip;
                                                                    }
                                                                }
                                                            }
                                                            addressList.add(addressRecord);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                break;
                            }
                        }
                    }
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
        upsertResults = Database.upsert(accounts.values(), Account.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Customer Upsert Error: ' + upsertError.getMessage());
            }
        }
        
        ApexUtil.isAddressTriggerInvoked = false;
        upsertResults = Database.upsert(addressList,Address__c.NS_ID__c,false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Customer Upsert Error: ' + upsertError.getMessage());
            }
        }

        //Opps
		Set<String> customerIds = new Set<String>();        
        for(Opportunity oppRecord : [SELECT Id, AccountId FROM Opportunity WHERE Account.NS_ID__c IN: accounts.keySet() AND Shipping_Address_Code__c <> NULL AND Shipping_Address__c = NULL]) customerIds.add(oppRecord.AccountId);
        
        Map<String,String> addressMap = new Map<String,String>();
        for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__c IN: customerIds]) if(a.NS_ID__c != null) addressMap.put(a.NS_ID__c,a.Id);
        
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity oppRecord : [SELECT Id, AccountId, Shipping_Address_Code__c, Shipping_Address__c FROM Opportunity WHERE Account.NS_ID__c IN: accounts.keySet() AND Shipping_Address_Code__c <> NULL AND Shipping_Address__c = NULL]){
            if(addressMap.get(oppRecord.Shipping_Address_Code__c) != null){
                oppRecord.Shipping_Address__c = addressMap.get(oppRecord.Shipping_Address_Code__c);
                oppList.add(oppRecord);
            }
        }
        ApexUtil.isOpportunityTriggerInvoked = false;
        List<Database.saveResult> updateResults = Database.update(oppList,false);
        for(Database.saveResult updateResult:updateResults) {
            if(!updateResult.isSuccess()) {
                for(Database.Error updateError : updateResult.getErrors()) System.debug('NetsuiteGetCustomersBatch - Opportunity Update Error: ' + updateError.getMessage());
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetCustomersBatch');
        if(!Test.isRunningTest()) Database.executeBatch(new NetsuiteGetContactsBatch(startDate), 50);
    }
    
}