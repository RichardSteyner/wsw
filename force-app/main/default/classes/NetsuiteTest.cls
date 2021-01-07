@isTest
private class NetsuiteTest {
    public static String CRON_EXP = '0 0 0 15 3 ? 2030';
    static void createData(){
        Netsuite__c netsuite = Netsuite__c.getOrgDefaults();
        netsuite.Base_URL_Soap__c = 'https://1030411.suitetalk.api.netsuite.com/services/NetSuitePort_2020_1';
        netsuite.Base_URL__c = 'https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/';
        netsuite.Account_Id__c = '1030411';
        netsuite.Products_Exception__c = 'none';
        insert netsuite;
        
        NetsuiteLead__c netsuiteLead = new NetsuiteLead__c(Name = 'approvalprocess-1', ID__c = '1', Type__c = 'ApprovalProcess', Value__c = 'Not started');
        insert netsuiteLead;
        
        NetsuiteOpp__c netsuiteOpp = new NetsuiteOpp__c(Name = 'graphics-10', ID__c = '10', Type__c = 'Graphics', Value__c = 'Manny R Rodriguez');
        insert netsuiteOpp;
        
        NetsuiteOpp__c netsuiteOpp2 = new NetsuiteOpp__c(Name = 'stage-2', ID__c = '2', Type__c = 'Stage', Value__c = 'Graphics');
        insert netsuiteOpp2;
    }
    static testMethod void NetsuiteSchedule_Test(){
        Test.startTest();
            System.schedule('NetsuiteSchedule',CRON_EXP,new NetsuiteSchedule());
        Test.stopTest();
    }
    @isTest static void NetsuiteMethods_getEstimate_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        Opportunity oppRecord = new Opportunity(Name = 'Test',NS_ID__c = '7792583',CloseDate = system.today(), StageName = 'Sales');
        insert oppRecord;
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        NetsuiteMethods.getEstimate(oppRecord.Id);
        Test.stopTest();
    }
    @isTest static void NetsuiteMethods_getCustomer_Test(){
        createData();
        ApexUtil.isAccountTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test',NS_ID__c = '123');
        insert accRecord;
        Test.startTest();
        NetsuiteMethods.getCustomer(accRecord.Id);
        Test.stopTest();
    }
    @isTest static void NetsuiteMethods_getContact_Test(){
        createData();
        ApexUtil.isContactTriggerInvoked = false;
        Contact contactRecord = new Contact(Lastname = 'Test',NS_ID__c = '123');
        insert contactRecord;
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        NetsuiteMethods.getContact(contactRecord.Id);
        Test.stopTest();
    }
    @isTest static void upsertContact_Test(){
        createData();
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        Contact contactRecord = new Contact(Lastname = 'Test');
        insert contactRecord;
        Test.stopTest();
    }
    @isTest static void addCustomer_Test(){
        createData();
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        Account accRecord = new Account(Name = 'Test');
        insert accRecord;
        Test.stopTest();
    }
    @isTest static void updateCustomer_Test(){
        createData();
        ApexUtil.isAccountTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123');
        insert accRecord;
        Address__c addressRecord = new Address__c(Customer__c = accRecord.Id, Address_1__c = 'Test', Country__c = 'US', City__c = 'New York', State__c = 'NY', Default_Shipping__c =  true, Default_Billing__c = true);
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isAccountTriggerInvoked = true;
        insert addressRecord;
        Test.stopTest();
    }
    @isTest static void accountTriggerUpdateCreateAddress_Test(){
        createData();
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123');
        insert accRecord;
        Address__c addressRecord = new Address__c(Customer__c = accRecord.Id, Address_1__c = 'Test', Country__c = 'US', City__c = 'New York', State__c = 'NY', Default_Shipping__c =  true, Default_Billing__c = true);
        insert addressRecord;
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        accRecord.ShippingStreet = 'Change Test';
        accRecord.BillingStreet = 'Change Test';
        update accRecord;
        Test.stopTest();
    }
    @isTest static void accountTriggerUpdateUpdateAddress_Test(){
        createData();
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Address__c addressRecord = new Address__c(Customer__c = accRecord.Id, Address_1__c = 'Test', Country__c = 'US', City__c = 'New York', State__c = 'NY', Default_Shipping__c =  true, Default_Billing__c = true);
        insert addressRecord;
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        accRecord.ShippingPostalCode = '4000';
        accRecord.BillingPostalCode = '4000';
        update accRecord;
        Test.stopTest();
    }
    @isTest static void addressTrigger_Test(){
        createData();
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Address__c addressRecord = new Address__c(Customer__c = accRecord.Id, Address_1__c = 'Test', Country__c = 'US', City__c = 'New York', State__c = 'NY');
        insert addressRecord;
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isAddressTriggerInvoked = true;
        addressRecord.Default_Shipping__c = true;
        addressRecord.Default_Billing__c = true;
        update addressRecord;
        Test.stopTest();
    }
    @isTest static void opportunityTrigger_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        ApexUtil.isAccountTriggerInvoked = false;
        ApexUtil.isOliTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Product2 prodRecord = new Product2(Name = 'Test',isActive = true, NS_ID__c = '3668');
        insert prodRecord;
        PricebookEntry pbe = new PricebookEntry(Product2Id = prodRecord.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1, isActive = true);
        insert pbe;
        Opportunity oppRecord = new Opportunity(Name = 'test',CloseDate = system.today(), StageName = 'Estimate', AccountId = accRecord.Id);
        insert oppRecord;
        OpportunityLineItem oliRecord = new OpportunityLineItem(OpportunityId = opprecord.Id, PricebookEntryId = pbe.Id,UnitPrice = 1, Quantity = 1);
        insert oliRecord;
        ApexUtil.isOpportunityTriggerInvoked = false;
        
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isOpportunityTriggerInvoked = true;
        update oppRecord;
        Test.stopTest();
    }
    
    @isTest static void opportunityTriggerUpdateEstimate_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        ApexUtil.isAccountTriggerInvoked = false;
        ApexUtil.isOliTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Product2 prodRecord = new Product2(Name = 'Test',isActive = true, NS_ID__c = '3668');
        insert prodRecord;
        PricebookEntry pbe = new PricebookEntry(Product2Id = prodRecord.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1, isActive = true);
        insert pbe;
        Opportunity oppRecord = new Opportunity(Name = 'test',CloseDate = system.today(), StageName = 'Estimate', AccountId = accRecord.Id,NS_Estimate_ID__c = '123');
        insert oppRecord;
        OpportunityLineItem oliRecord = new OpportunityLineItem(OpportunityId = opprecord.Id, PricebookEntryId = pbe.Id,UnitPrice = 1, Quantity = 1);
        insert oliRecord;
        ApexUtil.isOpportunityTriggerInvoked = false;
        
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isOpportunityTriggerInvoked = true;
        update oppRecord;
        Test.stopTest();
    }
    @isTest static void opportunityTriggerConvertSale_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        ApexUtil.isAccountTriggerInvoked = false;
        ApexUtil.isOliTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Product2 prodRecord = new Product2(Name = 'Test',isActive = true, NS_ID__c = '3668');
        insert prodRecord;
        PricebookEntry pbe = new PricebookEntry(Product2Id = prodRecord.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1, isActive = true);
        insert pbe;
        Opportunity oppRecord = new Opportunity(Name = 'test',CloseDate = system.today(), StageName = 'Estimate', AccountId = accRecord.Id,NS_Estimate_ID__c = '123');
        insert oppRecord;
        OpportunityLineItem oliRecord = new OpportunityLineItem(OpportunityId = opprecord.Id, PricebookEntryId = pbe.Id,UnitPrice = 1, Quantity = 1);
        insert oliRecord;
        ApexUtil.isOpportunityTriggerInvoked = false;
        
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isOpportunityTriggerInvoked = true;
        oppRecord.StageName = 'Sales';
        update oppRecord;
        Test.stopTest();
    }
    @isTest static void opportunityTriggerUpdateSale_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        ApexUtil.isAccountTriggerInvoked = false;
        ApexUtil.isOliTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Product2 prodRecord = new Product2(Name = 'Test',isActive = true, NS_ID__c = '3668');
        insert prodRecord;
        PricebookEntry pbe = new PricebookEntry(Product2Id = prodRecord.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1, isActive = true);
        insert pbe;
        Opportunity oppRecord = new Opportunity(Name = 'test',CloseDate = system.today(), StageName = 'Sales', AccountId = accRecord.Id,NS_Estimate_ID__c = '123',NS_ID__c = '123');
        insert oppRecord;
        OpportunityLineItem oliRecord = new OpportunityLineItem(OpportunityId = opprecord.Id, PricebookEntryId = pbe.Id,UnitPrice = 1, Quantity = 1);
        insert oliRecord;
        ApexUtil.isOpportunityTriggerInvoked = false;
        
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isOpportunityTriggerInvoked = true;
        oppRecord.StageName = 'Graphics';
        update oppRecord;
        Test.stopTest();
    }
    @isTest static void opportunityLineItemTrigger_Test(){
        createData();
        ApexUtil.isOpportunityTriggerInvoked = false;
        ApexUtil.isAccountTriggerInvoked = false;
        ApexUtil.isOliTriggerInvoked = false;
        Account accRecord = new Account(Name = 'Test', NS_ID__c = '123', BillingStreet = 'Test', BillingCountry = 'US', BillingCity = 'New York', BillingState = 'NY');
        insert accRecord;
        Product2 prodRecord = new Product2(Name = 'Test',isActive = true, NS_ID__c = '3668');
        insert prodRecord;
        PricebookEntry pbe = new PricebookEntry(Product2Id = prodRecord.Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 1, isActive = true);
        insert pbe;
        Opportunity oppRecord = new Opportunity(Name = 'test',CloseDate = system.today(), StageName = 'Sales', AccountId = accRecord.Id,NS_Estimate_ID__c = '123',NS_ID__c = '123');
        insert oppRecord;
        
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        ApexUtil.isOpportunityTriggerInvoked = true;
        ApexUtil.isOliTriggerInvoked = true;
        OpportunityLineItem oliRecord = new OpportunityLineItem(OpportunityId = opprecord.Id, PricebookEntryId = pbe.Id,UnitPrice = 1, Quantity = 1);
        insert oliRecord;
        Test.stopTest();
    }
    @isTest static void testGetContactsBatch(){
        createData();
        Test.startTest();
        Database.executeBatch(new NetsuiteGetContactsBatch(''), 30);
        Test.stopTest();
    }
    @isTest static void testGetCustomersBatch(){
        createData();
        Test.startTest();
        Database.executeBatch(new NetsuiteGetCustomersBatch('', new Set<String>()), 30);
        Test.stopTest();
    }
    @isTest static void testGetSalesOrderBatch(){
        createData();
        system.Test.setMock(HttpCalloutMock.class, new NetsuiteMockImplementation());
        Test.startTest();
        Database.executeBatch(new NetsuiteGetSalesOrderBatch(''), 30);
        Test.stopTest();
    }
    @isTest static void testContactParser(){
        NetsuiteContactParser nlc = new NetsuiteContactParser();
        NetsuiteContactParser.Link l = new NetsuiteContactParser.Link();
        NetsuiteContactParser.Company c = new NetsuiteContactParser.Company();
        nlc.id = '111';
        nlc.entityId = '1';
        nlc.globalsubscriptionstatus = '1';
        nlc.isinactive = false;
        nlc.owner = 312;
        l.rel = 'rel';
        l.href = 'href';
        nlc.links = new List<NetsuiteContactParser.Link>();
        nlc.links.add(l);
        c.id = '1';
        c.refName = 'test';
        nlc.company = c;
        nlc.getCompanyId();
        nlc.getLastName();
    }
    @isTest static void testListParser(){
        NetsuiteListParser nlp = new NetsuiteListParser();
        NetsuiteListParser.Link l = new NetsuiteListParser.Link();
        NetsuiteListParser.Item i = new NetsuiteListParser.Item();
        nlp.count = 1;
        nlp.hasMore = false;
        l.rel = 'rel';
        l.href = 'href';
        nlp.links = new List<NetsuiteListParser.Link>();
        nlp.links.add(l);
        i.links = new List<NetsuiteListParser.Link>();
        i.id = '1';
        nlp.items = new List<NetsuiteListParser.Item>();
        nlp.items.add(i);
    }
    @istest static void testNetsuiteCustomerParser(){
        NetsuiteCustomerParser ncp = new NetsuiteCustomerParser();
        NetsuiteCustomerParser.Link l = new NetsuiteCustomerParser.Link();
        NetsuiteCustomerParser.ContactZ c = new NetsuiteCustomerParser.ContactZ();
        ncp.custentity_exhibit_catalog = false;
        ncp.custentity_firstorder_email = false;
        ncp.custentity_resort_catalog = false;
        ncp.defaultAddress = 'test';
        l.rel = 'rel';
        l.href = 'href';
        ncp.links = new List<NetsuiteCustomerParser.Link>();
        ncp.links.add(l);
        c.id = '1';
        c.refName = 'test';
        c.links = new List<NetsuiteCustomerParser.Link>();
        c.links.add(l);
        ncp.contact = c;
        ncp.getParentName();
    }
    @isTest static void testNetsuiteAddressbookParser(){
        NetsuiteAddressbookParser nap = new NetsuiteAddressbookParser();
        NetsuiteAddressbookParser.Link l = new NetsuiteAddressbookParser.Link();
        l.rel = 'rel';
        l.href = 'href';
        nap.links = new List<NetsuiteAddressbookParser.Link>();
        nap.links.add(l);
    }
    @isTest static void testApexUtil(){
        Map<String,Object> customerMap = new Map<String,Object>();
        customerMap.put('1',new NetsuiteLead__c(Type__c = 'LeadSource',Value__c = 'Test',ID__c = '1'));
        customerMap.put('2',new NetsuiteLead__c(Type__c = 'CCProcessor',Value__c = 'Test',ID__c = '1'));
        customerMap.put('3',new NetsuiteLead__c(Type__c = 'PriceLevel',Value__c = 'Test',ID__c = '1'));
        customerMap.put('4',new NetsuiteLead__c(Type__c = 'EntityStatus',Value__c = 'Test',ID__c = '1'));
        customerMap.put('5',new NetsuiteLead__c(Type__c = 'Partner',Value__c = 'Test',ID__c = '1'));
        customerMap.put('6',new NetsuiteLead__c(Type__c = 'Terms',Value__c = 'Test',ID__c = '1'));
        customerMap.put('7',new NetsuiteLead__c(Type__c = 'TaxItem',Value__c = 'Test',ID__c = '1'));
        customerMap.put('8',new NetsuiteLead__c(Type__c = 'SalesRep',Value__c = 'Test',ID__c = '1'));
        customerMap.put('9',new NetsuiteLead__c(Type__c = 'Industry',Value__c = 'Test',ID__c = '1'));
        customerMap.put('10',new NetsuiteLead__c(Type__c = 'TypeOfCustomer',Value__c = 'Test',ID__c = '1'));
        customerMap.put('11',new NetsuiteLead__c(Type__c = 'Association',Value__c = 'Test',ID__c = '1'));
        customerMap.put('12',new NetsuiteLead__c(Type__c = 'ApprovalProcess',Value__c = 'Test',ID__c = '1'));
        customerMap.put('13',new NetsuiteLead__c(Type__c = 'Employee',Value__c = 'Test',ID__c = '1'));
        customerMap.put('14',new NetsuiteLead__c(Type__c = 'HowDidYourHear',Value__c = 'Test',ID__c = '1'));
        customerMap.put('15',new NetsuiteLead__c(Type__c = 'HowDidYourHearTradeShow',Value__c = 'Test',ID__c = '1'));
        
        Map<String,Object> orderMap = new Map<String,Object>();
        orderMap.put('1',new NetsuiteOpp__c(Type__c = 'ShipMethod',Value__c = 'Test',ID__c = '1'));
        orderMap.put('2',new NetsuiteOpp__c(Type__c = 'OrderDetail',Value__c = 'Test',ID__c = '1'));
        orderMap.put('3',new NetsuiteOpp__c(Type__c = 'Stage',Value__c = 'Test',ID__c = '1'));
        
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','prefCCProcessor', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','leadSource', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','priceLevel', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','entityStatus', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','Partner', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','Terms', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','TaxItem', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('customer',customerMap,'Test','SalesRep', 'listRel');
        ApexUtil.getFieldSettingNetsuiteXML('order',orderMap,'Test','shipMethod', 'listRel');
        
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentity_esc_industry', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentity_typeofcustomer', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentity2', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentity_ws_accnt_aprvl_prcs', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentitycustentity_certificate_app_by', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentity45', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentitylead_survey', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customerMap,'Test', 'custentitylead_survey_tradeshow_value', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('order',orderMap,'Test', 'custbody11', '1', '1');
        ApexUtil.getFieldSettingCustomSelectNetsuiteXML('order',orderMap,'Test', 'custbody_orderstatus', '1', '1');
    }
}