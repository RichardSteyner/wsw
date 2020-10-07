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
                System.debug('-----------CONTACT------------');
                System.debug(nsContact);
                objContact = new Contact(NS_ID__c=auxId,Company_Id__c=nsContact.getCompanyId(),Phone=nsContact.phone,Inactive__c=nsContact.isinactive,Global_Subscription_Status__c=ApexUtil.globalSubscriptionStatusContact.get(nsContact.globalsubscriptionstatus));
                objContact.LastName = (nsContact.entityId != null ? (nsContact.entityId.indexOf(' ') > 0 ? nsContact.entityId.subStringAfter(' ') : nsContact.entityId)  : nsContact.lastName);
                objContact.FirstName = (nsContact.entityId != null ? (nsContact.entityId.indexOf(' ') > 0 ? nsContact.entityId.subStringBefore(' ') : null)  : nsContact.firstName);
                if(nsContact.email != null){
                    MyPattern = Pattern.compile(emailRegex);
                    MyMatcher = MyPattern.matcher(nsContact.email);
                    if(MyMatcher.matches()) objContact.Email = nsContact.email;
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
                                                    nsAddressbookDetail = (NetsuiteAddressbookParser.AddressBookDetail) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookDetail.class);
                                                    if(nsAddressbookDetail != null && nsAddressbookDetail.defaultBilling != null && nsAddressbookDetail.defaultBilling == true){
                                                        jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') + '/addressbookaddress' , '');
                                                        if(jsonResponse!=null){
                                                            nsAddressbooAddress = (NetsuiteAddressbookParser.AddressBookAddress) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookAddress.class);
                                                            objContact.MailingStreet = (nsAddressbooAddress.addr1 != null ? nsAddressbooAddress.addr1 : null);
                                                            objContact.Addressee__c = (nsAddressbooAddress.addressee != null ? nsAddressbooAddress.addressee : null);
                                                            objContact.MailingCity = nsAddressbooAddress.city;
                                                            objContact.MailingState = nsAddressbooAddress.state;
                                                            objContact.MailingCountry = nsAddressbooAddress.country;
                                                            objContact.Country_Code__c = nsAddressbooAddress.country;
                                                            objContact.MailingPostalCode = nsAddressbooAddress.zip;
                                                            objContact.Address_Phone__c = nsAddressbooAddress.addrPhone;
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
                if(objContact.LastName != null){
                    if(nsContact.getCompanyId() != null) companyAccounts.put(nsContact.getCompanyId(), null);
                  
                    if(nsContact.owner!=null){
                        objContact.Owner_NS_ID__c=String.valueOf(nsContact.owner); 
                        userIds.put(String.valueOf(nsContact.owner), null);
                    }
                    contacts.put(auxId, objContact);
                }
            }
        }

        if(!contacts.isEmpty()){
            for(User u : [select Id, NS_ID__c from User where NS_ID__c in: userIds.keySet()]) userIds.put(u.NS_ID__c, u.Id);
            
            for(Account a : [select Id, NS_ID__c from Account where NS_ID__c in: companyAccounts.keySet()]) companyAccounts.put(a.NS_ID__c, a.Id);
            
            for(Contact c : contacts.values()){
                if(c.Company_Id__c!=null && companyAccounts.get(c.Company_Id__c) != null) c.AccountId = companyAccounts.get(c.Company_Id__c);
                if(c.Owner_NS_ID__c!=null && userIds.get(c.Owner_NS_ID__c) != null) c.OwnerId=userIds.get(c.Owner_NS_ID__c);
            }
            
            ApexUtil.isContactTriggerInvoked = false;        
            List<Database.UpsertResult> upsertResults = Database.upsert(contacts.values(), Contact.NS_ID__c, false);
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