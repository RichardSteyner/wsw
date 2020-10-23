global class NetsuitePostOpportunitiesBatch implements Database.Batchable<Opportunity>, Database.Stateful, Database.AllowsCallouts {
    
	public String startDate;
    public Map<String,Object> customSettingMap = new Map<String,Object>();
    
    global NetsuitePostOpportunitiesBatch(String startDate){
        this.startDate = startDate;
        
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
    }
    
    global List<Opportunity> start(Database.BatchableContext BC){
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities = [Select id, NS_ID__c, Name, Email__c, StageName, Balance__c, Web_Order_Number__c, 
                             				Order_Detail__c, Order__c, Warehouse_Notes__c, Art_file_by_email__c, 
                             				Discount_Total__c, Ship_Date__c, Ship_Method__c, Shipping_Cost__c, 
                             				Netsuite_Status__c, Subtotal__c, Tax_Total__c, Transaction_Date__c, 
                             				Document_Number__c, 
                                  			Netsuite_To_Sync__c, Netsuite_Sync_Status__c, Netsuite_Sync_Error__c 
                                		from Opportunity 
                                   		where Netsuite_To_Sync__c = true];
     
        return opportunities;
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        String xmlBody = '', errorCode = null, errorString = null, errorSuccess = null;
        String /*departmentXML = '',*/ shipMethodXML = '', shipDateXML='', tranDateXML='', orderDetailXML='', stageXML='', responseS='';
        HTTPResponse response;
        for(Opportunity opp : scope){
            try{
                //departmentXML = ApexUtil.getFieldSettingNetsuiteXML('order',customSettingMap,'<3> Operations : Research and Development', 'department', 'tran');
                shipMethodXML = ApexUtil.getFieldSettingNetsuiteXML('order',customSettingMap,opp.Ship_Method__c, 'shipMethod', 'tran');
                orderDetailXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('order',customSettingMap,opp.Order_Detail__c, 'custbody11', '70', '21');
                stageXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('order',customSettingMap,opp.StageName, 'custbody_orderstatus', '45', '18');
                if(opp.Ship_Date__c!=null){
                    shipDateXML = '<tran:shipDate>' + Datetime.newInstance(opp.Ship_Date__c.year(), opp.Ship_Date__c.month(), opp.Ship_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tran:shipDate>';
                }
                if(opp.Transaction_Date__c!=null){
                    tranDateXML = '<tran:tranDate>' + Datetime.newInstance(opp.Transaction_Date__c.year(), opp.Transaction_Date__c.month(), opp.Transaction_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tran:tranDate>';
                }
                
                xmlBody = '<update>' +
                            '	<platformMsgs:record internalId="' + opp.NS_ID__c + '" xsi:type="tran:SalesOrder" xmlns:tran="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                            '		<tran:email>' + opp.Email__c + '</tran:email>' +
                    		'		<tran:balance>' + opp.Balance__c + '</tran:balance>' +
                    		/*'		<tran:status>' + opp.Netsuite_Status__c + '</tran:status>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		tranDateXML +  
                    		/*'		<tran:tranId>' + opp.Document_Number__c + '</tran:tranId>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		/*departmentXML + */ //al parecer es readonly o sólo se puede setear al insertar
                    		/*shipMethodXML + */ //al parecer es readonly o sólo se puede setear al insertar
                    		/*'		<tran:shippingCost>' + opp.Shipping_Cost__c + '</tran:shippingCost>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		shipDateXML +
                    		/*'		<tran:discountTotal>' + (opp.Discount_Total__c!=null ? opp.Discount_Total__c : 0) + '</tran:discountTotal>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		/*'		<tran:subTotal>' + (opp.Subtotal__c!=null ? opp.Subtotal__c : 0) + '</tran:subTotal>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		/*'		<tran:taxTotal>' + (opp.Tax_Total__c!=null ? opp.Tax_Total__c : 0) + '</tran:taxTotal>' + */ //al parecer es readonly o sólo se puede setear al insertar
                    		'		<tran:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                    		'			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                            '				<platformCore:value>' + opp.Web_Order_Number__c + '</platformCore:value>' +
                        	'			</platformCore:customField>' +
                    		'			<platformCore:customField internalId="61" scriptId="custbody5" xsi:type="platformCore:StringCustomFieldRef">' +
                            '				<platformCore:value>' + opp.Order__c + '</platformCore:value>' +
                        	'			</platformCore:customField>' +
                    		'			<platformCore:customField internalId="64" scriptId="custbody8" xsi:type="platformCore:StringCustomFieldRef">' +
                            '				<platformCore:value>' + opp.Warehouse_Notes__c + '</platformCore:value>' +
                        	'			</platformCore:customField>' +
                    		'			<platformCore:customField internalId="2149" scriptId="custbody_artfile_by_email" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '				<platformCore:value>' + opp.Art_file_by_email__c + '</platformCore:value>' +
                        	'			</platformCore:customField>' +
                    		stageXML + 
                    		orderDetailXML +
                    		'		</tran:customFieldList>' + 
                            '	</platformMsgs:record>' +
                            '</update>';
                
                response = NetsuiteConnection.updateNetsuiteObjectSoap(xmlBody);
                responseS = response.getBody();
                if(String.isNotBlank(response.getBody())){
                    errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                    errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                    errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"')=='false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                }
                if(response.getStatusCode()==200 && errorCode==null && errorString==null && errorSuccess==null){
                    opp.Netsuite_To_Sync__c = false;
                    opp.Netsuite_Sync_Status__c = 'Synced';
                    opp.Netsuite_Sync_Error__c = '';
                } else {
                    opp.Netsuite_To_Sync__c = false;
                    opp.Netsuite_Sync_Status__c = 'Error';
                    if(errorSuccess!=null)
                        opp.Netsuite_Sync_Error__c = errorSuccess.left(255);
                    else
                    	opp.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                }
            }catch(Exception e){
                opp.Netsuite_To_Sync__c = false;
                opp.Netsuite_Sync_Status__c = 'Error';
                opp.Netsuite_Sync_Error__c = ('NetsuitePostOpportunitiesBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage()).left(255);
            	System.debug('NetsuitePostOpportunitiesBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isOpportunityTriggerInvoked = false;
        if(scope.size()>0) update scope;
        
                /*List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                Messaging.SingleEmailMessage mail = New Messaging.SingleEmailMessage();
                String[] toAddress =  new String[]{'rurupeque@cloudcreations.com'};
                mail.setToAddresses(toAddress);
                mail.setSubject('Hi');
                mail.setPlainTextBody(responseS);
                mails.add(mail);
                Messaging.sendEmail(mails);*/
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuitePostOpportunitiesBatch');
        if(!Test.isRunningTest()) Database.executeBatch(new NetsuiteGetSalesOrderBatch(startDate), 25);
    }

}