global class NetsuitePostLeadsBatch implements Database.Batchable<Lead>, Database.Stateful, Database.AllowsCallouts {
    
	public String startDate;
    public Map<String,Object> customSettingMap = new Map<String,Object>();
    
    global NetsuitePostLeadsBatch(String startDate){
        this.startDate = startDate;
        
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
    }
    
    global List<Lead> start(Database.BatchableContext BC){
        return [Select id, NS_ID__c, LastName, NumberOfEmployees, Taxable__c, Web_Approved_CB__c, Website, Phone, OZlink_Billing_shipping_to_recip__c, Ozlink_Website__c, OZlink_Bill_shipping_to_3rd__c, Industry, Type_of_Customer__c,
                CC_Processor__c, LeadSource, Price_Level__c, Netsuite_Status__c, Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                from Lead where Netsuite_To_Sync__c = true limit 30];
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope){
        String xmlBody = '', errorCode = null, errorString = null, errorSuccess = null;
        HTTPResponse response;
        String industryXML='', typeCustomerXML='', leadSourceXML='', prefCcProcessorXML='', priceLevelXML='', entityStatusXML='';
        for(Lead l : scope){
            try{
                leadSourceXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,l.LeadSource, 'leadSource', 'listRel');
                prefCcProcessorXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,l.CC_Processor__c, 'prefCCProcessor', 'listRel');
                priceLevelXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,l.Price_Level__c, 'priceLevel', 'listRel');
                entityStatusXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,l.Netsuite_Status__c, 'entityStatus', 'listRel');
                industryXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,l.Industry, 'custentity_esc_industry', '19', '2');
                typeCustomerXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,l.Type_of_Customer__c, 'custentity_typeofcustomer', '44', '-186');
                
                xmlBody = '<update>' +
                            '	<platformMsgs:record internalId="' + l.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' + 
                            '		<listRel:companyName>' + l.LastName + '</listRel:companyName>' +
                            '		<listRel:url>' + l.Website + '</listRel:url>' +
                    		'		<listRel:phone>' + l.Phone + '</listRel:phone>' +
                    		'		<listRel:taxable>' + l.Taxable__c + '</listRel:taxable>' +
                    		leadSourceXML + 
                    		prefCcProcessorXML + 
                    		priceLevelXML + 
                    		entityStatusXML + 
                    		'		<listRel:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                    		'			<platformCore:customField internalId="1187" scriptId="custentity_sc_web_approved" xsi:type="platformCore:BooleanCustomFieldRef">' + 
                        	'				<platformCore:value>' + l.Web_Approved_CB__c + '</platformCore:value>' +
                    		'			</platformCore:customField>' +
                    		'			<platformCore:customField internalId="18" scriptId="custentity_esc_no_of_employees" xsi:type="platformCore:LongCustomFieldRef">' + 
                            '               <platformCore:value>' + l.NumberOfEmployees + '</platformCore:value>' + 
                            '           </platformCore:customField>' + 
                    		'			<platformCore:customField internalId="84" scriptId="custentity_ozlink_bill_shipping_to_3rd" xsi:type="platformCore:BooleanCustomFieldRef">' + 
                            '           	<platformCore:value>' + l.OZlink_Bill_shipping_to_3rd__c + '</platformCore:value>' +
                            '        	</platformCore:customField>' + 
                            '        	<platformCore:customField internalId="83" scriptId="custentity_ozlink_bill_shipping_to_recip" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '            	<platformCore:value>' + l.OZlink_Billing_shipping_to_recip__c + '</platformCore:value>' +
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
                    l.Netsuite_To_Sync__c = false;
                    l.Netsuite_Sync_Status__c = 'Synced';
                    l.Netsuite_Sync_Error__c = '';
                } else {
                    l.Netsuite_To_Sync__c = false;
                    l.Netsuite_Sync_Status__c = 'Error';
                    if(errorSuccess!=null)
                        l.Netsuite_Sync_Error__c = errorSuccess.left(255);
                    else
                    	l.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                }
            }catch(Exception e){
                l.Netsuite_To_Sync__c = false;
                l.Netsuite_Sync_Status__c = 'Error';
                l.Netsuite_Sync_Error__c = ('NetsuitePostAccountsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage()).left(255);
            	System.debug('NetsuitePostLeadsBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isLeadTriggerInvoked = false;
        if(scope.size()>0) update scope;
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuitePostLeadsBatch');
        if(!Test.isRunningTest()){
            Database.executeBatch(new NetsuitePostContactsBatch(startDate), 15);
        }
    }

}