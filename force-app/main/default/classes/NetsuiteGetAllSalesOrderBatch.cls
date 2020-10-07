global class NetsuiteGetAllSalesOrderBatch implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {

	public Integer size;
	public Integer offset;
	public Boolean hasMore;    
    
    global NetsuiteGetAllSalesOrderBatch(Integer size, Integer offset){
        this.size = size;
        this.offset = offset;
        hasMore = true;
    }
    
    global List<String> start(Database.BatchableContext BC){
        List<String> nsIds = new List<String>(); 
        try{
           	Date auxFecha = Date.valueOf('2020-08-19');
            String filtroFecha = 'lastModifiedDate%20AFTER%20"' + auxFecha.month() + '/' + auxFecha.day() + '/' + auxFecha.year() + '"';
            NetsuiteListParser listSales = (NetsuiteListParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('salesOrder', 'limit=' + size + '&offset=' + offset + '&q=' + filtroFecha), NetsuiteListParser.class);
            hasMore = listSales.hasMore;
            for(NetsuiteListParser.Item auxItem : listSales.items){
            	nsIds.add(auxItem.id);
            }
            offset = offset + size;
        }catch(Exception e){
            hasMore = false;
            System.debug('NetsuiteGetAllSalesOrderBatch Error Start: ' + e.getLineNumber() + '--' + e.getMessage());
        }
        return nsIds;
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope){
        NetsuiteSalesOrderParser nsSales;
        Opportunity objOpp;
        Account objAccount;
        Map<String, Opportunity> opps = new Map<String, Opportunity>();
        Map<String, Account> accounts = new Map<String, Account>();
        Map<String, Id> userIds = new Map<String, Id>();
    	for(String auxId : scope){
            System.debug(auxId);
        	try{
                nsSales = (NetsuiteSalesOrderParser) json.deserialize(NetsuiteConnection.getNetsuiteObject('salesOrder/' + auxId, ''), NetsuiteSalesOrderParser.class);
                System.debug('-----------SALES ORDER------------');
                System.debug(nsSales.trandate);
                System.debug('-----------SALES ORDER------------');
                
                objOpp = new Opportunity(NS_ID__c=auxId, Name=auxId, Balance__c=nsSales.balance, Web_Order_Number__c=nsSales.getWebOrderNumber(),
                                         Order_Detail__c=nsSales.getOrderDetail(), Order__c=nsSales.custbody5, Warehouse_Notes__c=nsSales.getWarehouseNotes(),
                                         Art_file_by_email__c=nsSales.custbody_artfile_by_email, StageName=nsSales.getStage(),
                                         Email__c=nsSales.email, Discount_Total__c=nsSales.discountTotal, Customer_NS_ID__c=nsSales.getEntityId(),
                                         Ship_Date__c=nsSales.shipDate, Ship_Method__c=nsSales.getShipMethod(), Shipping_Cost__c=nsSales.shippingCost,
                                         Netsuite_Status__c=nsSales.status, Subtotal__c=nsSales.subtotal, Tax_Total__c=nsSales.taxTotal,
                                         Transaction_Date__c=nsSales.trandate, Document_Number__c=nsSales.tranId, CloseDate=nsSales.trandate,
                                         Graphics_Designer_NS_Id__c=nsSales.getCustbody3Id(), 
                                         Order_processed_By_NS_ID__c=nsSales.getCustbody9Id(), 
                                         Owner_NS_ID__c=nsSales.getSalesRepId());
                opps.put(auxId, objOpp);
                
                if(nsSales.getEntityId()!=null){
                    objAccount = new Account(NS_ID__c=nsSales.getEntityId(), Name=nsSales.entity.refName);
                    accounts.put(nsSales.getEntityId(), objAccount);
                }
                if(nsSales.getCustbody3Id()!=null){
                    userIds.put(nsSales.getCustbody3Id(), null);
                }
                if(nsSales.getCustbody9Id()!=null){
                    userIds.put(nsSales.getCustbody9Id(), null);
                }
                if(nsSales.getSalesRepId()!=null){
                    userIds.put(nsSales.getSalesRepId(), null);
                }
           	}catch(Exception e){
            	System.debug('NetsuiteGetAllSalesOrderBatch Error Execute: ' + e.getLineNumber() + '--' + e.getMessage());
        	}
        }
        
        ApexUtil.isAccountTriggerInvoked = false;
        List<Database.UpsertResult> upsertResults;
        upsertResults = Database.upsert(accounts.values(), Account.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults) {
            if(!upsertResult.isSuccess()) {
                for(Database.Error upsertError : upsertResult.getErrors()) 
                    System.debug('NetsuiteGetAllSalesOrderBatch - Account Upsert Error: ' + upsertError.getMessage());
            }
        }
           
        for(User u : [select Id, NS_ID__c from User where NS_ID__c in: userIds.keySet()])
            userIds.put(u.NS_ID__c, u.Id);
                
		for(Opportunity o : opps.values()){
			if(o.Customer_NS_ID__c!=null)
            {
            	if(accounts.get(o.Customer_NS_ID__c)!=null && accounts.get(o.Customer_NS_ID__c).Id!=null) 
                	o.AccountId=accounts.get(o.Customer_NS_ID__c).Id;
                else
                    System.debug('Cannot relate to account: ' + o.Customer_NS_ID__c);
            }
            if(o.Graphics_Designer_NS_Id__c!=null){
                if(userIds.get(o.Graphics_Designer_NS_Id__c)!=null) 
                	o.Graphics_Designer__c=userIds.get(o.Graphics_Designer_NS_Id__c);
                else
                    System.debug('Cannot relate to Graphics Designer: ' + o.Graphics_Designer_NS_Id__c);
            }
            if(o.Order_processed_By_NS_ID__c!=null){
                if(userIds.get(o.Order_processed_By_NS_ID__c)!=null) 
                	o.Order_processed_By__c=userIds.get(o.Order_processed_By_NS_ID__c);
                else
                    System.debug('Cannot relate to Order Processed By: ' + o.Order_processed_By_NS_ID__c);
            }
            if(o.Owner_NS_ID__c!=null){
                if(userIds.get(o.Owner_NS_ID__c)!=null) 
                	o.OwnerId=userIds.get(o.Owner_NS_ID__c);
                else
                    System.debug('Cannot relate to Owner: ' + o.Owner_NS_ID__c);
            }
        }
        
		ApexUtil.isOpportunityTriggerInvoked = false;         
       	upsertResults = Database.upsert(opps.values(), Opportunity.NS_ID__c, false);
        for(Database.UpsertResult upsertResult:upsertResults){
        	if(!upsertResult.isSuccess()) {
            	for(Database.Error upsertError : upsertResult.getErrors()) 
                	System.debug('NetsuiteGetAllSalesOrderBatch - Opportunity Upsert Error: ' + upsertError.getMessage());
            }
     	}
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish NetsuiteGetAllSalesOrderBatch');
        if(!Test.isRunningTest()){
            if(hasMore){
                Database.executeBatch(new NetsuiteGetAllSalesOrderBatch( size, offset));
            }else
                Database.executeBatch(new NetsuiteGetAllCustomersBatch(size, 0), 30);
        }
    }
    
}