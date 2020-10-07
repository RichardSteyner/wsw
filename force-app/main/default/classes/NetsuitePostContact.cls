public class NetsuitePostContact {
    
    @future(callout=true)
	public static void updateContacts(Set<Id> contactIds){
        List<Contact> contacts = [Select id, NS_ID__c, FirstName, LastName, Email, Global_Subscription_Status__c,
                                  			Phone, Inactive__c,  
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Contact 
                                   		where Id in:contactIds and Netsuite_Sync_Status__c != 'Synced'];
        
        String xmlBody = '', errorCode = null, errorString = null;
        HTTPResponse response;
        for(Contact con : contacts){
            xmlBody = '<update>' +
    					'	<platformMsgs:record internalId="' + con.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
    					'		<listRel:firstName>' + con.FirstName + '</listRel:companyName>' +
    					'	</platformMsgs:record>' +
    		  			'</update>';
            
            response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
            errorCode = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultcode>', '</faultcode>') : null;
            errorString = String.isNotBlank(response.getBody()) ? response.getBody().substringBetween('<faultstring>', '</faultstring>') : null;
            if(response.getStatusCode()==200 && errorCode==null && errorString==null){
                con.Netsuite_To_Sync__c = false;
                con.Netsuite_Sync_Status__c = 'Synced';
                con.Netsuite_Sync_Error__c = '';
            } else {
                con.Netsuite_To_Sync__c = false;
                con.Netsuite_Sync_Status__c = 'Error';
                con.Netsuite_Sync_Error__c = errorCode + '->' + errorString;
            }
        }
        
        ApexUtil.isContactTriggerInvoked = false;
        if(contacts.size()>0) update contacts;
    }

}