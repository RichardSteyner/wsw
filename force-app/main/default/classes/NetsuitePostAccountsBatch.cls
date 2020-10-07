global class NetsuitePostAccountsBatch implements Database.Batchable<Account>, Database.Stateful, Database.AllowsCallouts {
    
	public String startDate;
    public Map<String,Object> customSettingMap = new Map<String,Object>();
    
    global NetsuitePostAccountsBatch(String startDate){
        this.startDate = startDate;
        
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
    }
    
    global List<Account> start(Database.BatchableContext BC){
        List<Account> accounts = new List<Account>();
        accounts = [Select id, NS_ID__c, Name, NumberOfEmployees, Taxable__c, Web_Approved_CB__c, Website, 
                                  			Phone, OZlink_Billing_shipping_to_recip__c, Ozlink_Website__c, 
                        					OZlink_Bill_shipping_to_3rd__c, Industry, Type_of_Customer__c, 
                     						CC_Processor__c, AccountSource, Price_Level__c, Netsuite_Status__c,  
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Account 
                                   		where Netsuite_To_Sync__c = true limit 30];
        
        return accounts;
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope){
        String xmlBody = '', errorCode = null, errorString = null, errorSuccess = null;
        HTTPResponse response;
        String industryXML='', typeCustomerXML='', leadSourceXML='', prefCcProcessorXML='', priceLevelXML='', entityStatusXML='';
        for(Account acc : scope){
            try{
                leadSourceXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,acc.AccountSource, 'leadSource', 'listRel');
                prefCcProcessorXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,acc.CC_Processor__c, 'prefCCProcessor', 'listRel');
                priceLevelXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,acc.Price_Level__c, 'priceLevel', 'listRel');
                entityStatusXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,acc.Netsuite_Status__c, 'entityStatus', 'listRel');
                industryXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,acc.Industry, 'custentity_esc_industry', '19', '2');
                typeCustomerXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,acc.Type_of_Customer__c, 'custentity_typeofcustomer', '44', '-186');
                
                xmlBody = '<update>' +
                            '	<platformMsgs:record internalId="' + acc.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
                            '		<listRel:companyName>' + acc.Name + '</listRel:companyName>' +
                    		'		<listRel:url>' + acc.Website + '</listRel:url>' +
                    		'		<listRel:phone>' + acc.Phone + '</listRel:phone>' +
                    		'		<listRel:taxable>' + acc.Taxable__c + '</listRel:taxable>' +
                    		leadSourceXML + 
                    		prefCcProcessorXML + 
                    		priceLevelXML + 
                    		entityStatusXML + 
                    		'		<listRel:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                    		'			<platformCore:customField internalId="1187" scriptId="custentity_sc_web_approved" xsi:type="platformCore:BooleanCustomFieldRef">' + 
                        	'				<platformCore:value>' + acc.Web_Approved_CB__c + '</platformCore:value>' +
                    		'			</platformCore:customField>' +
                    		'			<platformCore:customField internalId="18" scriptId="custentity_esc_no_of_employees" xsi:type="platformCore:LongCustomFieldRef">' + 
                            '               <platformCore:value>' + acc.NumberOfEmployees + '</platformCore:value>' + 
                            '           </platformCore:customField>' + 
                    		'			<platformCore:customField internalId="84" scriptId="custentity_ozlink_bill_shipping_to_3rd" xsi:type="platformCore:BooleanCustomFieldRef">' + 
                            '           	<platformCore:value>' + acc.OZlink_Bill_shipping_to_3rd__c + '</platformCore:value>' +
                            '        	</platformCore:customField>' + 
                            '        	<platformCore:customField internalId="83" scriptId="custentity_ozlink_bill_shipping_to_recip" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '            	<platformCore:value>' + acc.OZlink_Billing_shipping_to_recip__c + '</platformCore:value>' +
                            '        	</platformCore:customField>' +
                    		industryXML +
                    		typeCustomerXML + 
                    		'		</listRel:customFieldList>' + 
                            '	</platformMsgs:record>' +
                            '</update>';
                
                response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
                
                if(String.isNotBlank(response.getBody())){
                    errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                    errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                    errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"')=='false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                }
                if(response.getStatusCode()==200 && errorCode==null && errorString==null && errorSuccess==null){
                    acc.Netsuite_To_Sync__c = false;
                    acc.Netsuite_Sync_Status__c = 'Synced';
                    acc.Netsuite_Sync_Error__c = '';
                } else {
                    acc.Netsuite_To_Sync__c = false;
                    acc.Netsuite_Sync_Status__c = 'Error';
                    if(errorSuccess!=null)
                        acc.Netsuite_Sync_Error__c = errorSuccess.left(255);
                    else
                    	acc.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                }
            }catch(Exception e){
                acc.Netsuite_To_Sync__c = false;
                acc.Netsuite_Sync_Status__c = 'Error';
                acc.Netsuite_Sync_Error__c = ('NetsuitePostAccountsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage()).left(255);
            	System.debug('NetsuitePostAccountsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        if(scope.size()>0) update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuitePostAccountsBatch');
        if(!Test.isRunningTest()){
            Database.executeBatch(new NetsuitePostLeadsBatch(startDate), 15);
        }
    }

}