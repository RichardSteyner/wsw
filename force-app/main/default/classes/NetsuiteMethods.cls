public class NetsuiteMethods {
    
    @AuraEnabled
    public static String getEstimate(Id oppId){
        Opportunity oppRecord = [SELECT Id, NS_Estimate_ID__c FROM Opportunity WHERE Id =: oppId];
        Map<String,OpportunityLineItem> oliMap = new Map<String,OpportunityLineItem>();
        for(OpportunityLineItem oli : [SELECT Id, Product2.NS_ID__c, UnitPrice, Quantity, Description, NS_Price_Code__c FROM OpportunityLineItem WHERE OpportunityId =: oppRecord.Id]) oliMap.put(oli.Product2.NS_ID__c,oli);
        String xmlBody = '<get><baseRef internalId="' + oppRecord.NS_Estimate_ID__c + '" type="estimate" xsi:type="platformCore:RecordRef"/></get>';
        HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody);
        if(response != null && response.getStatusCode() == 200){
            String errorCode, errorString, errorSuccess;
            if(String.isNotBlank(response.getBody())){
                errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
            }
            if(errorCode == null && errorString == null && errorSuccess == null){
                OpportunityLineItem oliRecord;
                List<Dom.XmlNode> estimate = NetsuiteMethods.XmlParser(response.getBody());
                Map<String,Product2> productMap = new Map<String,Product2>();
                List<OpportunityLineItem> olisUpsert = new List<OpportunityLineItem>();
                for(Dom.XmlNode childElement1 : estimate){
                    if(childElement1.getName() == 'Body'){
                        for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                            for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                    if(childElement4.getName() == 'record'){
                                        for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                            if(childElement5.getName() == 'itemList'){
                                                for(Dom.XmlNode item : childElement5.getChildElements()){
                                                    oliRecord = new OpportunityLineItem(OpportunityId = oppRecord.Id);
                                                    for(Dom.XmlNode itemData : item.getChildElements()){
                                                        if(itemData.getName() == 'item'){
                                                            oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                            if(oliMap.get(itemData.getAttribute('internalId',null)) != null){
                                                                oliRecord.Id = oliMap.get(itemData.getAttribute('internalId',null)).Id;
                                                            }else{
                                                                for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                    if(itemDataDetail.getName() == 'name'){
                                                                        productMap.put(itemData.getAttribute('internalId',null),new Product2(Name = itemDataDetail.getText(),isActive = true,NS_ID__c = itemData.getAttribute('internalId',null)));
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if(itemData.getName() == 'quantity') oliRecord.Quantity = Decimal.valueOf(itemData.getText());
                                                        if(itemData.getName() == 'rate') oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                        if(itemData.getName() == 'price'){
                                                            oliRecord.NS_Price_Code__c = itemData.getAttribute('internalId',null);
                                                            for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                if(itemDataDetail.getName() == 'name'){
                                                                    oliRecord.Price_Level__c = itemDataDetail.getText();
                                                                }
                                                            }
                                                        }
                                                    }
                                                    olisUpsert.add(oliRecord);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if(!olisUpsert.isEmpty()){
                    Map<String,PricebookEntry> pbeMap = new Map<String,PricebookEntry>();
                    if(!productMap.isEmpty()){
                        for(PricebookEntry pbe : [SELECT Id, Product2.NS_ID__c, UnitPrice, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Product2.NS_ID__c IN: productMap.keySet()]){
                            pbeMap.put(pbe.Product2.NS_ID__c,pbe);
                            if(productMap.get(pbe.Product2.NS_ID__c) != null) productMap.remove(pbe.Product2.NS_ID__c);
                        }
                        insert productMap.values();
                        List<PricebookEntry> pbeList = new List<PricebookEntry>();
                        String pbeId;
                        if(!Test.isRunningTest()) pbeId = [Select Id From Pricebook2 WHERE isStandard=true and isActive=true].Id; else pbeId = Test.getStandardPricebookId();
                        for(Product2 product : productMap.values()){
                            pbeMap.put(product.NS_ID__c,new PricebookEntry(Product2Id = product.Id, Pricebook2Id = pbeId, isActive = true, UnitPrice = 0));
                        }
                        upsert pbeMap.values();
                    } 
                    
                    for(OpportunityLineItem oliu : olisUpsert){
                        if(oliu.Id == null && pbeMap.get(oliu.Item_ID__c) != null) oliu.PricebookEntryId = pbeMap.get(oliu.Item_ID__c).Id;
                    }
                    ApexUtil.isOpportunityTriggerInvoked = false;
                    upsert olisUpsert;
                }
            } else {
                if(errorSuccess != null) 
                    return errorSuccess; 
                else 
                    return errorCode + ': ' + errorString;
            }
        }
        return 'Ok';
    }
    
    @AuraEnabled
    public static String getCustomer(Id accId){
        Account accountRecord = [SELECT Id, NS_ID__c FROM Account WHERE Id =: accId];
        String jsonResponse = NetsuiteConnection.getNetsuiteObject('customer/' + accountRecord.NS_ID__c, '');
        system.debug(jsonResponse);
        if(jsonResponse!=null){
            Map<String,String> customSettingMap = new Map<String,String>();
            for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl.Value__c);
            
            Map<String,NetsuiteLead__c> customLeadMap = new Map<String,NetsuiteLead__c>();
            NetsuiteCustomerParser customer = (NetsuiteCustomerParser) json.deserialize(jsonResponse, NetsuiteCustomerParser.class);
            if(customer != null){
                accountRecord.Name=customer.companyName;
                accountRecord.NumberOfEmployees=customer.custentity_esc_no_of_employees;
                accountRecord.Taxable__c=customer.taxable;
                accountRecord.Web_Approved_CB__c=customer.custentity_sc_web_approved;
                accountRecord.Attention_Address__c=customer.defaultAddress;
                accountRecord.WS_Prime__c=customer.getWSPrime();
                accountRecord.Phone=customer.phone;
                accountRecord.Website=customer.url;
                accountRecord.Parent_NS_ID__c=customer.getParentId();
                accountRecord.OZlink_Bill_shipping_to_3rd__c=customer.custentity_ozlink_bill_shipping_to_3rd;
                accountRecord.OZlink_Billing_shipping_to_recip__c=customer.custentity_ozlink_bill_shipping_to_recip;
                accountRecord.Ozlink_Website__c=customer.custentity_ozlink_website;
                accountRecord.Owner_NS_ID__c=customer.getSalesRepId();
                accountRecord.AccountSource = (customer.getLeadSource() != null ? customer.getLeadSource().subStringAfter('> ') : null);
                accountRecord.CC_Processor__c = (customer.getCCProcessor() != null ? customer.getCCProcessor().subStringAfter('> ') : null);
                accountRecord.Price_Level__c = (customer.getPriceLevel() != null ? customer.getPriceLevel().subStringAfter('> ') : null);
                accountRecord.Netsuite_Status__c = (customer.geEntityStatus() != null ? customer.geEntityStatus().subStringAfter('> ') : null);
                accountRecord.Industry = (customer.getIndustry() != null ? customer.getIndustry().subStringAfter('> ') : null);
                accountRecord.Type_of_Customer__c = (customer.getTypeOfCustomer() != null ? customer.getTypeOfCustomer().subStringAfter('> ') : null);
                if(customer.getLeadSource() != null){
                    customLeadMap.put(
                        'leadsource-'+customer.getLeadSource().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'leadsource', Name = 'LeadSource-'+customer.getLeadSource().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getLeadSource().subStringBetween('<','>'),Value__c = customer.getLeadSource().subStringAfter('> ').trim())
                    );
                }
                if(customer.getCCProcessor() != null){
                    customLeadMap.put(
                        'ccprocessor-'+customer.getCCProcessor().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'CCProcessor', Name = 'ccprocessor-'+customer.getCCProcessor().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getCCProcessor().subStringBetween('<','>'),Value__c = customer.getCCProcessor().subStringAfter('> ').trim())
                    );
                }
                if(customer.getPriceLevel() != null){
                    customLeadMap.put(
                        'pricelevel-'+customer.getPriceLevel().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'PriceLevel', Name = 'pricelevel-'+customer.getPriceLevel().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getPriceLevel().subStringBetween('<','>'),Value__c = customer.getPriceLevel().subStringAfter('> ').trim())
                    );
                }
                if(customer.geEntityStatus() != null){
                    customLeadMap.put(
                        'entitystatus-'+customer.geEntityStatus().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'EntityStatus', Name = 'entitystatus-'+customer.geEntityStatus().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.geEntityStatus().subStringBetween('<','>'),Value__c = customer.geEntityStatus().subStringAfter('> ').trim())
                    );
                }
                if(customer.getIndustry() != null){
                    customLeadMap.put(
                        'industry-'+customer.getIndustry().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'Industry', Name = 'industry-'+customer.getIndustry().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getIndustry().subStringBetween('<','>'),Value__c = customer.getIndustry().subStringAfter('> ').trim())
                    );
                }
                if(customer.getTypeOfCustomer() != null){
                    customLeadMap.put(
                        'typeofcustomer-'+customer.getTypeOfCustomer().subStringBetween('<','>').trim().toLowerCase(),
                        new NetsuiteLead__c(Type__c = 'TypeOfCustomer', Name = 'typeofcustomer-'+customer.getTypeOfCustomer().subStringBetween('<','>').trim().toLowerCase(), ID__c = customer.getTypeOfCustomer().subStringBetween('<','>'),Value__c = customer.getTypeOfCustomer().subStringAfter('> ').trim())
                    );
                }
                
                //Custom Settings
                for(String key : customLeadMap.keySet()){
                    if(customSettingMap.get(key) != null) customLeadMap.remove(key); else customSettingMap.put(key,customLeadMap.get(key).Value__c);
                }
                if(!customLeadMap.isEmpty()) insert customLeadMap.values();
                
                ApexUtil.isAccountTriggerInvoked = false;
                update accountRecord;
            }
        }
        return 'Ok';
    }
    
    @future(callout=true)
    public static void createEstimate(Set<String> recordIds){
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        String orderDetail;
        String xmlBody;
        for(Opportunity oppRecord : [SELECT Id, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Estimate_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Email__c, (SELECT Id, Product2.NS_ID__c, Description, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    orderDetail = null;
                    for(NetsuiteOpp__c orderDetailValue : customSettingMap.get('orderdetail')) if(orderDetailValue.Value__c == oppRecord.Order_Detail__c) orderDetail = orderDetailValue.ID__c;
                    xmlBody = 
                        '<add>' +
                        '	<platformMsgs:record  xsi:type="tranSales:Estimate" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                        '		<tranSales:entity internalId="' + oppRecord.Account.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Estimate_Date__c != null ? '<tranSales:tranDate>' + Datetime.newInstance(oppRecord.Estimate_Date__c.year(), oppRecord.Estimate_Date__c.month(), oppRecord.Estimate_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:tranDate>' : '') + 
                        '		<tranSales:entityStatus internalId="10" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Estimate_Expiration_Date__c != null ? '<tranSales:dueDate>' + Datetime.newInstance(oppRecord.Estimate_Expiration_Date__c.year(), oppRecord.Estimate_Expiration_Date__c.month(), oppRecord.Estimate_Expiration_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:dueDate>' : '') +
                        //'		<tranSales:status>Proposal</tranSales:status>' + 
                        '		<tranSales:expectedCloseDate>' + Datetime.newInstance(oppRecord.CloseDate.year(), oppRecord.CloseDate.month(), oppRecord.CloseDate.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:expectedCloseDate>' + 
                        '		<tranSales:memo>' + oppRecord.Memo__c + '</tranSales:memo>' + 
                        '		<tranSales:email>' + oppRecord.Email__c + '</tranSales:email>' +
                        '		<tranSales:itemList>';
                    Integer i = 1;
                    for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                        xmlBody += 
                            '    		<tranSales:item>' +
                            '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '        		<tranSales:line>' + i + '</tranSales:line>' +
                            '        		<tranSales:expandItemGroup>false</tranSales:expandItemGroup>' +
                            '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                            '        		<tranSales:description>' + oli.Description + '</tranSales:description>' +
                            '        		<tranSales:price internalId="-1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '				<tranSales:amount>0</tranSales:amount>' +
                            '    		</tranSales:item>';
                    }
                    xmlBody += 
                        '		</tranSales:itemList>' +
                        '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                        '			<platformCore:customField internalId="70" scriptId="custbody11" xsi:type="platformCore:SelectCustomFieldRef">' +
                        '				<platformCore:value internalId="' + (orderDetail != null ? orderDetail : '') + '" typeId="21" />' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Web_Order_Number__c != null ? oppRecord.Web_Order_Number__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</add>';
                    
                    HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('add',xmlBody);
                    if(response != null && response.getStatusCode() == 200){
                        String errorCode, errorString, errorSuccess;
                        if(String.isNotBlank(response.getBody())){
                            errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                            errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                            errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                        }
                        if(errorCode == null && errorString == null && errorSuccess == null){
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Synced';
                            oppRecord.Netsuite_Sync_Error__c = '';
                            oppRecord.NS_Estimate_ID__c = response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="estimate"');
                            if(oppRecord.NS_Estimate_ID__c != null){
                                xmlBody = '<get><baseRef internalId="' + oppRecord.NS_Estimate_ID__c + '" type="estimate" xsi:type="platformCore:RecordRef"/></get>';
                                response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody);
                                if(response != null && response.getStatusCode() == 200){
                                    oppRecord.Estimate__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:tranId>','</tranSales:tranId>') : null;
                                    oppRecord.Estimate_Status__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:entityStatus','</tranSales:entityStatus>').subStringBetween('<platformCore:name>','</platformCore:name>') : null;
                                }
                            }
                        } else {
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                        }
                    }
                }else{
                    oppRecord.Netsuite_To_Sync__c = false;
                    oppRecord.Netsuite_Sync_Status__c = 'Warning';
                    oppRecord.Netsuite_Sync_Error__c = 'Missing product items.';
                }
            }else{
                oppRecord.Netsuite_To_Sync__c = false;
                oppRecord.Netsuite_Sync_Status__c = 'Warning';
                oppRecord.Netsuite_Sync_Error__c = 'Customer not found.';
            }
            opportunityList.add(oppRecord);
        }
        ApexUtil.isOpportunityTriggerInvoked = false;
        if(!opportunityList.isEmpty()) update opportunityList;
    }
    
    @future(callout=true)
    public static void updateEstimate(Set<String> recordIds){
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        String orderDetail;
        String xmlBody;
        for(Opportunity oppRecord : [SELECT Id, NS_Estimate_ID__c, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Estimate_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Email__c, (SELECT Id, Product2.NS_ID__c, Description, Quantity FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    orderDetail = null;
                    for(NetsuiteOpp__c orderDetailValue : customSettingMap.get('orderdetail')) if(orderDetailValue.Value__c == oppRecord.Order_Detail__c) orderDetail = orderDetailValue.ID__c;
                    xmlBody = 
                        '<update>' +
                        '	<platformMsgs:record internalId="' + oppRecord.NS_Estimate_ID__c + '"  xsi:type="tranSales:Estimate" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                        '		<tranSales:entity internalId="' + oppRecord.Account.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Estimate_Date__c != null ? '<tranSales:tranDate>' + Datetime.newInstance(oppRecord.Estimate_Date__c.year(), oppRecord.Estimate_Date__c.month(), oppRecord.Estimate_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:tranDate>' : '') + 
                        '		<tranSales:entityStatus internalId="22" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Estimate_Expiration_Date__c != null ? '<tranSales:dueDate>' + Datetime.newInstance(oppRecord.Estimate_Expiration_Date__c.year(), oppRecord.Estimate_Expiration_Date__c.month(), oppRecord.Estimate_Expiration_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:dueDate>' : '') +
                        '		<tranSales:expectedCloseDate>' + Datetime.newInstance(oppRecord.CloseDate.year(), oppRecord.CloseDate.month(), oppRecord.CloseDate.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:expectedCloseDate>' + 
                        '		<tranSales:memo>' + oppRecord.Memo__c + '</tranSales:memo>' + 
                        '		<tranSales:email>' + oppRecord.Email__c + '</tranSales:email>' +
                        '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                        '			<platformCore:customField internalId="70" scriptId="custbody11" xsi:type="platformCore:SelectCustomFieldRef">' +
                        '				<platformCore:value internalId="' + (orderDetail != null ? orderDetail : '') + '" typeId="21" />' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Web_Order_Number__c != null ? oppRecord.Web_Order_Number__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</update>';
                    
                    HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('update',xmlBody);
                    if(response != null && response.getStatusCode() == 200){
                        String errorCode, errorString, errorSuccess;
                        if(String.isNotBlank(response.getBody())){
                            errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                            errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                            errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                        }
                        if(errorCode == null && errorString == null && errorSuccess == null){
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Synced';
                            oppRecord.Netsuite_Sync_Error__c = '';
                        } else {
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                        }
                    }
                }else{
                    oppRecord.Netsuite_To_Sync__c = false;
                    oppRecord.Netsuite_Sync_Status__c = 'Warning';
                    oppRecord.Netsuite_Sync_Error__c = 'Missing product items.';
                }
            }else{
                oppRecord.Netsuite_To_Sync__c = false;
                oppRecord.Netsuite_Sync_Status__c = 'Warning';
                oppRecord.Netsuite_Sync_Error__c = 'Customer not found.';
            }
            opportunityList.add(oppRecord);
        }
        ApexUtil.isOpportunityTriggerInvoked = false;
        if(!opportunityList.isEmpty()) update opportunityList;
    }
    
    @future(callout=true)
    public static void convertSale(Set<String> recordIds){
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        String orderDetail;
        String xmlBody;
        for(Opportunity oppRecord : [SELECT Id, NS_Estimate_ID__c, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Transaction_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Email__c, (SELECT Id, Product2.NS_ID__c, Description, Quantity, NS_Price_Code__c, UnitPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    xmlBody = 
                        '<add>' +
                        '	<platformMsgs:record xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                        '		<tranSales:entity internalId="' + oppRecord.Account.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Transaction_Date__c != null ? '<tranSales:tranDate>' + Datetime.newInstance(oppRecord.Transaction_Date__c.year(), oppRecord.Transaction_Date__c.month(), oppRecord.Transaction_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:tranDate>' : '') + 
                        '		<tranSales:status>Pending Approval</tranSales:status>' + 
                        '		<tranSales:email>' + oppRecord.Email__c + '</tranSales:email>' +
                        '		<tranSales:createdFrom internalId="' + oppRecord.NS_Estimate_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                        '		<tranSales:itemList>';
                    Integer i = 1;
                    for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                        xmlBody += 
                            '    		<tranSales:item>' +
                            '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '        		<tranSales:line>' + i + '</tranSales:line>' +
                            '        		<tranSales:expandItemGroup>false</tranSales:expandItemGroup>' +
                            '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                            '        		<tranSales:description>' + oli.Description + '</tranSales:description>' +
                            '        		<tranSales:price internalId="' + oli.NS_Price_Code__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            //'				<tranSales:amount>0</tranSales:amount>' +
                            '    		</tranSales:item>';
                    }
                    xmlBody += 
                        '		</tranSales:itemList>' +
                        '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                        '			<platformCore:customField internalId="70" scriptId="custbody11" xsi:type="platformCore:SelectCustomFieldRef">' +
                        '				<platformCore:value internalId="' + (orderDetail != null ? orderDetail : '') + '" typeId="21" />' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Web_Order_Number__c != null ? oppRecord.Web_Order_Number__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</add>';
                    
                    HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('add',xmlBody);
                    if(response != null && response.getStatusCode() == 200){
                        String errorCode, errorString, errorSuccess;
                        if(String.isNotBlank(response.getBody())){
                            errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                            errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                            errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                        }
                        if(errorCode == null && errorString == null && errorSuccess == null){
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Synced';
                            oppRecord.Netsuite_Sync_Error__c = '';
                            oppRecord.NS_ID__c = response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="salesOrder"');
                            if(oppRecord.NS_ID__c != null){
                                xmlBody = '<get><baseRef internalId="' + oppRecord.NS_ID__c + '" type="salesOrder" xsi:type="platformCore:RecordRef"/></get>';
                                response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody);
                                if(response != null && response.getStatusCode() == 200){
                                    oppRecord.Order__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:tranId>','</tranSales:tranId>') : null;
                                    /*oppRecord.Shipping_Cost__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? Decimal.valueOf(response.getBody().subStringBetween('<tranSales:shippingCost>','</tranSales:shippingCost>')) : null;
                                    oppRecord.Discount_Total__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? Decimal.valueOf(response.getBody().subStringBetween('<tranSales:discountTotal>','</tranSales:discountTotal>')) : null;
                                    oppRecord.Tax_Total__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? Decimal.valueOf(response.getBody().subStringBetween('<tranSales:taxTotal>','</tranSales:taxTotal>')) : null;
                                    oppRecord.Subtotal__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? Decimal.valueOf(response.getBody().subStringBetween('<tranSales:subTotal>','</tranSales:subTotal>')) : null;
                                    oppRecord.Total__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? Decimal.valueOf(response.getBody().subStringBetween('<tranSales:total>','</tranSales:total>')) : null;
                                    oppRecord.Ship_Method__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:shipMethod','</tranSales:shipMethod>').subStringBetween('<platformCore:name>','</platformCore:name>') : null;
                                	*/
								}
                            }
                        } else {
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                        }
                    }
                }else{
                    oppRecord.Netsuite_To_Sync__c = false;
                    oppRecord.Netsuite_Sync_Status__c = 'Warning';
                    oppRecord.Netsuite_Sync_Error__c = 'Missing product items.';
                }
            }else{
                oppRecord.Netsuite_To_Sync__c = false;
                oppRecord.Netsuite_Sync_Status__c = 'Warning';
                oppRecord.Netsuite_Sync_Error__c = 'Customer not found.';
            }
            opportunityList.add(oppRecord);
        }
        ApexUtil.isOpportunityTriggerInvoked = false;
        if(!opportunityList.isEmpty()) update opportunityList;
    }
    
    @future(callout=true)
	public static void createCustomer(Set<String> recordIds){
        Map<String,Object> customSettingMap = new Map<String,Object>();
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
        
        List<Account> accountList = new List<Account>();
        //String orderDetail;
        String xmlBody;
        HTTPResponse response;
        String prefCcProcessorXML, entityStatusXML, typeCustomerXML, errorCode, errorString, errorSuccess;
        for(Account accountRecord : [SELECT Id, Name, CC_Processor__c, Netsuite_Status__c, Type_of_Customer__c FROM Account WHERE Id IN: recordIds]){
            prefCcProcessorXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.CC_Processor__c, 'prefCCProcessor', 'listRel');
            entityStatusXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Netsuite_Status__c, 'entityStatus', 'listRel');
            typeCustomerXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Type_of_Customer__c, 'custentity_typeofcustomer', '44', '-186');
            xmlBody = 
                '<add>' +
                '	<platformMsgs:record xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' +
                '		<listRel:companyName>' + accountRecord.Name + '</listRel:companyName>' +
                prefCcProcessorXML +
                entityStatusXML +
                '		<listRel:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                typeCustomerXML + 
                '		</listRel:customFieldList>' + 
                '	</platformMsgs:record>' +
                '</add>';
            
            response = NetsuiteConnection.postNetsuiteSoap('add',xmlBody);
            errorCode = null;
            errorString = null;
            errorSuccess = null;
            system.debug(response.getBody());
            if(String.isNotBlank(response.getBody())){
                errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"')=='false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
            }
            if(response.getStatusCode()==200 && errorCode==null && errorString==null && errorSuccess==null){
                accountRecord.Netsuite_To_Sync__c = false;
                accountRecord.Netsuite_Sync_Status__c = 'Synced';
                accountRecord.Netsuite_Sync_Error__c = '';
                accountRecord.NS_ID__c = response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="customer"');
            } else {
                accountRecord.Netsuite_To_Sync__c = false;
                accountRecord.Netsuite_Sync_Status__c = 'Error';
                if(errorSuccess!=null)
                    accountRecord.Netsuite_Sync_Error__c = errorSuccess.left(255);
                else
                    accountRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
            }
            accountList.add(accountRecord);
        }
        ApexUtil.isAccountTriggerInvoked = false;
        if(!accountList.isEmpty()) update accountList;
    }
    
    public static List<Dom.XmlNode> XmlParser(String strXml) {
        List<Dom.XmlNode> childlist = new List<Dom.XmlNode>();
        Dom.Document doc = new Dom.Document();
        Integer childElementCount =0;
        doc.load(strXml);
        Dom.XMLNode rootElement = doc.getRootElement();
        String rootElementName = rootElement.getName();
        for(Dom.XmlNode childelement : rootElement.getChildElements()){
            childlist.add(childelement);
            childElementCount++;
        }
        return childlist;
    }
}