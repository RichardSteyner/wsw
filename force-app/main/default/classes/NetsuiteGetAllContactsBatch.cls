global class NetsuiteGetAllContactsBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

	public Integer size;
	public Integer offset;
	public Boolean hasMore;    
    
    global NetsuiteGetAllContactsBatch(Integer size, Integer offset){
        this.size = size;
        this.offset = offset;
        hasMore = true;
    }
    
    global List<String> start(Database.BatchableContext BC){
        List<String> nsIds = new List<String>(); 
        try{
            Date auxFecha = Date.valueOf('2020-08-19');
          	String filtroFecha = 'lastModifiedDate%20AFTER%20"' + auxFecha.month() + '/' + auxFecha.day() + '/' + auxFecha.year() + '"';
            NetsuiteListParser listContacts = (NetsuiteListParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('contact', 'limit=' + size + '&offset=' + offset + '&q=' + filtroFecha), NetsuiteListParser.class);
            hasMore = listContacts.hasMore;
            for(NetsuiteListParser.Item auxItem : listContacts.items){
				nsIds.add(auxItem.id);
            }
            offset = offset + size;
        }catch(Exception e){
            hasMore = false;
            System.debug('NetsuiteGetAllContactsBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteContactParser nsContact;
        Contact objContact;
        Account objAccount;
        Map<String, Contact> contacts = new Map<String, Contact>();
        Map<String, Id> companyAccounts = new Map<String, Id>();
        Map<String, Account> entityAccounts = new Map<String, Account>();
    	for(String auxId : scope){
            System.debug(auxId);
        	try{
                nsContact = (NetsuiteContactParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('contact/' + auxId, ''), NetsuiteContactParser.class);
                //System.debug('-----------CONTACT------------');
                //System.debug(nsContact);
                //System.debug('-----------CONTACT------------');
                
                objContact = new Contact(NS_ID__c=auxId, Company_Id__c=nsContact.getCompanyId(), FirstName=nsContact.firstName, LastName=nsContact.getLastName(),
                                         Phone=nsContact.phone, Email=nsContact.email, Inactive__c=nsContact.isinactive,
                                         Global_Subscription_Status__c=ApexUtil.globalSubscriptionStatusContact.get(nsContact.globalsubscriptionstatus));
                
                if(nsContact.getCompanyId()!=null){
                    companyAccounts.put(nsContact.getCompanyId(), null);
                    contacts.put(auxId, objContact);
                }else if(nsContact.entityId!=null && String.isNotBlank(nsContact.entityId)){
                    objAccount = new Account(Entity_NS_ID__c=nsContact.entityId.trim().toUpperCase(), Name=nsContact.entityId);
                    objContact.Entity_Id__c=nsContact.entityId.trim().toUpperCase();
                    entityAccounts.put(nsContact.entityId.trim().toUpperCase(), objAccount);
                    contacts.put(auxId, objContact);
                }
           	}catch(Exception e){
            	System.debug('NetsuiteGetAllContactsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.UpsertResult> upsertResults;
        upsertResults = Database.upsert(entityAccounts.values(), Account.Entity_NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) 
                    System.debug('NetsuiteGetAllContactsBatch - Entity Upsert Error: ' + upsertError.getMessage());
            }
        }
        
        for(Account a : [select Id, NS_ID__c from Account where NS_ID__c in: companyAccounts.keySet()])
            companyAccounts.put(a.NS_ID__c, a.Id);
                
		for(Contact c : contacts.values()){
			if(c.Company_Id__c!=null)
            {
            	if(companyAccounts.get(c.Company_Id__c)!=null) 
                	c.AccountId=companyAccounts.get(c.Company_Id__c);
                else
                    System.debug('Cannot relate to company: ' + c.Company_Id__c);
            }else if(c.Entity_Id__c!=null){
                if(entityAccounts.get(c.Entity_Id__c)!=null && entityAccounts.get(c.Entity_Id__c).Id!=null) 
                	c.AccountId=entityAccounts.get(c.Entity_Id__c).Id;
                else
                    System.debug('Cannot relate to entity: ' + c.Entity_Id__c);
            }
        }
        
		ApexUtil.isContactTriggerInvoked = false;        
       	upsertResults = Database.upsert(contacts.values(), Contact.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) 
                	System.debug('NetsuiteGetAllContactsBatch - Contact Upsert Error: ' + upsertError.getMessage());
            }
     	}
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetAllContactsBatch');
        if(!Test.isRunningTest()){
            if(hasMore){
                Database.executeBatch(new NetsuiteGetAllContactsBatch(size, offset), 30);
            }
        }
    }
    
}