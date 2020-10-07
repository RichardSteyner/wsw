@isTest
public class Netsuite_Test {
    
    private static Netsuite__c authentication = Netsuite__c.getOrgDefaults();
    
    
	static{
        authentication.Base_URL_Soap__c = 'http://netsuite.com';
        insert authentication;
    }
	
    @isTest static void testListParser(){
        NetsuiteListParser nlp = new NetsuiteListParser();
        NetsuiteListParser.Link l = new NetsuiteListParser.Link();
        nlp.count = 1;
        l.rel = 'rel';
        l.href = 'href';
        nlp.links = new List<NetsuiteListParser.Link>();
        nlp.links.add(l);
    }
    
    @isTest static void testContactParser(){
        NetsuiteContactParser nlc = new NetsuiteContactParser();
        NetsuiteContactParser.Link l = new NetsuiteContactParser.Link();
        nlc.id = '111';
        nlc.owner = 312;
        l.rel = 'rel';
        l.href = 'href';
        nlc.links = new List<NetsuiteContactParser.Link>();
        nlc.links.add(l);
    }
    
    @isTest static void testSalesOrderParser(){
        NetsuiteSalesOrderParser nls = new NetsuiteSalesOrderParser();
        NetsuiteSalesOrderParser.Link l = new NetsuiteSalesOrderParser.Link();
        nls.id = '111';
        l.rel = 'rel';
        l.href = 'href';
        nls.links = new List<NetsuiteSalesOrderParser.Link>();
        nls.links.add(l);
    }
    
    @isTest static void testGetAllCustomersBatch(){
        //Map<String, Account> accountMap = new Map<String, Account> {'57676'=>new Account(LastName='Test', AdvancedMDID__C='57676', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient')!=null ? Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patient').getRecordTypeId() : null)};
        Test.startTest();
        Database.executeBatch(new NetsuiteGetAllCustomersBatch(30, 0), 30);
        Test.stopTest();
    }
    
    @isTest static void testGetAllContactsBatch(){
        Test.startTest();
        Database.executeBatch(new NetsuiteGetAllContactsBatch(30, 0), 30);
        Test.stopTest();
    }
    
    @isTest static void testGetAllSalesOrderBatch(){
        Test.startTest();
        Database.executeBatch(new NetsuiteGetAllSalesOrderBatch(30, 0), 30);
        Test.stopTest();
    }
    
    @isTest static void testGetCustomersBatch(){
        Test.startTest();
        Database.executeBatch(new NetsuiteGetCustomersBatch('', new Set<String>()), 30);
        Test.stopTest();
    }
    
    @isTest static void testGetContactsBatch(){
        Test.startTest();
        Database.executeBatch(new NetsuiteGetContactsBatch(''), 30);
        Test.stopTest();
    }
    
    @isTest static void testGetSalesOrderBatch(){
        Test.startTest();
        Database.executeBatch(new NetsuiteGetSalesOrderBatch(''), 30);
        Test.stopTest();
    }
    
    @isTest static void testPostAccountBatch(){
        Account acc = new Account(Name='Test', NS_ID__c='111', Website='test@cloudcreations.com');
        insert acc;
        acc.Industry = '<21> Machinery';
        update acc;
        Test.startTest();
        Database.executeBatch(new NetsuitePostAccountsBatch(''), 30);
        Test.stopTest();
    }
    
    @isTest static void testPostLeadBatch(){
        Lead l = new Lead(LastName='Test', Company='Cloud Creations', NS_ID__c='111');
        insert l;
        l.Industry = '<21> Machinery';
        update l;
        Test.startTest();
        Database.executeBatch(new NetsuitePostLeadsBatch(''), 30);
        Test.stopTest();
    }
    
    @isTest static void testPostContactBatch(){
        Contact con = new Contact(FirstName='Steyner', LastName='Urupeque', NS_ID__c='111');
        insert con;
        con.Inactive__c = true;
        update con;
        Test.startTest();
        Database.executeBatch(new NetsuitePostContactsBatch(''), 30);
        Test.stopTest();
    }
    
    @isTest static void testPostOpportunityBatch(){
        Opportunity opp = new Opportunity(Name='Steyner', StageName='Negotiation', CloseDate=Date.today(), NS_ID__c='111');
        insert opp;
        opp.Transaction_Date__c = Date.today();
        update opp;
        Test.startTest();
        Database.executeBatch(new NetsuitePostOpportunitiesBatch(''), 30);
        Test.stopTest();
    }

    @isTest static  void testXMLGetidsSuccess(){
        NetsuiteGetIds getCustomers = new NetsuiteGetIds('salesorder');
        List<String> ids =new List<String>();
        ids = getCustomers.getUpdatedIds('2020-08-18T07:00:00.000Z');
        getCustomers = new NetsuiteGetIds('customer');
        ids = getCustomers.getUpdatedIds('2020-08-18T07:00:00.000Z');
        getCustomers = new NetsuiteGetIds('contact');
        ids = getCustomers.getUpdatedIds('2020-08-18T07:00:00.000Z');
    }

}