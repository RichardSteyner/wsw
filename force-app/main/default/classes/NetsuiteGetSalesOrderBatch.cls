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
        Map<String, Id> userIds = new Map<String, Id>();
        Map<String,NetsuiteOpp__c> customOppMap = new Map<String,NetsuiteOpp__c>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        Map<String,OpportunityLineItem> olisMap = new Map<String,OpportunityLineItem>();
    	for(String auxId : scope){
        	try{
                jsonResponse = NetsuiteConnection.getNetsuiteObject('salesOrder/' + auxId, '');
                if(jsonResponse!=null){
                    nsSales = (NetsuiteSalesOrderParser) json.deserialize(jsonResponse, NetsuiteSalesOrderParser.class);
                    System.debug('-----------SALES ORDER------------');
                    System.debug(auxId);
                    
                    objOpp = new Opportunity(NS_ID__c=auxId, Name=auxId, Balance__c=nsSales.balance, Web_Order_Number__c=nsSales.getWebOrderNumber(),
                                             Order__c=nsSales.custbody5, Warehouse_Notes__c=nsSales.getWarehouseNotes(), Art_file_by_email__c=nsSales.custbody_artfile_by_email,
                                             Email__c=nsSales.email, Discount_Total__c=nsSales.discountTotal, Customer_NS_ID__c=nsSales.getEntityId(),
                                             Ship_Date__c=nsSales.shipDate, Shipping_Cost__c=nsSales.shippingCost,
                                             Netsuite_Status__c=nsSales.status, Subtotal__c=nsSales.subtotal, Tax_Total__c=nsSales.taxTotal,
                                             Transaction_Date__c=nsSales.trandate, Document_Number__c=nsSales.tranId, CloseDate=nsSales.trandate,
                                             Graphics_Designer_NS_Id__c=nsSales.getCustbody3Id(), 
                                             Order_processed_By_NS_ID__c=nsSales.getCustbody9Id(), 
                                             Owner_NS_ID__c=nsSales.getSalesRepId());
                    objOpp.Order_Detail__c = (nsSales.getOrderDetail() != null ? nsSales.getOrderDetail().subStringAfter('> ') : null);
                    objOpp.StageName = (nsSales.getStage() != null ? nsSales.getStage().subStringAfter('> ') : null);
                    objOpp.Ship_Method__c = (nsSales.getShipMethod() != null ? nsSales.getShipMethod().subStringAfter('> ') : null);
                    objOpp.Total__c = nsSales.total;
                    if(nsSales.getOrderDetail() != null){
                        customOppMap.put(
                            'orderdetail-'+nsSales.getOrderDetail().subStringBetween('<','>').trim().toLowerCase(),
                            new NetsuiteOpp__c(Type__c = 'OrderDetail', Name = 'OrderDetail-'+nsSales.getOrderDetail().subStringBetween('<','>').trim().toLowerCase(), ID__c = nsSales.getOrderDetail().subStringBetween('<','>'),Value__c = nsSales.getOrderDetail().subStringAfter('> ').trim())
                        );
                    }
                    if(nsSales.getStage() != null){
                        customOppMap.put(
                            'stage-'+nsSales.getStage().subStringBetween('<','>').trim().toLowerCase(),
                            new NetsuiteOpp__c(Type__c = 'Stage', Name = 'stage-'+nsSales.getStage().subStringBetween('<','>').trim().toLowerCase(), ID__c = nsSales.getStage().subStringBetween('<','>'),Value__c = nsSales.getStage().subStringAfter('> ').trim())
                        );
                    }
                    if(nsSales.getShipMethod() != null){
                        customOppMap.put(
                            'shipmethod-'+nsSales.getShipMethod().subStringBetween('<','>').trim().toLowerCase(),
                            new NetsuiteOpp__c(Type__c = 'ShipMethod', Name = 'shipmethod-'+nsSales.getShipMethod().subStringBetween('<','>').trim().toLowerCase(), ID__c = nsSales.getShipMethod().subStringBetween('<','>'),Value__c = nsSales.getShipMethod().subStringAfter('> ').trim())
                        );
                    }
                    
                    opps.put(auxId, objOpp);
                    
                    if(nsSales.getEntityId()!=null){
                        objAccount = new Account(NS_ID__c=nsSales.getEntityId(), Name=nsSales.entity.refName);
                        auxAccountIds.add(nsSales.getEntityId());
                        accounts.put(nsSales.getEntityId(), objAccount);
                    }
                    if(nsSales.getCustbody3Id()!=null) userIds.put(nsSales.getCustbody3Id(), null);
                    if(nsSales.getCustbody9Id()!=null) userIds.put(nsSales.getCustbody9Id(), null);
                    if(nsSales.getSalesRepId()!=null) userIds.put(nsSales.getSalesRepId(), null);
                    
                    //OLIS
                    if(nsSales.item != null && nsSales.item.links != null){
                        for(NetsuiteSalesOrderParser.Link sLink : nsSales.item.links){
                            if(sLink.href != null){
                                jsonResponse = NetsuiteConnection.getNetsuiteObject(sLink.href.substringAfter('/v1/') , '');
                                if(jsonResponse!=null){
                                    nsRelatedList = (NetsuiteSalesOrderParser.RelatedList) json.deserialize(jsonResponse, NetsuiteSalesOrderParser.RelatedList.class);
                                    if(nsRelatedList.items != null){
                                        for(NetsuiteSalesOrderParser.ItemLink itemlink : nsRelatedList.items){
                                            if(itemlink.links != null){
                                                for(NetsuiteSalesOrderParser.Link linkDetail : itemlink.links){
                                                    if(linkDetail.href != null){
                                                        jsonResponse = NetsuiteConnection.getNetsuiteObject(linkDetail.href.substringAfter('/v1/') , '');
                                                        if(jsonResponse!=null){
                                                            nsItemDetail = (NetsuiteSalesOrderParser.ItemDetail) json.deserialize(jsonResponse, NetsuiteSalesOrderParser.ItemDetail.class);
                                                            if(nsItemDetail != null && nsItemDetail.item.id != null && nsItemDetail.item.refName != null && nsItemDetail.quantity != null && nsItemDetail.quantity != 0 && nsItemDetail.rate != null){
                                                                //Product2
                                                                productMap.put(nsItemDetail.item.id,new Product2(NS_ID__c = nsItemDetail.item.id, Name = nsItemDetail.item.refName, isActive = true));
                                                                //OpportunityLineItem
                                                                olisMap.put(nsItemDetail.id, new OpportunityLineItem(
                                                                    NS_ID__c = nsItemDetail.id,
                                                                    Opportunity = new Opportunity(NS_ID__c = objOpp.NS_ID__c),
                                                                    Quantity = nsItemDetail.quantity,
                                                                    UnitPrice = nsItemDetail.rate != null ? nsItemDetail.rate : 0,
                                                                    Item_ID__c = nsItemDetail.item.id,
                                                                    Quantity_Available__c = nsItemDetail.quantityAvailable,
                                                                    Brand__c = nsItemDetail.custcol_item_brand != null ? nsItemDetail.custcol_item_brand.refName : null
                                                                ));
                                                            }
                                                        }
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            break;
                        }
                    }
                }else
                    System.debug('NetsuiteGetSalesOrderBatch -> Response null or responseCode not 200.!');
           	}catch(Exception e){
            	System.debug('NetsuiteGetSalesOrderBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
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
           
        for(User u : [select Id, NS_ID__c from User where NS_ID__c in: userIds.keySet()]) userIds.put(u.NS_ID__c, u.Id);
                
		for(Opportunity o : opps.values()){
			if(o.Customer_NS_ID__c!=null)
            {
            	if(accounts.get(o.Customer_NS_ID__c)!=null && accounts.get(o.Customer_NS_ID__c).Id!=null) 
                	o.AccountId=accounts.get(o.Customer_NS_ID__c).Id;
                //else
                    //System.debug('Cannot relate to account: ' + o.Customer_NS_ID__c);
            }
            if(o.Graphics_Designer_NS_Id__c!=null){
                if(userIds.get(o.Graphics_Designer_NS_Id__c)!=null) 
                	o.Graphics_Designer__c=userIds.get(o.Graphics_Designer_NS_Id__c);
                //else
                    //System.debug('Cannot relate to Graphics Designer: ' + o.Graphics_Designer_NS_Id__c);
            }
            if(o.Order_processed_By_NS_ID__c!=null){
                if(userIds.get(o.Order_processed_By_NS_ID__c)!=null) 
                	o.Order_processed_By__c=userIds.get(o.Order_processed_By_NS_ID__c);
                //else
                    //System.debug('Cannot relate to Order Processed By: ' + o.Order_processed_By_NS_ID__c);
            }
            if(o.Owner_NS_ID__c!=null){
                if(userIds.get(o.Owner_NS_ID__c)!=null) 
                	o.OwnerId=userIds.get(o.Owner_NS_ID__c);
                //else
                    //System.debug('Cannot relate to Owner: ' + o.Owner_NS_ID__c);
            }
        }
        
		ApexUtil.isOpportunityTriggerInvoked = false;         
       	upsertResults = Database.upsert(opps.values(), Opportunity.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) 
                	System.debug('NetsuiteGetSalesOrderBatch - Opportunity Upsert Error: ' + upsertError.getMessage());
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
            List<OpportunityLineItem> olisData = [SELECT Id, NS_ID__c FROM OpportunityLineItem WHERE NS_ID__c IN: olisMap.keySet()];
            for(OpportunityLineItem oli : olisMap.values()){
                for(OpportunityLineItem o : olisData){
                    if(oli.NS_ID__c == o.NS_ID__c){
                        oli.Id = o.Id;
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
            upsert olisMap.values() NS_ID__c;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetSalesOrderBatch');
        if(!Test.isRunningTest()) Database.executeBatch(new NetsuiteGetCustomersBatch(startDate, auxAccountIds), 10);
    }
    
}