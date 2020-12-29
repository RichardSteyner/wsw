global class NetsuiteGetSalesOrderBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

    public String startDate;   
    public Set<String> auxAccountIds;
    public Map<String,String> customSettingMap = new Map<String,String>();
    
    global NetsuiteGetSalesOrderBatch(String startDate){
        this.startDate = startDate;
        auxAccountIds = new Set<String>();
        
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl.Value__c);
    }
    
    global List<String> start(Database.BatchableContext BC){
        List<String> nsIds = new List<String>(); 
        try{
            NetsuiteGetIds getSales = new NetsuiteGetIds('salesorder');
			List<String> auxList = getSales.getUpdatedIds(startDate);
            nsIds.addAll(auxList);
        }catch(Exception e){
            System.debug('NetsuiteGetSalesOrderBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteSalesOrderParser nsSales;
        NetsuiteSalesOrderParser.RelatedList nsRelatedList;
        NetsuiteSalesOrderParser.ItemDetail nsItemDetail;
        String jsonResponse;
        Opportunity objOpp;
        Account objAccount;
        Map<String, Opportunity> opps = new Map<String, Opportunity>();
        Map<String, Account> accounts = new Map<String, Account>();
        Map<String,NetsuiteOpp__c> customOppMap = new Map<String,NetsuiteOpp__c>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        Map<String,OpportunityLineItem> olisMap = new Map<String,OpportunityLineItem>();
        String xmlBody, errorCode, errorString, errorSuccess;
        HTTPResponse response;
        Opportunity oppRecord;
        OpportunityLineItem oliRecord;
        for(String auxId : scope){
            //jsonResponse = NetsuiteConnection.getNetsuiteObject('salesOrder/' + auxId, '');
            xmlBody = '<get><baseRef internalId="' + auxId + '" type="salesOrder" xsi:type="platformCore:RecordRef"/></get>';
            response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
            if(response != null && response.getStatusCode() == 200){
                if(String.isNotBlank(response.getBody())){
                    errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                    errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                    errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                }
                if(errorCode == null && errorString == null && errorSuccess == null){
                    List<Dom.XmlNode> salesXML = NetsuiteMethods.XmlParser(response.getBody());
                    for(Dom.XmlNode childElement1 : salesXML){
                        if(childElement1.getName() == 'Body'){
                            for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                    for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                        if(childElement4.getName() == 'record'){
                                            oppRecord = new Opportunity(NS_ID__c = auxId);
                                            oppRecord.PO__c = null;
                                            oppRecord.Memo__c = null;
                                            oppRecord.Ship_Date__c = null;
                                            oppRecord.Partner__c = null;
                                            oppRecord.Tracking__c = null;
                                            oppRecord.Ship_Method__c = null;
                                            oppRecord.In_Han_Date__c = null;
                                            oppRecord.Blind_Ship__c = null;
                                            oppRecord.Order_Detail__c = null;
                                            oppRecord.Ozlink__c = null;
                                            for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                if(childElement5.getName() == 'tranId') oppRecord.Name = childElement5.getText();
                                                if(childElement5.getName() == 'tranDate') oppRecord.CloseDate = Date.valueOf(childElement5.getText().split('T')[0]);
                                                if(childElement5.getName() == 'entity'){
                                                    objAccount = new Account(NS_ID__c = childElement5.getAttribute('internalId',null));
                                                    oppRecord.Customer_NS_ID__c = objAccount.NS_ID__c;
                                                    auxAccountIds.add(childElement5.getAttribute('internalId',null));
                                                    for(Dom.XmlNode childElement6 : childElement5.getChildElements()){
                                                        if(childElement6.getName() == 'name'){
                                                            objAccount.Name = childElement6.getText();
                                                            accounts.put(objAccount.NS_ID__c, objAccount);
                                                        }
                                                    }
                                                }
                                                if(childElement5.getName() == 'partner'){
                                                    for(Dom.XmlNode childElement6 : childElement5.getChildElements()){
                                                        if(childElement6.getName() == 'name'){
                                                            oppRecord.Partner__c = childElement6.getText();
                                                            customOppMap.put(
                                                                'partner-'+childElement5.getAttribute('internalId',null),
                                                                new NetsuiteOpp__c(Type__c = 'Partner', Name = 'partner-'+childElement5.getAttribute('internalId',null), ID__c = childElement5.getAttribute('internalId',null),Value__c = childElement6.getText())
                                                            );
                                                        }
                                                    }
                                                }
                                                if(childElement5.getName() == 'otherRefNum') oppRecord.PO__c = childElement5.getText();
                                                if(childElement5.getName() == 'endDate') oppRecord.In_Han_Date__c = childElement5.getText() != null ? Date.valueOf(childElement5.getText().split('T')[0]) : null;
                                                if(childElement5.getName() == 'shipAddressList') oppRecord.Shipping_Address_Code__c = childElement5.getAttribute('internalId',null);
                                                if(childElement5.getName() == 'memo') oppRecord.Memo__c = childElement5.getText();
                                                if(childElement5.getName() == 'shipDate') oppRecord.Ship_Date__c = childElement5.getText() != null ? Date.valueOf(childElement5.getText().split('T')[0]) : null;
                                                if(childElement5.getName() == 'shippingCost') oppRecord.Shipping_Cost__c = childElement5.getText() != null ? Decimal.valueOf(childElement5.getText()) : null;
                                                if(childElement5.getName() == 'linkedTrackingNumbers') oppRecord.Tracking__c = childElement5.getText();
                                                if(childElement5.getName() == 'shipMethod'){
                                                    for(Dom.XmlNode customField : childElement5.getChildElements()){
                                                        if(customField.getName() == 'name') oppRecord.Ship_Method__c = customField.getText();
                                                    }
                                                }
                                                if(childElement5.getName() == 'subTotal') oppRecord.Subtotal__c = Decimal.valueOf(childElement5.getText());
                                                if(childElement5.getName() == 'discountTotal') oppRecord.Discount_Total__c = Decimal.valueOf(childElement5.getText());
                                                if(childElement5.getName() == 'taxTotal') oppRecord.Tax_Total__c = Decimal.valueOf(childElement5.getText());
                                                if(childElement5.getName() == 'total') oppRecord.Total__c = Decimal.valueOf(childElement5.getText());
                                                if(childElement5.getName() == 'customFieldList'){
                                                    for(Dom.XmlNode customField : childElement5.getChildElements()){
                                                        if(customField.getAttribute('internalId',null) == '64' && customField.getAttribute('scriptId',null) == 'custbody8'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Warehouse_Notes__c = customFieldValue.getText();
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '4552' && customField.getAttribute('scriptId',null) == 'custbody93'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Customer_Service_Note__c = customFieldValue.getText();
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '6720' && customField.getAttribute('scriptId',null) == 'custbody107'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Did_I_Offer_A_Free_Sample__c = Boolean.valueOf(customFieldValue.getText());
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '4580' && customField.getAttribute('scriptId',null) == 'custbody_proofsheetfinishing'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Proofsheet_Finishing_Notes__c = customFieldValue.getText();
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '2149' && customField.getAttribute('scriptId',null) == 'custbody_artfile_by_email'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Art_file_by_email__c = Boolean.valueOf(customFieldValue.getText());
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '5922' && customField.getAttribute('scriptId',null) == 'custbody_art_file_exemption'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Use_Art_Files_from_other_orders__c = Boolean.valueOf(customFieldValue.getText());
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '66' && customField.getAttribute('scriptId',null) == 'custbody10'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Web_Order_Number__c = customFieldValue.getText();
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '76' && customField.getAttribute('scriptId',null) == 'custbody13'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Blind_Ship__c = Boolean.valueOf(customFieldValue.getText());
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '116' && customField.getAttribute('scriptId',null) == 'custbody17'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value') oppRecord.Ozlink__c = Boolean.valueOf(customFieldValue.getText());
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '70' && customField.getAttribute('scriptId',null) == 'custbody11'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value'){
                                                                    for(Dom.XmlNode customFieldName : customFieldValue.getChildElements()){
                                                                        if(customFieldName.getName() == 'name'){
                                                                            oppRecord.Order_Detail__c = customFieldName.getText();
                                                                            customOppMap.put(
                                                                                'orderdetail-'+customFieldValue.getAttribute('internalId',null),
                                                                                new NetsuiteOpp__c(Type__c = 'OrderDetail', Name = 'OrderDetail-'+customFieldValue.getAttribute('internalId',null), ID__c = customFieldValue.getAttribute('internalId',null),Value__c = customFieldName.getText())
                                                                            );
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        if(customField.getAttribute('internalId',null) == '45' && customField.getAttribute('scriptId',null) == 'custbody_orderstatus'){
                                                            for(Dom.XmlNode customFieldValue : customField.getChildElements()){
                                                                if(customFieldValue.getName() == 'value'){
                                                                    for(Dom.XmlNode customFieldName : customFieldValue.getChildElements()){
                                                                        if(customFieldName.getName() == 'name'){
                                                                            oppRecord.StageName = customFieldName.getText();
                                                                            customOppMap.put(
                                                                                'stage-'+customFieldValue.getAttribute('internalId',null),
                                                                                new NetsuiteOpp__c(Type__c = 'Stage', Name = 'stage-'+customFieldValue.getAttribute('internalId',null), ID__c = customFieldValue.getAttribute('internalId',null),Value__c = customFieldName.getText())
                                                                            );
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if(childElement5.getName() == 'itemList'){
                                                    for(Dom.XmlNode item : childElement5.getChildElements()){
                                                        oliRecord = new OpportunityLineItem(Opportunity = new Opportunity(NS_ID__c = auxId));
                                                        oliRecord.Sales_ID__c = auxId;
                                                        for(Dom.XmlNode itemData : item.getChildElements()){
                                                            if(itemData.getName() == 'item'){
                                                                oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                                for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                    if(itemDataDetail.getName() == 'name'){
                                                                        productMap.put(itemData.getAttribute('internalId',null),new Product2(Name = itemDataDetail.getText(),isActive = true,NS_ID__c = itemData.getAttribute('internalId',null)));
                                                                    }
                                                                }
                                                            }
                                                            if(itemData.getName() == 'lineUniqueKey') oliRecord.NS_ID__c = itemData.getText();
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
                                                        olisMap.put(oliRecord.NS_ID__c,oliRecord);
                                                    }
                                                }
                                            }
                                            opps.put(auxId,oppRecord);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //Custom Settings
        for(String key : customOppMap.keySet()){
            if(customSettingMap.get(key) != null) customOppMap.remove(key); else customSettingMap.put(key,customOppMap.get(key).Value__c);
        }
        if(!customOppMap.isEmpty()) insert customOppMap.values();
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.UpsertResult> upsertResults;
        upsertResults = Database.upsert(accounts.values(), Account.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) 
                    System.debug('NetsuiteGetSalesOrderBatch - Account Upsert Error: ' + upsertError.getMessage());
            }
        }
        
		for(Opportunity o : opps.values()){
			if(o.Customer_NS_ID__c!=null){
            	if(accounts.get(o.Customer_NS_ID__c)!=null && accounts.get(o.Customer_NS_ID__c).Id!=null) o.AccountId=accounts.get(o.Customer_NS_ID__c).Id;
            }
        }
        
		ApexUtil.isOpportunityTriggerInvoked = false;         
       	upsertResults = Database.upsert(opps.values(), Opportunity.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetSalesOrderBatch - Opportunity Upsert Error: ' + upsertError.getMessage());
            }
     	}
        
        //OpportunityLineItem
        List<PricebookEntry> pbes = [SELECT Id, Product2.NS_ID__c FROM PricebookEntry WHERE Product2.NS_ID__c IN: productMap.keySet()];
        if(productMap.size() != 0){
            upsert productMap.values() NS_ID__c;
            
            Set<ID> involvedProducts = new Set<ID>();
            for(Product2 prod : productMap.values()) involvedProducts.add(prod.Id);

            List<PricebookEntry> existingPBE = new List<PricebookEntry>();
            existingPBE = [SELECT Id, Product2Id FROM PricebookEntry WHERE Product2Id IN: involvedProducts];
            Map<Id,Id> checkPBE = new Map<Id,Id>();
            for(pricebookentry pbex : existingPBE){
                checkPBE.put(pbex.Product2Id,pbex.Id);
            }        
            
            String pbeId;
            if(!Test.isRunningTest()) pbeId = [Select Id From Pricebook2 WHERE isStandard=true and isActive=true].Id; else pbeId = Test.getStandardPricebookId();
            
            List<PricebookEntry> pentry=new List<PricebookEntry>();
            PricebookEntry pbe;
            for(Product2 prod : productMap.values()){
                pbe = new PricebookEntry();
                if(checkPBE.get(prod.id)==null){
                    pbe.Product2Id = prod.Id;
                    pbe.Pricebook2Id = pbeId;
                    pbe.IsActive = true;
                    pbe.UnitPrice = 0;
                    pentry.add(pbe);
                }else{
                    pbe.Id = checkPBE.get(prod.id);
                    pbe.UnitPrice = 0;
                    pentry.add(pbe);
                }        
            }
            upsert pentry;
            
            pbes = [SELECT Id, Product2.NS_ID__c FROM PricebookEntry WHERE Product2.NS_ID__c IN: productMap.keySet()];
        }
        
        if(!olisMap.isEmpty()){
            Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
            Set<String> productsExceptions = new Set<String>();
            for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
            
            List<OpportunityLineItem> olisData = [SELECT Id, Opportunity.NS_ID__c, NS_ID__c, Item_ID__c, UnitPrice FROM OpportunityLineItem WHERE NS_ID__c IN: olisMap.keySet()];
            for(OpportunityLineItem oli : olisMap.values()){
                for(OpportunityLineItem o : olisData){
                    if(oli.Item_ID__c == o.Item_ID__c && o.Opportunity.NS_ID__c == oli.Sales_ID__c){
                        oli.Id = o.Id;
                        if(productsExceptions.contains(o.Item_ID__c)) oli.UnitPrice = o.UnitPrice;
                    }
                }
                if(oli.Id == null){
                    for(PricebookEntry pbe : pbes){
                        if(oli.Item_ID__c == pbe.Product2.NS_ID__c){
                            oli.PricebookEntryId = pbe.Id;
                        }
                    }
                }
            }
            upsertResults = Database.upsert(olisMap.values(), OpportunityLineItem.Id, false);
            for(Database.UpsertResult upsertResult:upsertResults){
                if(!upsertResult.isSuccess()) {
                    for(Database.Error upsertError : upsertResult.getErrors()) System.debug('NetsuiteGetSalesOrderBatch - OpportunityLineItem Upsert Error: ' + upsertError.getMessage());
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetSalesOrderBatch');
        if(!Test.isRunningTest()) Database.executeBatch(new NetsuiteGetCustomersBatch(startDate, auxAccountIds), 1);
    }
    
}