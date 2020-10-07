public class NetsuitePostCustomer {
    
    @future(callout=true)
	public static void postCustomersFromAccounts(Set<Id> customerIds){
        List<Account> accounts = [Select id, NS_ID__c, Name, NumberOfEmployees, Taxable__c, Web_Approved_CB__c,
                                  			Phone, OZlink_Billing_shipping_to_recip__c, Ozlink_Website__c, 
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Account 
                                   		where Id in:customerIds and Netsuite_Sync_Status__c != 'Synced'];
        
        String xmlBody = '', errorCode = null, errorString = null;
        HTTPResponse response;
        for(Account acc : accounts){
            xmlBody = '<update>' +
    					'	<platformMsgs:record internalId="' + acc.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
    					'		<listRel:companyName>' + account.Name + '</listRel:companyName>' +
    					'	</platformMsgs:record>' +
    		  			'</update>';
            
            response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
            errorCode = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultcode>', '</faultcode>') : null;
            errorString = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultstring>', '</faultstring>') : null;
            if(response.getStatusCode()==200 && errorCode==null && errorString==null){
                acc.Netsuite_To_Sync__c = false;
                acc.Netsuite_Sync_Status__c = 'Synced';
                acc.Netsuite_Sync_Error__c = '';
            } else {
                acc.Netsuite_To_Sync__c = false;
                acc.Netsuite_Sync_Status__c = 'Error';
                acc.Netsuite_Sync_Error__c = errorCode + '->' + errorString;
            }
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        if(accounts.size()>0) update accounts;
    }	
    
    @future(callout=true)
	public static void postCustomersFromLeads(Set<Id> customerIds){
        List<Lead> leads = [Select id, NS_ID__c, LastName, NumberOfEmployees, Taxable__c, Web_Approved_CB__c,
                                  			Phone, OZlink_Billing_shipping_to_recip__c, Ozlink_Website__c, 
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Lead 
                                   		where Id in:customerIds and Netsuite_Sync_Status__c != 'Synced'];
        
        String xmlBody = '', errorCode = null, errorString = null;
        HTTPResponse response;
        for(Lead l : leads){
            xmlBody = '<update>' +
    					'	<platformMsgs:record internalId="' + l.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
    					'		<listRel:companyName>' + l.LastName + '</listRel:companyName>' +
    					'	</platformMsgs:record>' +
    		  			'</update>';
            
            response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
            errorCode = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultcode>', '</faultcode>') : null;
            errorString = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultstring>', '</faultstring>') : null;
            if(response.getStatusCode()==200 && errorCode==null && errorString==null){
                l.Netsuite_To_Sync__c = false;
                l.Netsuite_Sync_Status__c = 'Synced';
                l.Netsuite_Sync_Error__c = '';
            } else {
                l.Netsuite_To_Sync__c = false;
                l.Netsuite_Sync_Status__c = 'Error';
                l.Netsuite_Sync_Error__c = errorCode + '->' + errorString;
            }
        }
        
        ApexUtil.isLeadTriggerInvoked = false;
        if(leads.size()>0) update leads;
    }	

}