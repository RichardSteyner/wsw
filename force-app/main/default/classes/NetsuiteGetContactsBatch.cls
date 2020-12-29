global class NetsuiteGetContactsBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

    public String startDate;   
    
    global NetsuiteGetContactsBatch(String startDate){
        this.startDate = startDate;
    }
    
    global List<String> start(Database.BatchableContext BC){
        List<String> nsIds = new List<String>(); 
        try{
        	NetsuiteGetIds getContacts = new NetsuiteGetIds('contact');
			List<String> auxList = getContacts.getUpdatedIds(startDate);
            nsIds.addAll(auxList);
        }catch(Exception e){
            System.debug('NetsuiteGetContactsBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteContactParser nsContact;
        NetsuiteAddressbookParser nsAddressbook;
        NetsuiteAddressbookParser.AddressBookDetail nsAddressbookDetail;
        NetsuiteAddressbookParser.AddressBookAddress nsAddressbooAddress;
        String jsonResponse;
        Contact objContact;
        Account objAccount;
        Map<String, Contact> contacts = new Map<String, Contact>();
        Map<String, Id> companyAccounts = new Map<String, Id>();
        Map<String, Id> userIds = new Map<String, Id>();
        String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
        Pattern MyPattern;
        Matcher MyMatcher;
        for(String auxId : scope){
            jsonResponse = NetsuiteConnection.getNetsuiteObject('contact/' + auxId, '');
            if(jsonResponse!=null){
                nsContact = (NetsuiteContactParser) json.deserialize(jsonResponse, NetsuiteContactParser.class);
                objContact = new Contact(NS_ID__c=auxId);
                objContact.Customer_ID__c = (nsContact.company != null ? nsContact.company.id : null);
                objContact.LastName = nsContact.lastName;
                objContact.FirstName = nsContact.firstName;
                objContact.Salutation = nsContact.salutation;
                objContact.Title = nsContact.title;
                objContact.Phone = nsContact.phone;
                objContact.Fax = nsContact.fax;
                objContact.MobilePhone = nsContact.mobilePhone;
                objContact.OtherPhone = nsContact.officePhone;
                objContact.HomePhone = nsContact.homePhone;
                if(nsContact.altEmail != null){
                    MyPattern = Pattern.compile(emailRegex);
                    MyMatcher = MyPattern.matcher(nsContact.altEmail);
                    if(MyMatcher.matches()) objContact.Alt_Email__c = nsContact.altEmail;
                }
                if(nsContact.email != null){
                    MyPattern = Pattern.compile(emailRegex);
                    MyMatcher = MyPattern.matcher(nsContact.email);
                    if(MyMatcher.matches()) objContact.Email = nsContact.email;
                }
                if(objContact.LastName != null && objContact.LastName.trim() != '') contacts.put(auxId, objContact);
            }
        }

        if(!contacts.isEmpty()){
            Set<String> customerIds = new Set<String>();
            for(Contact c : contacts.values()) if(c.Customer_ID__c != null) customerIds.add(c.Customer_ID__c);
            
            Map<String,Account> customerMap = new Map<String,Account>();
            for(Account a : [SELECT Id, NS_ID__c from Account WHERE NS_ID__c IN: customerIds]) customerMap.put(a.NS_ID__c, a);
            
            List<Contact> contactUpsert = new List<Contact>();
            for(Contact c : contacts.values()){
                if(c.Customer_ID__c!=null && customerMap.get(c.Customer_ID__c) != null){
                    c.AccountId = customerMap.get(c.Customer_ID__c).Id;
                    contactUpsert.add(c);
                }
            }
            
            ApexUtil.isContactTriggerInvoked = false;        
            List<Database.UpsertResult> upsertResults = Database.upsert(contactUpsert, Contact.NS_ID__c, false);
            for(Database.UpsertResult upsertResult:upsertResults){
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetContactsBatch - Contact Upsert Error: ' + upsertError.getMessage());
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetContactsBatch');
    }
}