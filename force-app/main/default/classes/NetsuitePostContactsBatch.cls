global class NetsuitePostContactsBatch implements Database.Batchable<Contact>, Database.Stateful, Database.AllowsCallouts {
    
	public String startDate;
    
    global NetsuitePostContactsBatch(String startDate){
        this.startDate = startDate;
    }
    
    global List<Contact> start(Database.BatchableContext BC){
        List<Contact> contacts = new List<Contact>();
        contacts = [Select id, NS_ID__c, FirstName, LastName, Email, Global_Subscription_Status__c,
                                  			Phone, Inactive__c,  
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Contact 
                                   		where Netsuite_To_Sync__c = true];
        
        return contacts;
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> scope){
        String xmlBody = '', errorCode = null, errorString = null, errorSuccess = null;
        HTTPResponse response;
        for(Contact con : scope){
            try{
                xmlBody = '<update>' +
                            '	<platformMsgs:record internalId="' + con.NS_ID__c + '" xsi:type="listRel:Contact" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
                            '		<listRel:firstName>' + con.FirstName + '</listRel:firstName>' +
                    		'		<listRel:lastName>' + con.LastName + '</listRel:lastName>' +
                    		'		<listRel:email>' + con.Email + '</listRel:email>' +
                    		'		<listRel:globalSubscriptionStatus>' + con.Global_Subscription_Status__c + '</listRel:globalSubscriptionStatus>' +
                    		/*<listRel:company internalId="238111" />*/
                    		'		<listRel:phone>' + con.Phone + '</listRel:phone>' +
                    		'		<listRel:isInactive>' + con.Inactive__c + '</listRel:isInactive>' +
                            '	</platformMsgs:record>' +
                            '</update>';
                
                response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
                
                if(String.isNotBlank(response.getBody())){
                    errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                    errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                    errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"')=='false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                }
                if(response.getStatusCode()==200 && errorCode==null && errorString==null && errorSuccess==null){
                    con.Netsuite_To_Sync__c = false;
                    con.Netsuite_Sync_Status__c = 'Synced';
                    con.Netsuite_Sync_Error__c = '';
                } else {
                    con.Netsuite_To_Sync__c = false;
                    con.Netsuite_Sync_Status__c = 'Error';
                    if(errorSuccess!=null)
                        con.Netsuite_Sync_Error__c = errorSuccess.left(255);
                    else
                    	con.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                }
            }catch(Exception e){
                con.Netsuite_To_Sync__c = false;
                con.Netsuite_Sync_Status__c = 'Error';
                con.Netsuite_Sync_Error__c = ('NetsuitePostContactsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage()).left(255);
            	System.debug('NetsuitePostContactsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isContactTriggerInvoked = false;
        if(scope.size()>0) update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuitePostContactsBatch');
        if(!Test.isRunningTest()){
            Database.executeBatch(new NetsuitePostOpportunitiesBatch(startDate), 15);
        }
    }

}