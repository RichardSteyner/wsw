public class NetsuiteMethods {
    
    @AuraEnabled
    public static String getEstimate(Id oppId){
        Opportunity oppRecord = [SELECT Id, NS_Estimate_ID__c, NS_ID__c, AccountId, Account.NS_ID__c FROM Opportunity WHERE Id =: oppId];
        Map<String,OpportunityLineItem> oliMap = new Map<String,OpportunityLineItem>();
        for(OpportunityLineItem oli : [SELECT Id, Product2Id, Product2.NS_ID__c, UnitPrice, Quantity, Description, NS_Price_Code__c FROM OpportunityLineItem WHERE OpportunityId =: oppRecord.Id]) oliMap.put(oli.Product2.NS_ID__c,oli);
        if(oppRecord.NS_Estimate_ID__c == null && oppRecord.NS_ID__c == null) return 'Does not have Netsuite ID\'s';
        String xmlBody = '<get><baseRef internalId="' + (oppRecord.NS_ID__c != null ? oppRecord.NS_ID__c : oppRecord.NS_Estimate_ID__c) + '" type="' + (oppRecord.NS_ID__c != null ? 'salesOrder' : 'estimate') + '" xsi:type="platformCore:RecordRef"/></get>';
        HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
        Boolean isEstimate = (oppRecord.NS_ID__c != null ? false : true);
        if(response != null && response.getStatusCode() == 200){
            String errorCode, errorString, errorSuccess;
            if(String.isNotBlank(response.getBody())){
                errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
            }
            if(errorCode == null && errorString == null && errorSuccess == null){
                Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
                Set<String> productsExceptions = new Set<String>();
                for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
                
                Map<String,String> customSettingMap = new Map<String,String>();
                for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl.Value__c);
                
                Map<String,NetsuiteOpp__c> customOppMap = new Map<String,NetsuiteOpp__c>();

                Map<String,String> addressMap = new Map<String,String>();
                for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__c =: oppRecord.AccountId]) if(a.NS_ID__c != null) addressMap.put(a.NS_ID__c,a.Id);
                
                OpportunityLineItem oliRecord;
                List<Dom.XmlNode> estimate = NetsuiteMethods.XmlParser(response.getBody());
                Map<String,Product2> productMap = new Map<String,Product2>();
                List<OpportunityLineItem> olisUpsert = new List<OpportunityLineItem>();
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
                for(Dom.XmlNode childElement1 : estimate){
                    if(childElement1.getName() == 'Body'){
                        for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                            for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                    if(childElement4.getName() == 'record'){
                                        for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
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
                                            if(childElement5.getName() == 'shipAddressList'){
                                                if(addressMap.get(childElement5.getAttribute('internalId',null)) != null) oppRecord.Shipping_Address__c = addressMap.get(childElement5.getAttribute('internalId',null));
                                            }
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
                                                     if(customField.getAttribute('internalId',null) == '45' && customField.getAttribute('scriptId',null) == 'custbody_orderstatus' && !isEstimate){
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
                                                    oliRecord = new OpportunityLineItem(OpportunityId = oppRecord.Id);
                                                    if(oppRecord.NS_ID__c != null) oliRecord.Sales_ID__c = oppRecord.NS_ID__c;
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
                                                        if(itemData.getName() == 'rate' && !productsExceptions.contains(oliRecord.Item_ID__c)) oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                        if(itemData.getName() == 'rate' && productsExceptions.contains(oliRecord.Item_ID__c)){
                                                            if(oliMap.get(oliRecord.Item_ID__c) == null) oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                        }
                                                        if(itemData.getName() == 'lineUniqueKey') oliRecord.NS_ID__c = itemData.getText();
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
                ApexUtil.isOpportunityTriggerInvoked = false;
                ApexUtil.isOliTriggerInvoked = false;
                //update oppRecord;
                Database.saveResult updateResult = Database.update(oppRecord,false);
                if(!updateResult.isSuccess()){
                    for(Database.Error err : updateResult.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields();
                }
                
                if(!olisUpsert.isEmpty()){
                    List<Database.upsertResult> uResults;
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
                        //upsert pbeMap.values();
                        uResults = Database.upsert(pbeMap.values(),false);
                        for(Database.upsertResult result : uResults) {
                            if(!result.isSuccess()){
                                for(Database.Error err : result.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields();
                            }
                        }
                    } 
                    
                    for(OpportunityLineItem oliu : olisUpsert){
                        if(oliu.Id == null && pbeMap.get(oliu.Item_ID__c) != null) oliu.PricebookEntryId = pbeMap.get(oliu.Item_ID__c).Id;
                    }
                    
                    //upsert olisUpsert;
                    uResults = Database.upsert(olisUpsert,false);
                    for(Database.upsertResult result : uResults) {
                        if(!result.isSuccess()){
                            for(Database.Error err : result.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields(); break;
                        }
                    }
                }
                
                //Custom Settings
                for(String key : customOppMap.keySet()){
                    if(customSettingMap.get(key) != null) customOppMap.remove(key); else customSettingMap.put(key,customOppMap.get(key).Value__c);
                }
                if(!customOppMap.isEmpty()) insert customOppMap.values();
                
                Boolean existProduct;
                List<OpportunityLineItem> olisDelete = new List<OpportunityLineItem>();
                List<OpportunityLineItem> olisNew = [SELECT Id, Product2Id FROM OpportunityLineItem WHERE Id IN: olisUpsert];
                for(OpportunityLineItem olix : oliMap.values()){
                    existProduct = false;
                    for(OpportunityLineItem olix2 : olisNew){
                        if(olix.Product2Id == olix2.Product2Id){
                            existProduct = true;
                            break;
                        }
                    }
                    if(!existProduct) olisDelete.add(olix);
                }
                if(!olisDelete.isEmpty()) delete olisDelete;
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
        Account accountRecord = [SELECT Id, NS_ID__c, Association__c FROM Account WHERE Id =: accId];
        String jsonResponse = NetsuiteConnection.getNetsuiteObject('customer/' + accountRecord.NS_ID__c, '');
        if(jsonResponse!=null){
            NetsuiteAddressbookParser nsAddressbook;
            NetsuiteAddressbookParser.AddressBookDetail nsAddressbookDetail;
            NetsuiteAddressbookParser.AddressBookAddress nsAddressbooAddress;
            List<Address__c> addressList = new List<Address__c>();
            Address__c addressRecord;
            Map<String,String> customSettingMap = new Map<String,String>();
            for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl.Value__c);
            
            Map<String,NetsuiteLead__c> customLeadMap = new Map<String,NetsuiteLead__c>();
            NetsuiteCustomerParser customer = (NetsuiteCustomerParser) json.deserialize(jsonResponse, NetsuiteCustomerParser.class);
            if(customer != null){
                accountRecord.Name=customer.companyName;
                accountRecord.NumberOfEmployees=customer.custentity_esc_no_of_employees;
                accountRecord.Taxable__c=customer.taxable;
                accountRecord.Web_Approved_CB__c=customer.custentity_sc_web_approved;
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
                accountRecord.Association__c = null;
                accountRecord.Sales_Order_Notes__c = customer.custentitysalesordernotes;
                accountRecord.Phone = customer.phone;
                accountRecord.Office_Phone__c = customer.altPhone;
                accountRecord.Fax = customer.fax;
                accountRecord.Email__c = customer.email;
                accountRecord.Alt_Contact__c = customer.custentity_invoice_email;
                accountRecord.Alt_Email__c = customer.custentity_order_conf_email;
                accountRecord.Annual_Revenue__c = customer.custentity_esc_annual_revenue;
                accountRecord.ASI__c = customer.custentity9;
                accountRecord.ASI_Number__c = customer.custentity25;
                accountRecord.Credit_Limit__c = customer.creditLimit;
                accountRecord.Tax_Number__c = customer.vatRegNumber;
                accountRecord.Resale_Number__c = customer.resaleNumber;
                accountRecord.Resale_Cert_File_Path__c = customer.custentity_resale_cert_newuser;
                accountRecord.Sale_Rep__c = null;
                if(customer.salesRep != null && customer.salesRep.refName != null){
                    accountRecord.Sale_Rep__c = customer.salesRep.refName;
                    customLeadMap.put(
                        'salesrep-'+customer.salesRep.id,
                        new NetsuiteLead__c(Type__c = 'SalesRep', Name = 'salesrep-'+customer.salesRep.id, ID__c = customer.salesRep.id,Value__c = customer.salesRep.refName)
                    );
                }
                accountRecord.How_Did_You_Hear__c = null;
                if(customer.custentitylead_survey != null && customer.custentitylead_survey.refName != null){
                    accountRecord.How_Did_You_Hear__c = customer.custentitylead_survey.refName;
                    customLeadMap.put(
                        'howdidyourhear-'+customer.custentitylead_survey.id,
                        new NetsuiteLead__c(Type__c = 'HowDidYourHear', Name = 'howdidyourhear-'+customer.custentitylead_survey.id, ID__c = customer.custentitylead_survey.id,Value__c = customer.custentitylead_survey.refName)
                    );
                }
                accountRecord.How_Did_You_Hear_Trade_Shows__c = null;
                if(customer.custentitylead_survey_tradeshow_value != null && customer.custentitylead_survey_tradeshow_value.refName != null){
                    accountRecord.How_Did_You_Hear_Trade_Shows__c = customer.custentitylead_survey_tradeshow_value.refName;
                    customLeadMap.put(
                        'howdidyourheartrade-'+customer.custentitylead_survey_tradeshow_value.id,
                        new NetsuiteLead__c(Type__c = 'HowDidYourHearTradeShow', Name = 'howdidyourheartrade-'+customer.custentitylead_survey_tradeshow_value.id, ID__c = customer.custentitylead_survey_tradeshow_value.id,Value__c = customer.custentitylead_survey_tradeshow_value.refName)
                    );
                }
                accountRecord.Certificate_Approved_By__c = null;
                if(customer.custentitycustentity_certificate_app_by != null && customer.custentitycustentity_certificate_app_by.refName != null){
                    accountRecord.Certificate_Approved_By__c = customer.custentitycustentity_certificate_app_by.refName;
                    customLeadMap.put(
                        'employee-'+customer.custentitycustentity_certificate_app_by.id,
                        new NetsuiteLead__c(Type__c = 'Employee', Name = 'employee-'+customer.custentitycustentity_certificate_app_by.id, ID__c = customer.custentitycustentity_certificate_app_by.id,Value__c = customer.custentitycustentity_certificate_app_by.refName)
                    );
                }
                accountRecord.Dedicated_Resort_Extrusion_Rep__c = null;
                if(customer.custentity45 != null && customer.custentity45.refName != null){
                    accountRecord.Dedicated_Resort_Extrusion_Rep__c = customer.custentity45.refName;
                    customLeadMap.put(
                        'employee-'+customer.custentity45.id,
                        new NetsuiteLead__c(Type__c = 'Employee', Name = 'employee-'+customer.custentity45.id, ID__c = customer.custentity45.id,Value__c = customer.custentity45.refName)
                    );
                }
                accountRecord.Tax_Item__c = null;
                if(customer.taxItem != null && customer.taxItem.refName != null){
                    accountRecord.Tax_Item__c = customer.taxItem.refName;
                    customLeadMap.put(
                        'taxitem-'+customer.taxItem.id,
                        new NetsuiteLead__c(Type__c = 'TaxItem', Name = 'taxitem-'+customer.taxItem.id, ID__c = customer.taxItem.id,Value__c = customer.taxItem.refName)
                    );
                }
                accountRecord.Terms__c = null;
                if(customer.terms != null && customer.terms.refName != null){
                    accountRecord.Terms__c = customer.terms.refName;
                    customLeadMap.put(
                        'terms-'+customer.terms.id,
                        new NetsuiteLead__c(Type__c = 'Terms', Name = 'terms-'+customer.terms.id, ID__c = customer.terms.id,Value__c = customer.terms.refName)
                    );
                }
                accountRecord.Account_Approval_Process__c = null;
                if(customer.custentity_ws_accnt_aprvl_prcs != null && customer.custentity_ws_accnt_aprvl_prcs.refName != null){
                    accountRecord.Account_Approval_Process__c = customer.custentity_ws_accnt_aprvl_prcs.refName;
                    customLeadMap.put(
                        'approvalprocess-'+customer.custentity_ws_accnt_aprvl_prcs.id,
                        new NetsuiteLead__c(Type__c = 'ApprovalProcess', Name = 'approvalprocess-'+customer.custentity_ws_accnt_aprvl_prcs.id, ID__c = customer.custentity_ws_accnt_aprvl_prcs.id,Value__c = customer.custentity_ws_accnt_aprvl_prcs.refName)
                    );
                }
                accountRecord.Partner__c = null;
                if(customer.partner != null && customer.partner.refName != null){
                    accountRecord.Partner__c = customer.partner.refName;
                    customLeadMap.put(
                        'partner-'+customer.partner.id,
                        new NetsuiteLead__c(Type__c = 'Partner', Name = 'partner-'+customer.partner.id, ID__c = customer.partner.id,Value__c = customer.partner.refName)
                    );
                }
                if(customer.custentity2 != null && customer.custentity2.links != null){
                    for(NetsuiteCustomerParser.Link aLink : customer.custentity2.links){
                        if(aLink.href != null){
                            jsonResponse = NetsuiteConnection.getNetsuiteObject(aLink.href.substringAfter('/v1/') , '');
                            NetsuiteCustomerParser.Association associationCustomer = (NetsuiteCustomerParser.Association) json.deserialize(jsonResponse, NetsuiteCustomerParser.Association.class);
                            if(associationCustomer != null && associationCustomer.items != null){
                                for(NetsuiteCustomerParser.AssocItem item : associationCustomer.items){
                                    if(item.refName != null){
                                        accountRecord.Association__c = (accountRecord.Association__c != null ? accountRecord.Association__c + ';' : '') + item.refName;
                                        customLeadMap.put(
                                            'association-'+item.id,
                                            new NetsuiteLead__c(Type__c = 'Association', Name = 'association-'+item.Id, ID__c = item.id,Value__c = item.refName)
                                        );
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
                if(customer.addressBook != null && customer.addressBook.links != null){
                    for(NetsuiteCustomerParser.Link alink : customer.addressBook.links){
                        if(alink.href != null){
                            system.debug(alink.href.substringAfter('/v1/'));
                            jsonResponse = NetsuiteConnection.getNetsuiteObject(alink.href.substringAfter('/v1/') , '');
                            if(jsonResponse!=null){
                                nsAddressbook = (NetsuiteAddressbookParser) json.deserialize(jsonResponse, NetsuiteAddressbookParser.class);
                                if(nsAddressbook != null && nsAddressbook.items != null){
                                    for(NetsuiteAddressbookParser.Item item : nsAddressbook.items){
                                        for(NetsuiteAddressbookParser.Link ablink : item.links){
                                            if(ablink.href != null){
                                                jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') , '');
                                                if(jsonResponse!=null){
                                                    nsAddressbookDetail = (NetsuiteAddressbookParser.AddressBookDetail) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookDetail.class);
                                                    if(nsAddressbookDetail != null){
                                                        addressRecord = new Address__c();
                                                        addressRecord.NS_ID__c = nsAddressbookDetail.id;
                                                        addressRecord.Customer__c = accountRecord.Id;
                                                        addressRecord.Default_Billing__c = nsAddressbookDetail.defaultBilling;
                                                        addressRecord.Default_Shipping__c = nsAddressbookDetail.defaultShipping;
                                                        jsonResponse = NetsuiteConnection.getNetsuiteObject(ablink.href.substringAfter('/v1/') + '/addressbookaddress' , '');
                                                        if(jsonResponse!=null){
                                                            system.debug('enter3');
                                                            nsAddressbooAddress = (NetsuiteAddressbookParser.AddressBookAddress) json.deserialize(jsonResponse, NetsuiteAddressbookParser.AddressBookAddress.class);
                                                            if(nsAddressbooAddress != null){
                                                                addressRecord.Address_1__c = nsAddressbooAddress.addr1;
                                                                addressRecord.Address_2__c = nsAddressbooAddress.addr2;
                                                                addressRecord.Addressee__c = nsAddressbooAddress.addressee;
                                                                addressRecord.Attention__c = nsAddressbooAddress.attention;
                                                                addressRecord.City__c = nsAddressbooAddress.city;
                                                                addressRecord.State__c = nsAddressbooAddress.state;
                                                                addressRecord.Country__c = nsAddressbooAddress.country;
                                                                //addressRecord.Country_Code__c = nsAddressbooAddress.country;
                                                                addressRecord.Zip__c = nsAddressbooAddress.zip;
                                                                addressRecord.Phone__c = nsAddressbooAddress.addrPhone;
                                                                if(addressRecord.Default_Billing__c == true){
                                                                    accountRecord.Address_Phone__c = nsAddressbooAddress.addrPhone;
                                                                    accountRecord.Address_1__c = nsAddressbooAddress.addr1;
                                                                    accountRecord.Address_2__c = nsAddressbooAddress.addr2;
                                                                    accountRecord.Attention_Address__c = nsAddressbooAddress.attention;
                                                                    accountRecord.BillingStreet = nsAddressbooAddress.addr1;
                                                                    accountRecord.BillingState = nsAddressbooAddress.state;
                                                                    accountRecord.BillingCity = nsAddressbooAddress.city;
                                                                    accountRecord.BillingCountry = nsAddressbooAddress.country;
                                                                    accountRecord.BillingPostalCode = nsAddressbooAddress.zip;
                                                                }
                                                                if(addressRecord.Default_Shipping__c == true){
                                                                    accountRecord.ShippingStreet = nsAddressbooAddress.addr1;
                                                                    accountRecord.ShippingState = nsAddressbooAddress.state;
                                                                    accountRecord.ShippingCity = nsAddressbooAddress.city;
                                                                    accountRecord.ShippingCountry = nsAddressbooAddress.country;
                                                                    accountRecord.ShippingPostalCode = nsAddressbooAddress.zip;
                                                                }
                                                            }
                                                        }
                                                        addressList.add(addressRecord);
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
                }
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
                //update accountRecord;
                Database.saveResult updateResult = Database.update(accountRecord,false);
                if(!updateResult.isSuccess()){
                    for(Database.Error err : updateResult.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields();
                }
                
                ApexUtil.isAddressTriggerInvoked = false;
                List<Database.upsertResult> uResults = Database.upsert(addressList,Address__c.NS_ID__c,false);
                for(Database.upsertResult result : uResults) {
                    if(!result.isSuccess()){
                        for(Database.Error err : result.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields(); break;
                    }
                }
            }
        }
        return 'Ok';
    }
    
    @AuraEnabled
    public static String getContact(Id contactId){
        Contact contactRecord = [SELECT Id, NS_ID__c FROM Contact WHERE Id =: contactId]; 
        if(contactRecord.NS_ID__c != null){
            String xmlBody = '<get><baseRef internalId="' + contactRecord.NS_ID__c + '" type="contact" xsi:type="platformCore:RecordRef"/></get>';
            HTTPResponse response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
            if(response != null && response.getStatusCode() == 200){
                String errorCode, errorString, errorSuccess;
                if(String.isNotBlank(response.getBody())){
                    errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                    errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                    errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                }
                if(errorCode == null && errorString == null && errorSuccess == null){
                    List<Dom.XmlNode> contactXML = NetsuiteMethods.XmlParser(response.getBody());
                    for(Dom.XmlNode childElement1 : contactXML){
                        if(childElement1.getName() == 'Body'){
                            for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                    for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                        if(childElement4.getName() == 'record'){
                                            for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                if(childElement5.getName() == 'salutation') contactRecord.Salutation = childElement5.getText();
                                                if(childElement5.getName() == 'firstName') contactRecord.Firstname = childElement5.getText();
                                                if(childElement5.getName() == 'lastName') contactRecord.Lastname = childElement5.getText();
                                                if(childElement5.getName() == 'title') contactRecord.Title = childElement5.getText();
                                                if(childElement5.getName() == 'phone') contactRecord.Phone = childElement5.getText();
                                                if(childElement5.getName() == 'fax') contactRecord.Fax = childElement5.getText();
                                                if(childElement5.getName() == 'email') contactRecord.Email = childElement5.getText();
                                                if(childElement5.getName() == 'altEmail') contactRecord.Alt_Email__c = childElement5.getText();
                                                if(childElement5.getName() == 'mobilePhone') contactRecord.MobilePhone = childElement5.getText();
                                                if(childElement5.getName() == 'officePhone') contactRecord.OtherPhone = childElement5.getText();
                                                if(childElement5.getName() == 'homePhone') contactRecord.HomePhone = childElement5.getText();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    ApexUtil.isContactTriggerInvoked = false;
                    Database.saveResult updateResult = Database.update(contactRecord,false);
                    if(!updateResult.isSuccess()){
                        for(Database.Error err : updateResult.getErrors()) return err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields();
                    }
                } else {
                    if(errorSuccess != null) 
                        return errorSuccess; 
                    else 
                        return errorCode + ': ' + errorString;
                }
            }
        }else{
            return 'The contact does not have a Netsuite ID.';
        }
        return 'Ok';
    }
    
    @future(callout=true)
    public static void createEstimate(Set<String> recordIds){
        Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
        Set<String> productsExceptions = new Set<String>();
        for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
        
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        Map<String,List<NetsuiteLead__c>> customSettingCustomerMap = new Map<String,List<NetsuiteLead__c>>();
        List<NetsuiteLead__c> listCustomerAux;
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()){
            listCustomerAux = customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteLead__c>();
            listCustomerAux.add(nl);
            customSettingCustomerMap.put(nl.Type__c.trim().toLowerCase(),listCustomerAux.clone());
        }
        
        Set<String> customerIds = new Set<String>();
        for(Opportunity oppRecord : [SELECT Id, AccountId, Account.NS_ID__c FROM Opportunity WHERE Id IN: recordIds]) if(oppRecord.Account.NS_ID__c != null) customerIds.add(oppRecord.Account.NS_ID__c);
        Map<String,String> addressMap = new Map<String,String>();
        for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__r.NS_ID__c IN: customerIds]) if(a.NS_ID__c != null) addressMap.put(a.NS_ID__c,a.Id);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        OpportunityLineItem oliRecord;
        String orderDetail, pricelevel, partner;
        String xmlBody;
        for(Opportunity oppRecord : [SELECT Id, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Estimate_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Account.Price_Level__c, Email__c, Graphic_and_Sales_Notes__c, In_Han_Date__c,
                                     Production_Turn_Time__c, Warehouse_Notes__c, Did_I_Offer_A_Free_Sample__c, Customer_Service_Note__c, Partner__c, PO__c, Proofsheet_Finishing_Notes__c, CreatedBy.NS_ID__c, Use_Art_Files_from_other_orders__c, Art_file_by_email__c,
                                     (SELECT Id, Product2.NS_ID__c, NS_ID__c, Description, Quantity, NS_Price_Code__c, UnitPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            orderDetail = null;
            pricelevel = null;
            partner = null;
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    if(customSettingMap.get('orderdetail') != null) for(NetsuiteOpp__c orderDetailValue : customSettingMap.get('orderdetail')) if(orderDetailValue.Value__c == oppRecord.Order_Detail__c) orderDetail = orderDetailValue.ID__c;
                    if(customSettingCustomerMap.get('pricelevel') != null) for(NetsuiteLead__c priceLevelValue : customSettingCustomerMap.get('pricelevel')) if(priceLevelValue.Value__c == oppRecord.Account.Price_Level__c) pricelevel = priceLevelValue.ID__c;
                    if(customSettingMap.get('partner') != null) for(NetsuiteOpp__c partnerValue : customSettingMap.get('partner')) if(partnerValue.Value__c == oppRecord.Partner__c) partner = partnerValue.ID__c;
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
                        (partner != null ? '<tranSales:partner internalId="' + partner +'" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                        (oppRecord.PO__c != null ? '<tranSales:otherRefNum>' + oppRecord.PO__c + '</tranSales:otherRefNum>' : '') +
                        '		<tranSales:endDate>' + (oppRecord.In_Han_Date__c != null ? Datetime.newInstance(oppRecord.In_Han_Date__c.year(), oppRecord.In_Han_Date__c.month(), oppRecord.In_Han_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '') + '</tranSales:endDate>' +
                        '		<tranSales:itemList>';
                    for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                        xmlBody += 
                            '    		<tranSales:item>' +
                            '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '        		<tranSales:expandItemGroup>false</tranSales:expandItemGroup>' +
                            '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                            '        		<tranSales:description>' + oli.Description + '</tranSales:description>' +
                            (!productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="' + (pricelevel != null ? pricelevel : '-1') + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                            (productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="-1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" /><tranSales:rate>' + oli.UnitPrice + '</tranSales:rate>' : '') +
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
                        '			<platformCore:customField internalId="60" scriptId="custbody4" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Graphic_and_Sales_Notes__c != null ? oppRecord.Graphic_and_Sales_Notes__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6730" scriptId="custbodyproduction_turn_time" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Production_Turn_Time__c != null ? oppRecord.Production_Turn_Time__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="64" scriptId="custbody8" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Warehouse_Notes__c != null ? oppRecord.Warehouse_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6720" scriptId="custbody107" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Did_I_Offer_A_Free_Sample__c != null ? (oppRecord.Did_I_Offer_A_Free_Sample__c ? 'true' : 'false') : 'false' ) + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4552" scriptId="custbody93" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Customer_Service_Note__c != null ? oppRecord.Customer_Service_Note__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4580" scriptId="custbody_proofsheetfinishing" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Proofsheet_Finishing_Notes__c != null ? oppRecord.Proofsheet_Finishing_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        (oppRecord.CreatedBy.NS_ID__c != null ? '<platformCore:customField internalId="65" scriptId="custbody9" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ oppRecord.CreatedBy.NS_ID__c +'" typeId="-4" /></platformCore:customField>' : '') +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</add>';
                    
                    HTTPResponse response;
                    String xmlBodyResponse = '<?xml version="1.0" encoding="UTF-8"?>'+
                        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                            '<soapenv:Header>'+
                                '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                    '<platformMsgs:nsId>WEBSERVICES_1030411_01062021669751396118193960_cbf40b6a6cc52</platformMsgs:nsId>'+
                                '</platformMsgs:documentInfo>'+
                            '</soapenv:Header>'+
                            '<soapenv:Body>'+
                                '<getResponse xmlns="">'+
                                    '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                        '<platformMsgs:record internalId="7792583" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">'+
                                            '<tranSales:createdDate>2020-12-04T08:00:36.000-08:00</tranSales:createdDate>'+
                                            '<tranSales:customForm internalId="152" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>WS Sales Order - SCA (Preferred)</platformCore:name>'+
                                            '</tranSales:customForm>'+
                                            '<tranSales:entity internalId="243631" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>61208 TestingXperts</platformCore:name>'+
                                            '</tranSales:entity>'+
                                            '<tranSales:tranDate>2020-12-04T00:00:00.000-08:00</tranSales:tranDate>'+
                                            '<tranSales:tranId>SO-540086</tranSales:tranId>'+
                                            '<tranSales:source>Web Services</tranSales:source>'+
                                            '<tranSales:orderStatus>_cancelled</tranSales:orderStatus>'+
                                            '<tranSales:endDate>2020-12-19T00:00:00.000-08:00</tranSales:endDate>'+
                                            '<tranSales:memo>VOID</tranSales:memo>'+
                                            '<tranSales:toBePrinted>false</tranSales:toBePrinted>'+
                                            '<tranSales:toBeEmailed>false</tranSales:toBeEmailed>'+
                                            '<tranSales:toBeFaxed>false</tranSales:toBeFaxed>'+
                                            '<tranSales:shipIsResidential>false</tranSales:shipIsResidential>'+
                                            '<tranSales:shipAddressList internalId="782559" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>1000 main Street</platformCore:name>'+
                                            '</tranSales:shipAddressList>'+
                                            '<tranSales:isMultiShipTo>false</tranSales:isMultiShipTo>'+
                                            '<tranSales:shipComplete>false</tranSales:shipComplete>'+
                                            '<tranSales:saveOnAuthDecline>true</tranSales:saveOnAuthDecline>'+
                                            '<tranSales:canHaveStackable>true</tranSales:canHaveStackable>'+
                                            '<tranSales:ccApproved>false</tranSales:ccApproved>'+
                                            '<tranSales:isRecurringPayment>false</tranSales:isRecurringPayment>'+
                                            '<tranSales:subTotal>3006.0</tranSales:subTotal>'+
                                            '<tranSales:discountTotal>0.0</tranSales:discountTotal>'+
                                            '<tranSales:taxTotal>248.0</tranSales:taxTotal>'+
                                            '<tranSales:total>3254.0</tranSales:total>'+
                                            '<tranSales:balance>0.0</tranSales:balance>'+
                                            '<tranSales:paypalProcess>false</tranSales:paypalProcess>'+
                                            '<tranSales:subsidiary internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>Parent Company</platformCore:name>'+
                                            '</tranSales:subsidiary>'+
                                            '<tranSales:lastModifiedDate>2021-01-06T06:02:51.000-08:00</tranSales:lastModifiedDate>'+
                                            '<tranSales:status>Cancelled</tranSales:status>'+
                							'<tranSales:itemList>'+
                                                '<tranSales:item>'+
                                                    '<tranSales:item internalId="3668" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AF7X7GO2</platformCore:name>'+
                                                    '</tranSales:item>'+
                                                    '<tranSales:expandItemGroup>false</tranSales:expandItemGroup>'+
                                                    '<tranSales:lineUniqueKey>106092690</tranSales:lineUniqueKey>'+
                                                    '<tranSales:quantityOnHand>0.0</tranSales:quantityOnHand>'+
                                                    '<tranSales:quantity>10.0</tranSales:quantity>'+
                                                    '<tranSales:price internalId="6" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>WS Display</platformCore:name>'+
                                                    '</tranSales:price>'+
                                                    '<tranSales:rate>298.60</tranSales:rate>'+
                                                    '<tranSales:amount>2986.0</tranSales:amount>'+
                                                    '<tranSales:class internalId="11" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>Resort Extrusions</platformCore:name>'+
                                                    '</tranSales:class>'+
                                                    '<tranSales:location internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>California</platformCore:name>'+
                                                    '</tranSales:location>'+
                                                    '<tranSales:createWo>false</tranSales:createWo>'+
                                                    '<tranSales:isClosed>false</tranSales:isClosed>'+
                                                    '<tranSales:fromJob>false</tranSales:fromJob>'+
                                                    '<tranSales:excludeFromRateRequest>false</tranSales:excludeFromRateRequest>'+
                                                    '<tranSales:isEstimate>false</tranSales:isEstimate>'+
                                                    '<tranSales:line>466</tranSales:line>'+
                                                    '<tranSales:taxCode internalId="19388" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AVATAX</platformCore:name>'+
                                                    '</tranSales:taxCode>'+
                                                    '<tranSales:taxRate1>8.25</tranSales:taxRate1>'+
                                                    '<tranSales:shipGroup>1</tranSales:shipGroup>'+
                                                    '<tranSales:itemIsFulfilled>false</tranSales:itemIsFulfilled>'+
                                                '</tranSales:item>'+
                                            '</tranSales:itemList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
                    if(Test.isRunningTest()){
                        response = new HttpResponse();
                        response.setStatusCode(200);
                        response.setBody(xmlBodyResponse);
                    }else{
                        response = NetsuiteConnection.postNetsuiteSoap('add',xmlBody,true);
                    }
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
                            oppRecord.NS_Estimate_ID__c = (!Test.isRunningTest() ? response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="estimate"') : '123');
                            if(oppRecord.NS_Estimate_ID__c != null){
                                xmlBody = '<get><baseRef internalId="' + oppRecord.NS_Estimate_ID__c + '" type="estimate" xsi:type="platformCore:RecordRef"/></get>';
                                if(!Test.isRunningTest()){
                                    response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
                                }else{
                                    response = new HttpResponse();
                                    response.setStatusCode(200);
                                    response.setBody(xmlBodyResponse);
                                }
                                if(response != null && response.getStatusCode() == 200){
                                    system.debug(oppRecord);
                                    system.debug(response.getBody());
                                    oppRecord.Estimate__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:tranId>','</tranSales:tranId>') : null;
                                    oppRecord.Estimate_Status__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? (response.getBody().subStringBetween('<tranSales:entityStatus','</tranSales:entityStatus>') != null ? response.getBody().subStringBetween('<tranSales:entityStatus','</tranSales:entityStatus>').subStringBetween('<platformCore:name>','</platformCore:name>') : null) : null;
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
                                                                if(childElement5.getName() == 'subTotal') oppRecord.Subtotal__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'discountTotal') oppRecord.Discount_Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'taxTotal') oppRecord.Tax_Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'total') oppRecord.Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'shipAddressList'){
                                                                    if(addressMap.get(childElement5.getAttribute('internalId',null)) != null) oppRecord.Shipping_Address__c = addressMap.get(childElement5.getAttribute('internalId',null));
                                                                }
                                                                if(childElement5.getName() == 'itemList'){
                                                                    for(Dom.XmlNode item : childElement5.getChildElements()){
                                                                        oliRecord = new OpportunityLineItem();
                                                                        for(Dom.XmlNode itemData : item.getChildElements()){
                                                                            if(itemData.getName() == 'item') oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                                            if(itemData.getName() == 'rate') oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                                            if(itemData.getName() == 'quantity') oliRecord.Quantity = Decimal.valueOf(itemData.getText());
                                                                            if(itemData.getName() == 'price') oliRecord.NS_Price_Code__c = itemData.getAttribute('internalId',null);
                                                                        }
                                                                        for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                                                                            if(oli.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                oli.UnitPrice = oliRecord.UnitPrice;
                                                                                oli.NS_Price_Code__c = oliRecord.NS_Price_Code__c;
                                                                                opportunityLineItemList.add(oli);
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                        }
                    }else{
                        oppRecord.Netsuite_To_Sync__c = false;
                        oppRecord.Netsuite_Sync_Status__c = 'Error';
                        oppRecord.Netsuite_Sync_Error__c = response.getBody().substringBetween('<platformFaults:message>','</platformFaults:message>');
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
        ApexUtil.isOliTriggerInvoked = false;
        if(!opportunityList.isEmpty()) update opportunityList;
        if(!opportunityLineItemList.isEmpty()) update opportunityLineItemList;
    }
    
    @future(callout=true)
    public static void updateEstimate(Set<String> recordIds){
        Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
        Set<String> productsExceptions = new Set<String>();
        for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
        
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        Map<String,List<NetsuiteLead__c>> customSettingCustomerMap = new Map<String,List<NetsuiteLead__c>>();
        List<NetsuiteLead__c> listCustomerAux;
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()){
            listCustomerAux = customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteLead__c>();
            listCustomerAux.add(nl);
            customSettingCustomerMap.put(nl.Type__c.trim().toLowerCase(),listCustomerAux.clone());
        }
        
        Set<String> customerIds = new Set<String>();
        for(Opportunity oppRecord : [SELECT Id, AccountId, Account.NS_ID__c FROM Opportunity WHERE Id IN: recordIds]) if(oppRecord.Account.NS_ID__c != null) customerIds.add(oppRecord.Account.NS_ID__c);
        Map<String,String> addressMap = new Map<String,String>();
        for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__r.NS_ID__c IN: customerIds]) if(a.NS_ID__c != null) addressMap.put(a.Id,a.NS_ID__c);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        OpportunityLineItem oliRecord;
        String orderDetail, partner, pricelevel;
        String xmlBody;
        Boolean haveProduct;
        for(Opportunity oppRecord : [SELECT Id, NS_Estimate_ID__c, Shipping_Address__c, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Estimate_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Account.Price_Level__c, Email__c, Graphic_and_Sales_Notes__c, Production_Turn_Time__c,
                                     Warehouse_Notes__c, Did_I_Offer_A_Free_Sample__c, Customer_Service_Note__c, Partner__c, PO__c, Proofsheet_Finishing_Notes__c, CreatedBy.NS_ID__c, Use_Art_Files_from_other_orders__c, Art_file_by_email__c, In_Han_Date__c,
                                     (SELECT Id, Product2.NS_ID__c, NS_ID__c, Description, Quantity, NS_Price_Code__c, UnitPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    orderDetail = null;
                    partner = null;
                    pricelevel = null;
                    if(customSettingMap.get('orderdetail') != null) for(NetsuiteOpp__c orderDetailValue : customSettingMap.get('orderdetail')) if(orderDetailValue.Value__c == oppRecord.Order_Detail__c) orderDetail = orderDetailValue.ID__c;
                    if(customSettingMap.get('partner') != null) for(NetsuiteOpp__c partnerValue : customSettingMap.get('partner')) if(partnerValue.Value__c == oppRecord.Partner__c) partner = partnerValue.ID__c;
                    if(customSettingCustomerMap.get('pricelevel') != null) for(NetsuiteLead__c priceLevelValue : customSettingCustomerMap.get('pricelevel')) if(priceLevelValue.Value__c == oppRecord.Account.Price_Level__c) pricelevel = priceLevelValue.ID__c;
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
                        (partner != null ? '<tranSales:partner internalId="' + partner +'" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                        '		<tranSales:otherRefNum>' + (oppRecord.PO__c != null ? oppRecord.PO__c : '') + '</tranSales:otherRefNum>' +
                        (oppRecord.Shipping_Address__c != null && addressMap.get(oppRecord.Shipping_Address__c) != null ? '<tranSales:shipAddressList internalId="' + addressMap.get(oppRecord.Shipping_Address__c) + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                        '		<tranSales:endDate>' + (oppRecord.In_Han_Date__c != null ? Datetime.newInstance(oppRecord.In_Han_Date__c.year(), oppRecord.In_Han_Date__c.month(), oppRecord.In_Han_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '') + '</tranSales:endDate>' +
                        '		<tranSales:itemList>';
                    for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                        xmlBody += 
                            '    		<tranSales:item>' +
                            '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '        		<tranSales:expandItemGroup>false</tranSales:expandItemGroup>' +
                            '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                            '        		<tranSales:description>' + (oli.Description != null ? oli.Description : '') + '</tranSales:description>' +
                            (!productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="' + (oli.NS_Price_Code__c != null ? oli.NS_Price_Code__c : (pricelevel != null ? pricelevel : '-1')) + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                            (productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="-1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" /><tranSales:rate>' + oli.UnitPrice + '</tranSales:rate>' : '') +
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
                        '			<platformCore:customField internalId="60" scriptId="custbody4" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Graphic_and_Sales_Notes__c != null ? oppRecord.Graphic_and_Sales_Notes__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6730" scriptId="custbodyproduction_turn_time" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Production_Turn_Time__c != null ? oppRecord.Production_Turn_Time__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="64" scriptId="custbody8" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Warehouse_Notes__c != null ? oppRecord.Warehouse_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6720" scriptId="custbody107" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Did_I_Offer_A_Free_Sample__c != null ? (oppRecord.Did_I_Offer_A_Free_Sample__c ? 'true' : 'false') : 'false' ) + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4552" scriptId="custbody93" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Customer_Service_Note__c != null ? oppRecord.Customer_Service_Note__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4580" scriptId="custbody_proofsheetfinishing" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Proofsheet_Finishing_Notes__c != null ? oppRecord.Proofsheet_Finishing_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        (oppRecord.CreatedBy.NS_ID__c != null ? '<platformCore:customField internalId="65" scriptId="custbody9" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ oppRecord.CreatedBy.NS_ID__c +'" typeId="-4" /></platformCore:customField>' : '') +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</update>';
                    
                    HTTPResponse response;
                    String xmlBodyResponse = '<?xml version="1.0" encoding="UTF-8"?>'+
                        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                            '<soapenv:Header>'+
                                '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                    '<platformMsgs:nsId>WEBSERVICES_1030411_01062021669751396118193960_cbf40b6a6cc52</platformMsgs:nsId>'+
                                '</platformMsgs:documentInfo>'+
                            '</soapenv:Header>'+
                            '<soapenv:Body>'+
                                '<getResponse xmlns="">'+
                                    '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                        '<platformMsgs:record internalId="7792583" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">'+
                                            '<tranSales:createdDate>2020-12-04T08:00:36.000-08:00</tranSales:createdDate>'+
                                            '<tranSales:customForm internalId="152" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>WS Sales Order - SCA (Preferred)</platformCore:name>'+
                                            '</tranSales:customForm>'+
                                            '<tranSales:entity internalId="243631" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>61208 TestingXperts</platformCore:name>'+
                                            '</tranSales:entity>'+
                                            '<tranSales:tranDate>2020-12-04T00:00:00.000-08:00</tranSales:tranDate>'+
                                            '<tranSales:tranId>SO-540086</tranSales:tranId>'+
                                            '<tranSales:source>Web Services</tranSales:source>'+
                                            '<tranSales:orderStatus>_cancelled</tranSales:orderStatus>'+
                                            '<tranSales:endDate>2020-12-19T00:00:00.000-08:00</tranSales:endDate>'+
                                            '<tranSales:memo>VOID</tranSales:memo>'+
                                            '<tranSales:toBePrinted>false</tranSales:toBePrinted>'+
                                            '<tranSales:toBeEmailed>false</tranSales:toBeEmailed>'+
                                            '<tranSales:toBeFaxed>false</tranSales:toBeFaxed>'+
                                            '<tranSales:shipIsResidential>false</tranSales:shipIsResidential>'+
                                            '<tranSales:shipAddressList internalId="782559" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>1000 main Street</platformCore:name>'+
                                            '</tranSales:shipAddressList>'+
                                            '<tranSales:isMultiShipTo>false</tranSales:isMultiShipTo>'+
                                            '<tranSales:shipComplete>false</tranSales:shipComplete>'+
                                            '<tranSales:saveOnAuthDecline>true</tranSales:saveOnAuthDecline>'+
                                            '<tranSales:canHaveStackable>true</tranSales:canHaveStackable>'+
                                            '<tranSales:ccApproved>false</tranSales:ccApproved>'+
                                            '<tranSales:isRecurringPayment>false</tranSales:isRecurringPayment>'+
                                            '<tranSales:subTotal>3006.0</tranSales:subTotal>'+
                                            '<tranSales:discountTotal>0.0</tranSales:discountTotal>'+
                                            '<tranSales:taxTotal>248.0</tranSales:taxTotal>'+
                                            '<tranSales:total>3254.0</tranSales:total>'+
                                            '<tranSales:balance>0.0</tranSales:balance>'+
                                            '<tranSales:paypalProcess>false</tranSales:paypalProcess>'+
                                            '<tranSales:subsidiary internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>Parent Company</platformCore:name>'+
                                            '</tranSales:subsidiary>'+
                                            '<tranSales:lastModifiedDate>2021-01-06T06:02:51.000-08:00</tranSales:lastModifiedDate>'+
                                            '<tranSales:status>Cancelled</tranSales:status>'+
                							'<tranSales:itemList>'+
                                                '<tranSales:item>'+
                                                    '<tranSales:item internalId="3668" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AF7X7GO2</platformCore:name>'+
                                                    '</tranSales:item>'+
                                                    '<tranSales:expandItemGroup>false</tranSales:expandItemGroup>'+
                                                    '<tranSales:lineUniqueKey>106092690</tranSales:lineUniqueKey>'+
                                                    '<tranSales:quantityOnHand>0.0</tranSales:quantityOnHand>'+
                                                    '<tranSales:quantity>10.0</tranSales:quantity>'+
                                                    '<tranSales:price internalId="6" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>WS Display</platformCore:name>'+
                                                    '</tranSales:price>'+
                                                    '<tranSales:rate>298.60</tranSales:rate>'+
                                                    '<tranSales:amount>2986.0</tranSales:amount>'+
                                                    '<tranSales:class internalId="11" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>Resort Extrusions</platformCore:name>'+
                                                    '</tranSales:class>'+
                                                    '<tranSales:location internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>California</platformCore:name>'+
                                                    '</tranSales:location>'+
                                                    '<tranSales:createWo>false</tranSales:createWo>'+
                                                    '<tranSales:isClosed>false</tranSales:isClosed>'+
                                                    '<tranSales:fromJob>false</tranSales:fromJob>'+
                                                    '<tranSales:excludeFromRateRequest>false</tranSales:excludeFromRateRequest>'+
                                                    '<tranSales:isEstimate>false</tranSales:isEstimate>'+
                                                    '<tranSales:line>466</tranSales:line>'+
                                                    '<tranSales:taxCode internalId="19388" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AVATAX</platformCore:name>'+
                                                    '</tranSales:taxCode>'+
                                                    '<tranSales:taxRate1>8.25</tranSales:taxRate1>'+
                                                    '<tranSales:shipGroup>1</tranSales:shipGroup>'+
                                                    '<tranSales:itemIsFulfilled>false</tranSales:itemIsFulfilled>'+
                                                '</tranSales:item>'+
                                            '</tranSales:itemList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
                    if(Test.isRunningTest()){
                        response = new HttpResponse();
                        response.setStatusCode(200);
                        response.setBody(xmlBodyResponse);
                    }else{
                        response = NetsuiteConnection.postNetsuiteSoap('update',xmlBody,true);
                    }
                    oppRecord.Update_Items__c = false;
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
                            
                            if(oppRecord.NS_Estimate_ID__c != null){
                                xmlBody = '<get><baseRef internalId="' + oppRecord.NS_Estimate_ID__c + '" type="estimate" xsi:type="platformCore:RecordRef"/></get>';
                                if(!Test.isRunningTest()){
                                    response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
                                }else{
                                    response = new HttpResponse();
                                    response.setStatusCode(200);
                                    response.setBody(xmlBodyResponse);
                                }
                                if(response != null && response.getStatusCode() == 200){
                                    List<Dom.XmlNode> estimateXML = NetsuiteMethods.XmlParser(response.getBody());
                                    String salesOrderId;
                                    for(Dom.XmlNode childElement1 : estimateXML){
                                        if(childElement1.getName() == 'Body'){
                                            for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                                for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                                    for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                                        if(childElement4.getName() == 'record'){
                                                            salesOrderId = childElement4.getAttribute('internalId',null);
                                                            for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                                if(childElement5.getName() == 'subTotal') oppRecord.Subtotal__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'discountTotal') oppRecord.Discount_Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'taxTotal') oppRecord.Tax_Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'total') oppRecord.Total__c = Decimal.valueOf(childElement5.getText());
                                                                if(childElement5.getName() == 'shipAddressList'){
                                                                    if(addressMap.get(childElement5.getAttribute('internalId',null)) != null) oppRecord.Shipping_Address__c = addressMap.get(childElement5.getAttribute('internalId',null));
                                                                }
                                                                if(childElement5.getName() == 'itemList'){
                                                                    for(Dom.XmlNode item : childElement5.getChildElements()){
                                                                        oliRecord = new OpportunityLineItem();
                                                                        oliRecord.Opportunity = new Opportunity(NS_ID__c = salesOrderId);
                                                                        for(Dom.XmlNode itemData : item.getChildElements()){
                                                                            if(itemData.getName() == 'item'){
                                                                                oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                                                haveProduct = false;
                                                                                for(OpportunityLineItem oliAux : oppRecord.OpportunityLineItems){
                                                                                    if(oliAux.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                        oliRecord.Id = oliAUx.Id; haveProduct = true; break;
                                                                                    }
                                                                                }
                                                                                if(!haveProduct){
                                                                                    for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                                        if(itemDataDetail.getName() == 'name'){
                                                                                            productMap.put(itemData.getAttribute('internalId',null),new Product2(Name = itemDataDetail.getText(),isActive = true,NS_ID__c = itemData.getAttribute('internalId',null)));
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            if(itemData.getName() == 'rate') oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                                            if(itemData.getName() == 'quantity') oliRecord.Quantity = Decimal.valueOf(itemData.getText());
                                                                            if(itemData.getName() == 'price'){
                                                                                oliRecord.NS_Price_Code__c = itemData.getAttribute('internalId',null);
                                                                                for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                                    if(itemDataDetail.getName() == 'name'){
                                                                                        oliRecord.Price_Level__c = itemDataDetail.getText();
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                        for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                                                                            if(oli.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                oli.UnitPrice = oliRecord.UnitPrice;
                                                                                oli.NS_Price_Code__c = oliRecord.NS_Price_Code__c;
                                                                                opportunityLineItemList.add(oli);
                                                                            }
                                                                        }                                                                            
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                        }
                    }else{
                        oppRecord.Netsuite_To_Sync__c = false;
                        oppRecord.Netsuite_Sync_Status__c = 'Error';
                        oppRecord.Netsuite_Sync_Error__c = response.getBody().substringBetween('<platformFaults:message>','</platformFaults:message>');
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
        ApexUtil.isOliTriggerInvoked = false;
        if(!opportunityList.isEmpty()){
            List<Database.saveResult> updateResults = Database.update(opportunityList,false);
            for(Database.saveResult updateResult : updateResults) {
                if(!updateResult.isSuccess()){
                    for(Database.Error err : updateResult.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                }
            }
        }
        if(!opportunityLineItemList.isEmpty()){
            List<Database.upsertResult> uResults;
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
                //upsert pbeMap.values();
                uResults = Database.upsert(pbeMap.values(),false);
                for(Database.upsertResult result : uResults) {
                    if(!result.isSuccess()){
                        for(Database.Error err : result.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                    }
                }
            } 
            
            for(OpportunityLineItem oliu : opportunityLineItemList){
                if(oliu.Id == null && pbeMap.get(oliu.Item_ID__c) != null) oliu.PricebookEntryId = pbeMap.get(oliu.Item_ID__c).Id;
            }
            uResults = Database.upsert(opportunityLineItemList,false);
            for(Database.upsertResult result : uResults) {
                if(!result.isSuccess()){
                    for(Database.Error err : result.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                }
            }    
        }
    }
    
    @future(callout=true)
    public static void convertSale(Set<String> recordIds){
        Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
        Set<String> productsExceptions = new Set<String>();
        for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
        
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        Map<String,List<NetsuiteLead__c>> customSettingCustomerMap = new Map<String,List<NetsuiteLead__c>>();
        List<NetsuiteLead__c> listCustomerAux;
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()){
            listCustomerAux = customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteLead__c>();
            listCustomerAux.add(nl);
            customSettingCustomerMap.put(nl.Type__c.trim().toLowerCase(),listCustomerAux.clone());
        }
        
        Set<String> customerIds = new Set<String>();
        for(Opportunity oppRecord : [SELECT Id, AccountId, Account.NS_ID__c FROM Opportunity WHERE Id IN: recordIds]) if(oppRecord.Account.NS_ID__c != null) customerIds.add(oppRecord.Account.NS_ID__c);
        Map<String,String> addressMap = new Map<String,String>();
        for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__r.NS_ID__c IN: customerIds]) if(a.NS_ID__c != null) addressMap.put(a.NS_ID__c,a.Id);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        String orderDetail, partner, graphics;
        String status, pricelevel, xmlBody;
        OpportunityLineItem oliRecord;
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        for(Opportunity oppRecord : [SELECT Id, NS_ID__c, NS_Estimate_ID__c, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Transaction_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Account.Price_Level__c, Email__c, Graphic_and_Sales_Notes__c, Production_Turn_Time__c,
                                     Warehouse_Notes__c, Did_I_Offer_A_Free_Sample__c, Customer_Service_Note__c, Partner__c, PO__c, Proofsheet_Finishing_Notes__c, CreatedBy.NS_ID__c, Use_Art_Files_from_other_orders__c, Art_file_by_email__c, In_Han_Date__c, Order_processed_By__c, Order_processed_By__r.NS_ID__c,
                                     Graphics_Designer__c, Blind_Ship__c, Ozlink__c,
                                     (SELECT Id, Sales_ID__c, Product2.NS_ID__c, Description, Quantity, NS_Price_Code__c, UnitPrice FROM OpportunityLineItems) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    partner = null;
                    orderDetail = null;
                    status = null;
                    pricelevel = null;
                    graphics = null;
                    if(customSettingMap.get('orderdetail') != null) for(NetsuiteOpp__c orderDetailValue : customSettingMap.get('orderdetail')) if(orderDetailValue.Value__c == oppRecord.Order_Detail__c) orderDetail = orderDetailValue.ID__c;
                    if(customSettingMap.get('partner') != null) for(NetsuiteOpp__c partnerValue : customSettingMap.get('partner')) if(partnerValue.Value__c == oppRecord.Partner__c) partner = partnerValue.ID__c;
                    if(customSettingMap.get('stage') != null) for(NetsuiteOpp__c statusValue : customSettingMap.get('stage')) if(statusValue.Value__c == oppRecord.StageName) status = statusValue.ID__c;
                    if(customSettingCustomerMap.get('pricelevel') != null) for(NetsuiteLead__c priceLevelValue : customSettingCustomerMap.get('pricelevel')) if(priceLevelValue.Value__c == oppRecord.Account.Price_Level__c) pricelevel = priceLevelValue.ID__c;
                    if(customSettingMap.get('graphics') != null) for(NetsuiteOpp__c graphicsValue : customSettingMap.get('graphics')) if(graphicsValue.Value__c == oppRecord.Graphics_Designer__c) graphics = graphicsValue.ID__c;
                    xmlBody = 
                        '<add>' +
                        '	<platformMsgs:record xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                        '		<tranSales:entity internalId="' + oppRecord.Account.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' + 
                        (oppRecord.Transaction_Date__c != null ? '<tranSales:tranDate>' + Datetime.newInstance(oppRecord.Transaction_Date__c.year(), oppRecord.Transaction_Date__c.month(), oppRecord.Transaction_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '</tranSales:tranDate>' : '') + 
                        //'		<tranSales:status>Pending Approval</tranSales:status>' + 
                        (oppRecord.Email__c != null ? '<tranSales:email>' + oppRecord.Email__c + '</tranSales:email>' : '') +
                        (oppRecord.Memo__c != null ? '<tranSales:memo>' + oppRecord.Memo__c + '</tranSales:memo>' : '') + 
                        (partner != null ? '<tranSales:partner internalId="' + partner +'" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                        '		<tranSales:otherRefNum>' + (oppRecord.PO__c != null ? oppRecord.PO__c : '') + '</tranSales:otherRefNum>' +
                        (oppRecord.NS_Estimate_ID__c != null ? '<tranSales:createdFrom internalId="' + oppRecord.NS_Estimate_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                        '		<tranSales:endDate>' + (oppRecord.In_Han_Date__c != null ? Datetime.newInstance(oppRecord.In_Han_Date__c.year(), oppRecord.In_Han_Date__c.month(), oppRecord.In_Han_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '') + '</tranSales:endDate>' +
                        '		<tranSales:itemList>';
                    for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                        xmlBody += 
                            '    		<tranSales:item>' +
                            '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            '        		<tranSales:expandItemGroup>false</tranSales:expandItemGroup>' +
                            '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                            '        		<tranSales:description>' + (oli.Description != null ? oli.Description : '') + '</tranSales:description>' +
                            '        		<tranSales:price internalId="' + oli.NS_Price_Code__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                            (!productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="' + (oli.NS_Price_Code__c != null ? oli.NS_Price_Code__c : (pricelevel != null ? pricelevel : '-1')) + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                            (productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="-1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" /><tranSales:rate>' + oli.UnitPrice + '</tranSales:rate>' : '') +
                            '    		</tranSales:item>';
                    }
                    xmlBody += 
                        '		</tranSales:itemList>' +
                        '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                        '			<platformCore:customField internalId="45" scriptId="custbody_orderstatus" xsi:type="platformCore:SelectCustomFieldRef">' +
                        '				<platformCore:value internalId="' + (status != null ? status : '2') + '" typeId="18" />' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="70" scriptId="custbody11" xsi:type="platformCore:SelectCustomFieldRef">' +
                        '				<platformCore:value internalId="' + (orderDetail != null ? orderDetail : '') + '" typeId="21" />' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Web_Order_Number__c != null ? oppRecord.Web_Order_Number__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="60" scriptId="custbody4" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Graphic_and_Sales_Notes__c != null ? oppRecord.Graphic_and_Sales_Notes__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6730" scriptId="custbodyproduction_turn_time" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Production_Turn_Time__c != null ? oppRecord.Production_Turn_Time__c : '') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="64" scriptId="custbody8" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Warehouse_Notes__c != null ? oppRecord.Warehouse_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="6720" scriptId="custbody107" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Did_I_Offer_A_Free_Sample__c != null ? (oppRecord.Did_I_Offer_A_Free_Sample__c ? 'true' : 'false') : 'false' ) + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4552" scriptId="custbody93" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Customer_Service_Note__c != null ? oppRecord.Customer_Service_Note__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="4580" scriptId="custbody_proofsheetfinishing" xsi:type="platformCore:StringCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Proofsheet_Finishing_Notes__c != null ? oppRecord.Proofsheet_Finishing_Notes__c : '') +'</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="5922" scriptId="custbody_art_file_exemption" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Use_Art_Files_from_other_orders__c != null ? (oppRecord.Use_Art_Files_from_other_orders__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="2149" scriptId="custbody_artfile_by_email" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Art_file_by_email__c != null ? (oppRecord.Art_file_by_email__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="76" scriptId="custbody13" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Blind_Ship__c != null ? (oppRecord.Blind_Ship__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        '			<platformCore:customField internalId="116" scriptId="custbody17" xsi:type="platformCore:BooleanCustomFieldRef">' +
                        '				<platformCore:value>' + (oppRecord.Ozlink__c != null ? (oppRecord.Ozlink__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                        '			</platformCore:customField>' +
                        (oppRecord.Order_processed_By__c != null && oppRecord.Order_processed_By__r.NS_ID__c != null ? '<platformCore:customField internalId="65" scriptId="custbody9" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ oppRecord.Order_processed_By__r.NS_ID__c +'" typeId="-4" /></platformCore:customField>' : '') +
                        (graphics != null ? '<platformCore:customField internalId="56" scriptId="custbody3" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ graphics +'" typeId="-4" /></platformCore:customField>' : '') +
                        '		</tranSales:customFieldList>' +
                        '	</platformMsgs:record>' +
                        '</add>';
                    
                    HTTPResponse response;
                    String xmlBodyResponse = '<?xml version="1.0" encoding="UTF-8"?>'+
                        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                            '<soapenv:Header>'+
                                '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                    '<platformMsgs:nsId>WEBSERVICES_1030411_01062021669751396118193960_cbf40b6a6cc52</platformMsgs:nsId>'+
                                '</platformMsgs:documentInfo>'+
                            '</soapenv:Header>'+
                            '<soapenv:Body>'+
                                '<getResponse xmlns="">'+
                                    '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                        '<platformMsgs:record internalId="7792583" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">'+
                                            '<tranSales:createdDate>2020-12-04T08:00:36.000-08:00</tranSales:createdDate>'+
                                            '<tranSales:customForm internalId="152" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>WS Sales Order - SCA (Preferred)</platformCore:name>'+
                                            '</tranSales:customForm>'+
                                            '<tranSales:entity internalId="243631" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>61208 TestingXperts</platformCore:name>'+
                                            '</tranSales:entity>'+
                                            '<tranSales:tranDate>2020-12-04T00:00:00.000-08:00</tranSales:tranDate>'+
                                            '<tranSales:tranId>SO-540086</tranSales:tranId>'+
                                            '<tranSales:source>Web Services</tranSales:source>'+
                                            '<tranSales:orderStatus>_cancelled</tranSales:orderStatus>'+
                                            '<tranSales:endDate>2020-12-19T00:00:00.000-08:00</tranSales:endDate>'+
                                            '<tranSales:memo>VOID</tranSales:memo>'+
                                            '<tranSales:toBePrinted>false</tranSales:toBePrinted>'+
                                            '<tranSales:toBeEmailed>false</tranSales:toBeEmailed>'+
                                            '<tranSales:toBeFaxed>false</tranSales:toBeFaxed>'+
                                            '<tranSales:shipIsResidential>false</tranSales:shipIsResidential>'+
                                            '<tranSales:shipAddressList internalId="782559" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>1000 main Street</platformCore:name>'+
                                            '</tranSales:shipAddressList>'+
                                            '<tranSales:isMultiShipTo>false</tranSales:isMultiShipTo>'+
                                            '<tranSales:shipComplete>false</tranSales:shipComplete>'+
                                            '<tranSales:saveOnAuthDecline>true</tranSales:saveOnAuthDecline>'+
                                            '<tranSales:canHaveStackable>true</tranSales:canHaveStackable>'+
                                            '<tranSales:ccApproved>false</tranSales:ccApproved>'+
                                            '<tranSales:isRecurringPayment>false</tranSales:isRecurringPayment>'+
                                            '<tranSales:subTotal>3006.0</tranSales:subTotal>'+
                                            '<tranSales:discountTotal>0.0</tranSales:discountTotal>'+
                                            '<tranSales:taxTotal>248.0</tranSales:taxTotal>'+
                                            '<tranSales:total>3254.0</tranSales:total>'+
                                            '<tranSales:balance>0.0</tranSales:balance>'+
                                            '<tranSales:paypalProcess>false</tranSales:paypalProcess>'+
                                            '<tranSales:subsidiary internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>Parent Company</platformCore:name>'+
                                            '</tranSales:subsidiary>'+
                                            '<tranSales:lastModifiedDate>2021-01-06T06:02:51.000-08:00</tranSales:lastModifiedDate>'+
                                            '<tranSales:status>Cancelled</tranSales:status>'+
                							'<tranSales:itemList>'+
                                                '<tranSales:item>'+
                                                    '<tranSales:item internalId="3668" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AF7X7GO2</platformCore:name>'+
                                                    '</tranSales:item>'+
                                                    '<tranSales:expandItemGroup>false</tranSales:expandItemGroup>'+
                                                    '<tranSales:lineUniqueKey>106092690</tranSales:lineUniqueKey>'+
                                                    '<tranSales:quantityOnHand>0.0</tranSales:quantityOnHand>'+
                                                    '<tranSales:quantity>10.0</tranSales:quantity>'+
                                                    '<tranSales:price internalId="6" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>WS Display</platformCore:name>'+
                                                    '</tranSales:price>'+
                                                    '<tranSales:rate>298.60</tranSales:rate>'+
                                                    '<tranSales:amount>2986.0</tranSales:amount>'+
                                                    '<tranSales:class internalId="11" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>Resort Extrusions</platformCore:name>'+
                                                    '</tranSales:class>'+
                                                    '<tranSales:location internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>California</platformCore:name>'+
                                                    '</tranSales:location>'+
                                                    '<tranSales:createWo>false</tranSales:createWo>'+
                                                    '<tranSales:isClosed>false</tranSales:isClosed>'+
                                                    '<tranSales:fromJob>false</tranSales:fromJob>'+
                                                    '<tranSales:excludeFromRateRequest>false</tranSales:excludeFromRateRequest>'+
                                                    '<tranSales:isEstimate>false</tranSales:isEstimate>'+
                                                    '<tranSales:line>466</tranSales:line>'+
                                                    '<tranSales:taxCode internalId="19388" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCore:name>AVATAX</platformCore:name>'+
                                                    '</tranSales:taxCode>'+
                                                    '<tranSales:taxRate1>8.25</tranSales:taxRate1>'+
                                                    '<tranSales:shipGroup>1</tranSales:shipGroup>'+
                                                    '<tranSales:itemIsFulfilled>false</tranSales:itemIsFulfilled>'+
                                                '</tranSales:item>'+
                                            '</tranSales:itemList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
                    if(Test.isRunningTest()){
                        response = new HttpResponse();
                        response.setStatusCode(200);
                        response.setBody(xmlBodyResponse);
                    }else{
                        response = NetsuiteConnection.postNetsuiteSoap('add',xmlBody,true);
                    }
                    if(response != null && response.getStatusCode() == 200){
                        String errorCode, errorString, errorSuccess;
                        if(String.isNotBlank(response.getBody())){
                            errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                            errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                            errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                        }
                        if((errorCode == null && errorString == null && errorSuccess == null) || 
                           (response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="salesOrder"') != null && response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="salesOrder"').trim() != '')){
                               oppRecord.Netsuite_To_Sync__c = false;
                               oppRecord.Netsuite_Sync_Status__c = 'Synced';
                               oppRecord.Netsuite_Sync_Error__c = '';
                               oppRecord.NS_ID__c = (!Test.isRunningTest() ? response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="salesOrder"') : '123');
                               if(oppRecord.NS_ID__c != null){
                                   if(oppRecord.StageName != 'Sales'){
                                       xmlBody = 
                                           '<update>' +
                                           '	<platformMsgs:record internalId="' + oppRecord.NS_ID__c + '" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                                           '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                                           '			<platformCore:customField internalId="45" scriptId="custbody_orderstatus" xsi:type="platformCore:SelectCustomFieldRef">' +
                                           '				<platformCore:value internalId="' + status + '" typeId="18" />' +
                                           '			</platformCore:customField>' +
                                           '		</tranSales:customFieldList>' +
                                           '	</platformMsgs:record>' +
                                           '</update>';
                                       
                                       HTTPResponse responseStatus = NetsuiteConnection.postNetsuiteSoap('update',xmlBody,false); 
                                   }                                
                                   xmlBody = '<get><baseRef internalId="' + oppRecord.NS_ID__c + '" type="salesOrder" xsi:type="platformCore:RecordRef"/></get>';
                                   if(!Test.isRunningTest()){
                                       response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
                                   }else{
                                       response = new HttpResponse();
                                       response.setStatusCode(200);
                                       response.setBody(xmlBodyResponse);
                                   }
                                   if(response != null && response.getStatusCode() == 200){
                                       oppRecord.Order__c = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'true' ? response.getBody().subStringBetween('<tranSales:tranId>','</tranSales:tranId>') : null;
                                       
                                       List<Dom.XmlNode> salesXML = NetsuiteMethods.XmlParser(response.getBody());
                                       for(Dom.XmlNode childElement1 : salesXML){
                                           if(childElement1.getName() == 'Body'){
                                               for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                                   for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                                       for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                                           if(childElement4.getName() == 'record'){
                                                               for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                                   if(childElement5.getName() == 'subTotal') oppRecord.Subtotal__c = Decimal.valueOf(childElement5.getText());
                                                                   if(childElement5.getName() == 'discountTotal') oppRecord.Discount_Total__c = Decimal.valueOf(childElement5.getText());
                                                                   if(childElement5.getName() == 'taxTotal') oppRecord.Tax_Total__c = Decimal.valueOf(childElement5.getText());
                                                                   if(childElement5.getName() == 'total') oppRecord.Total__c = Decimal.valueOf(childElement5.getText());
                                                                   if(childElement5.getName() == 'shipAddressList'){
                                                                       if(addressMap.get(childElement5.getAttribute('internalId',null)) != null) oppRecord.Shipping_Address__c = addressMap.get(childElement5.getAttribute('internalId',null));
                                                                   }
                                                                   if(childElement5.getName() == 'itemList'){
                                                                       for(Dom.XmlNode item : childElement5.getChildElements()){
                                                                           oliRecord = new OpportunityLineItem();
                                                                           for(Dom.XmlNode itemData : item.getChildElements()){
                                                                               if(itemData.getName() == 'item') oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                                               if(itemData.getName() == 'rate') oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                                               if(itemData.getName() == 'quantity') oliRecord.Quantity = Decimal.valueOf(itemData.getText());
                                                                               if(itemData.getName() == 'price') oliRecord.NS_Price_Code__c = itemData.getAttribute('internalId',null);
                                                                           }
                                                                           for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                                                                               if(oli.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                   if(oli.Sales_ID__c == null) oli.Sales_ID__c = oppRecord.NS_ID__c;
                                                                                   oli.UnitPrice = oliRecord.UnitPrice;
                                                                                   if(oli.NS_Price_Code__c == null) oli.NS_Price_Code__c = oliRecord.NS_Price_Code__c;
                                                                                   opportunityLineItemList.add(oli);
                                                                               }
                                                                           }
                                                                       }
                                                                   }
                                                               }
                                                           }
                                                       }
                                                   }
                                               }
                                           }
                                       }
                                   }
                               }
                           } else {
                               oppRecord.Netsuite_To_Sync__c = false;
                               oppRecord.Netsuite_Sync_Status__c = 'Error';
                               if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                           }
                    }else{
                        oppRecord.Netsuite_To_Sync__c = false;
                        oppRecord.Netsuite_Sync_Status__c = 'Error';
                        oppRecord.Netsuite_Sync_Error__c = response.getBody().substringBetween('<platformFaults:message>','</platformFaults:message>');
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
        ApexUtil.isOliTriggerInvoked = false;
        if(!opportunityList.isEmpty()) update opportunityList;
        if(!opportunityLineItemList.isEmpty()) update opportunityLineItemList;
    }
    
    @future(callout=true)
    public static void updateSale(Set<String> recordIds){
        Netsuite__c orgDefaults = Netsuite__c.getOrgDefaults();
        Set<String> productsExceptions = new Set<String>();
        for(String od : orgDefaults.Products_Exception__c.split(',')) productsExceptions.add(od);
        
        Map<String,List<NetsuiteOpp__c>> customSettingMap = new Map<String,List<NetsuiteOpp__c>>();
        List<NetsuiteOpp__c> listAux;
        for(NetsuiteOpp__c nl : NetsuiteOpp__c.getall().values()){
            listAux = customSettingMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteOpp__c>();
            listAux.add(nl);
            customSettingMap.put(nl.Type__c.trim().toLowerCase(),listAux.clone());
        }
        
        Map<String,List<NetsuiteLead__c>> customSettingCustomerMap = new Map<String,List<NetsuiteLead__c>>();
        List<NetsuiteLead__c> listCustomerAux;
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()){
            listCustomerAux = customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) != null ? customSettingCustomerMap.get(nl.Type__c.trim().toLowerCase()) : new List<NetsuiteLead__c>();
            listCustomerAux.add(nl);
            customSettingCustomerMap.put(nl.Type__c.trim().toLowerCase(),listCustomerAux.clone());
        }
        
        Set<String> customerIds = new Set<String>();
        for(Opportunity oppRecord : [SELECT Id, AccountId, Account.NS_ID__c FROM Opportunity WHERE Id IN: recordIds]) if(oppRecord.Account.NS_ID__c != null) customerIds.add(oppRecord.Account.NS_ID__c);
        Map<String,String> addressMap = new Map<String,String>();
        for(Address__c a : [SELECT Id, NS_ID__c FROM Address__c WHERE Customer__r.NS_ID__c IN: customerIds]) if(a.NS_ID__c != null) addressMap.put(a.Id,a.NS_ID__c);
        
        List<Opportunity> opportunityList = new List<Opportunity>();
        List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
        Map<String,Product2> productMap = new Map<String,Product2>();
        OpportunityLineItem oliRecord;
        String status, pricelevel, xmlBody, graphics;
        Boolean haveProduct;
        for(Opportunity oppRecord : [SELECT Id, NS_ID__c, Shipping_Address__c, Order_Detail__c, Web_Order_Number__c, CloseDate, StageName, Transaction_Date__c, Estimate_Expiration_Date__c, Memo__c, AccountId, Account.NS_ID__c, Account.Price_Level__c, Email__c, Graphic_and_Sales_Notes__c, Production_Turn_Time__c,
                                     Warehouse_Notes__c, Did_I_Offer_A_Free_Sample__c, Customer_Service_Note__c, Partner__c, PO__c, Proofsheet_Finishing_Notes__c, CreatedBy.NS_ID__c, Art_file_by_email__c, Use_Art_Files_from_other_orders__c, In_Han_Date__c,
                                     Order_processed_By__c, Order_processed_By__r.NS_ID__c, Graphics_Designer__c, Blind_Ship__c, Ozlink__c,
                                     (SELECT Id, Product2.NS_ID__c, NS_ID__c, Description, Quantity, NS_Price_Code__c, UnitPrice FROM OpportunityLineItems ORDER BY CreatedDate ASC) FROM Opportunity WHERE Id IN: recordIds]){
            if(oppRecord.AccountId != null && oppRecord.Account.NS_ID__c != null){
                if(oppRecord.OpportunityLineItems != null && !oppRecord.OpportunityLineItems.isEmpty()){
                    status = null;
                    pricelevel = null;
                    graphics = null;
                    if(customSettingMap.get('stage') != null) for(NetsuiteOpp__c statusValue : customSettingMap.get('stage')) if(statusValue.Value__c == oppRecord.StageName) status = statusValue.ID__c;
                    if(customSettingCustomerMap.get('pricelevel') != null) for(NetsuiteLead__c priceLevelValue : customSettingCustomerMap.get('pricelevel')) if(priceLevelValue.Value__c == oppRecord.Account.Price_Level__c) pricelevel = priceLevelValue.ID__c;
                    if(customSettingMap.get('graphics') != null) for(NetsuiteOpp__c graphicsValue : customSettingMap.get('graphics')) if(graphicsValue.Value__c == oppRecord.Graphics_Designer__c) graphics = graphicsValue.ID__c;
                    if(status != null){
                        xmlBody = 
                            '<update>' +
                            '	<platformMsgs:record internalId="' + oppRecord.NS_ID__c + '" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">' + 
                            (oppRecord.Shipping_Address__c != null && addressMap.get(oppRecord.Shipping_Address__c) != null ? '<tranSales:shipAddressList internalId="' + addressMap.get(oppRecord.Shipping_Address__c) + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                            '		<tranSales:endDate>' + (oppRecord.In_Han_Date__c != null ? Datetime.newInstance(oppRecord.In_Han_Date__c.year(), oppRecord.In_Han_Date__c.month(), oppRecord.In_Han_Date__c.day()).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') : '') + '</tranSales:endDate>' +
                            '		<tranSales:itemList>';
                        for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                            xmlBody += 
                                '    		<tranSales:item>' +
                                '        		<tranSales:item internalId="' + oli.Product2.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' +
                                '        		<tranSales:quantity>' + oli.Quantity + '</tranSales:quantity>' +
                                '        		<tranSales:description>' + (oli.Description != null ? oli.Description : '') + '</tranSales:description>' +
                                (!productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="' + (oli.NS_Price_Code__c != null ? oli.NS_Price_Code__c : (pricelevel != null ? pricelevel : '-1')) + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                                (productsExceptions.contains(oli.Product2.NS_ID__c) ? '<tranSales:price internalId="-1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" /><tranSales:rate>' + oli.UnitPrice + '</tranSales:rate>' : '') +
                                '    		</tranSales:item>';
                        }
                        xmlBody += 
                            '		</tranSales:itemList>' +
                            '		<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                            '			<platformCore:customField internalId="45" scriptId="custbody_orderstatus" xsi:type="platformCore:SelectCustomFieldRef">' +
                            '				<platformCore:value internalId="' + status + '" typeId="18" />' +
                            '			</platformCore:customField>' +
                            '			<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">' +
                            '				<platformCore:value>' + (oppRecord.Web_Order_Number__c != null ? oppRecord.Web_Order_Number__c : '') + '</platformCore:value>' +
                            '			</platformCore:customField>' +
                            '			<platformCore:customField internalId="5922" scriptId="custbody_art_file_exemption" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '				<platformCore:value>' + (oppRecord.Use_Art_Files_from_other_orders__c != null ? (oppRecord.Use_Art_Files_from_other_orders__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                        	'			</platformCore:customField>' +
                            '			<platformCore:customField internalId="2149" scriptId="custbody_artfile_by_email" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '				<platformCore:value>' + (oppRecord.Art_file_by_email__c != null ? (oppRecord.Art_file_by_email__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                            '			</platformCore:customField>' +
                            '			<platformCore:customField internalId="76" scriptId="custbody13" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '				<platformCore:value>' + (oppRecord.Blind_Ship__c != null ? (oppRecord.Blind_Ship__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                            '			</platformCore:customField>' +
                            '			<platformCore:customField internalId="116" scriptId="custbody17" xsi:type="platformCore:BooleanCustomFieldRef">' +
                            '				<platformCore:value>' + (oppRecord.Ozlink__c != null ? (oppRecord.Ozlink__c ? 'true' : 'false') : 'false') + '</platformCore:value>' +
                            '			</platformCore:customField>' +
                            (oppRecord.Order_processed_By__c != null && oppRecord.Order_processed_By__r.NS_ID__c != null ? '<platformCore:customField internalId="65" scriptId="custbody9" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ oppRecord.Order_processed_By__r.NS_ID__c +'" typeId="-4" /></platformCore:customField>' : '') +
                            (graphics != null ? '<platformCore:customField internalId="56" scriptId="custbody3" xsi:type="platformCore:SelectCustomFieldRef"><platformCore:value internalId="'+ graphics +'" typeId="-4" /></platformCore:customField>' : '') +
                            '		</tranSales:customFieldList>' +
                            '	</platformMsgs:record>' +
                            '</update>';
                        
                        HTTPResponse response;
                        String xmlBodyResponse = '<?xml version="1.0" encoding="UTF-8"?>'+
                            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                                '<soapenv:Header>'+
                                    '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformMsgs:nsId>WEBSERVICES_1030411_01062021669751396118193960_cbf40b6a6cc52</platformMsgs:nsId>'+
                                    '</platformMsgs:documentInfo>'+
                                '</soapenv:Header>'+
                                '<soapenv:Body>'+
                                    '<getResponse xmlns="">'+
                                        '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                            '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                            '<platformMsgs:record internalId="7792583" xsi:type="tranSales:SalesOrder" xmlns:tranSales="urn:sales_2020_1.transactions.webservices.netsuite.com">'+
                                                '<tranSales:createdDate>2020-12-04T08:00:36.000-08:00</tranSales:createdDate>'+
                                                '<tranSales:customForm internalId="152" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                    '<platformCore:name>WS Sales Order - SCA (Preferred)</platformCore:name>'+
                                                '</tranSales:customForm>'+
                                                '<tranSales:entity internalId="243631" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                    '<platformCore:name>61208 TestingXperts</platformCore:name>'+
                                                '</tranSales:entity>'+
                                                '<tranSales:tranDate>2020-12-04T00:00:00.000-08:00</tranSales:tranDate>'+
                                                '<tranSales:tranId>SO-540086</tranSales:tranId>'+
                                                '<tranSales:source>Web Services</tranSales:source>'+
                                                '<tranSales:orderStatus>_cancelled</tranSales:orderStatus>'+
                                                '<tranSales:endDate>2020-12-19T00:00:00.000-08:00</tranSales:endDate>'+
                                                '<tranSales:memo>VOID</tranSales:memo>'+
                                                '<tranSales:toBePrinted>false</tranSales:toBePrinted>'+
                                                '<tranSales:toBeEmailed>false</tranSales:toBeEmailed>'+
                                                '<tranSales:toBeFaxed>false</tranSales:toBeFaxed>'+
                                                '<tranSales:shipIsResidential>false</tranSales:shipIsResidential>'+
                                                '<tranSales:shipAddressList internalId="782559" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                    '<platformCore:name>1000 main Street</platformCore:name>'+
                                                '</tranSales:shipAddressList>'+
                                                '<tranSales:isMultiShipTo>false</tranSales:isMultiShipTo>'+
                                                '<tranSales:shipComplete>false</tranSales:shipComplete>'+
                                                '<tranSales:saveOnAuthDecline>true</tranSales:saveOnAuthDecline>'+
                                                '<tranSales:canHaveStackable>true</tranSales:canHaveStackable>'+
                                                '<tranSales:ccApproved>false</tranSales:ccApproved>'+
                                                '<tranSales:isRecurringPayment>false</tranSales:isRecurringPayment>'+
                                                '<tranSales:subTotal>3006.0</tranSales:subTotal>'+
                                                '<tranSales:discountTotal>0.0</tranSales:discountTotal>'+
                                                '<tranSales:taxTotal>248.0</tranSales:taxTotal>'+
                                                '<tranSales:total>3254.0</tranSales:total>'+
                                                '<tranSales:balance>0.0</tranSales:balance>'+
                                                '<tranSales:paypalProcess>false</tranSales:paypalProcess>'+
                                                '<tranSales:subsidiary internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                    '<platformCore:name>Parent Company</platformCore:name>'+
                                                '</tranSales:subsidiary>'+
                                                '<tranSales:lastModifiedDate>2021-01-06T06:02:51.000-08:00</tranSales:lastModifiedDate>'+
                                                '<tranSales:status>Cancelled</tranSales:status>'+
                                                '<tranSales:itemList>'+
                                                    '<tranSales:item>'+
                                                        '<tranSales:item internalId="3668" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                            '<platformCore:name>AF7X7GO2</platformCore:name>'+
                                                        '</tranSales:item>'+
                                                        '<tranSales:expandItemGroup>false</tranSales:expandItemGroup>'+
                                                        '<tranSales:lineUniqueKey>106092690</tranSales:lineUniqueKey>'+
                                                        '<tranSales:quantityOnHand>0.0</tranSales:quantityOnHand>'+
                                                        '<tranSales:quantity>10.0</tranSales:quantity>'+
                                                        '<tranSales:price internalId="6" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                            '<platformCore:name>WS Display</platformCore:name>'+
                                                        '</tranSales:price>'+
                                                        '<tranSales:rate>298.60</tranSales:rate>'+
                                                        '<tranSales:amount>2986.0</tranSales:amount>'+
                                                        '<tranSales:class internalId="11" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                            '<platformCore:name>Resort Extrusions</platformCore:name>'+
                                                        '</tranSales:class>'+
                                                        '<tranSales:location internalId="1" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                            '<platformCore:name>California</platformCore:name>'+
                                                        '</tranSales:location>'+
                                                        '<tranSales:createWo>false</tranSales:createWo>'+
                                                        '<tranSales:isClosed>false</tranSales:isClosed>'+
                                                        '<tranSales:fromJob>false</tranSales:fromJob>'+
                                                        '<tranSales:excludeFromRateRequest>false</tranSales:excludeFromRateRequest>'+
                                                        '<tranSales:isEstimate>false</tranSales:isEstimate>'+
                                                        '<tranSales:line>466</tranSales:line>'+
                                                        '<tranSales:taxCode internalId="19388" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                            '<platformCore:name>AVATAX</platformCore:name>'+
                                                        '</tranSales:taxCode>'+
                                                        '<tranSales:taxRate1>8.25</tranSales:taxRate1>'+
                                                        '<tranSales:shipGroup>1</tranSales:shipGroup>'+
                                                        '<tranSales:itemIsFulfilled>false</tranSales:itemIsFulfilled>'+
                                                    '</tranSales:item>'+
                                                '</tranSales:itemList>'+
                                            '</platformMsgs:record>'+
                                        '</platformMsgs:readResponse>'+
                                    '</getResponse>'+
                                '</soapenv:Body>'+
                            '</soapenv:Envelope>';
                        if(Test.isRunningTest()){
                            response = new HttpResponse();
                            response.setStatusCode(200);
                            response.setBody(xmlBodyResponse);
                        }else{
                            response = NetsuiteConnection.postNetsuiteSoap('update',xmlBody,false);
                        }
                        oppRecord.Update_Items__c = false;
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
                                
                                if(oppRecord.NS_ID__c != null){
                                    xmlBody = '<get><baseRef internalId="' + oppRecord.NS_ID__c + '" type="salesOrder" xsi:type="platformCore:RecordRef"/></get>';
                                    if(!Test.isRunningTest()){
                                        response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
                                    }else{
                                        response = new HttpResponse();
                                        response.setStatusCode(200);
                                        response.setBody(xmlBodyResponse);
                                    }
                                    if(response != null && response.getStatusCode() == 200){
                                        List<Dom.XmlNode> salesOrderXML = NetsuiteMethods.XmlParser(response.getBody());
                                        String salesOrderId;
                                        for(Dom.XmlNode childElement1 : salesOrderXML){
                                            if(childElement1.getName() == 'Body'){
                                                for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                                    for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                                        for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                                            if(childElement4.getName() == 'record'){
                                                                salesOrderId = childElement4.getAttribute('internalId',null);
                                                                for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                                    if(childElement5.getName() == 'subTotal') oppRecord.Subtotal__c = Decimal.valueOf(childElement5.getText());
                                                                    if(childElement5.getName() == 'discountTotal') oppRecord.Discount_Total__c = Decimal.valueOf(childElement5.getText());
                                                                    if(childElement5.getName() == 'taxTotal') oppRecord.Tax_Total__c = Decimal.valueOf(childElement5.getText());
                                                                    if(childElement5.getName() == 'total') oppRecord.Total__c = Decimal.valueOf(childElement5.getText());
                                                                    if(childElement5.getName() == 'shipAddressList'){
                                                                        if(addressMap.get(childElement5.getAttribute('internalId',null)) != null) oppRecord.Shipping_Address__c = addressMap.get(childElement5.getAttribute('internalId',null));
                                                                    }
                                                                    if(childElement5.getName() == 'itemList'){
                                                                        for(Dom.XmlNode item : childElement5.getChildElements()){
                                                                            oliRecord = new OpportunityLineItem();
                                                                            oliRecord.Opportunity = new Opportunity(NS_ID__c = salesOrderId);
                                                                            oliRecord.Sales_ID__c = oppRecord.NS_ID__c;
                                                                            for(Dom.XmlNode itemData : item.getChildElements()){
                                                                                if(itemData.getName() == 'item'){
                                                                                    oliRecord.Item_ID__c = itemData.getAttribute('internalId',null);
                                                                                    haveProduct = false;
                                                                                    for(OpportunityLineItem oliAux : oppRecord.OpportunityLineItems){
                                                                                        if(oliAux.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                            oliRecord.Id = oliAUx.Id; haveProduct = true; break;
                                                                                        }
                                                                                    }
                                                                                    if(!haveProduct){
                                                                                        for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                                            if(itemDataDetail.getName() == 'name'){
                                                                                                productMap.put(itemData.getAttribute('internalId',null),new Product2(Name = itemDataDetail.getText(),isActive = true,NS_ID__c = itemData.getAttribute('internalId',null)));
                                                                                            }
                                                                                        }
                                                                                    }
                                                                                }
                                                                                if(itemData.getName() == 'lineUniqueKey') oliRecord.NS_ID__c = itemData.getText();
                                                                                if(itemData.getName() == 'rate') oliRecord.UnitPrice = Decimal.valueOf(itemData.getText());
                                                                                if(itemData.getName() == 'quantity') oliRecord.Quantity = Decimal.valueOf(itemData.getText());
                                                                                if(itemData.getName() == 'price'){
                                                                                    oliRecord.NS_Price_Code__c = itemData.getAttribute('internalId',null);
                                                                                    for(Dom.XmlNode itemDataDetail : itemData.getChildElements()){
                                                                                        if(itemDataDetail.getName() == 'name'){
                                                                                            oliRecord.Price_Level__c = itemDataDetail.getText();
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                            for(OpportunityLineItem oli : oppRecord.OpportunityLineItems){
                                                                                if(oli.Product2.NS_ID__c == oliRecord.Item_ID__c){
                                                                                    oli.UnitPrice = oliRecord.UnitPrice;
                                                                                    oli.NS_Price_Code__c = oliRecord.NS_Price_Code__c;
                                                                                    opportunityLineItemList.add(oli);
                                                                                }
                                                                            }                                                                            
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                oppRecord.Netsuite_To_Sync__c = false;
                                oppRecord.Netsuite_Sync_Status__c = 'Error';
                                if(errorSuccess != null) oppRecord.Netsuite_Sync_Error__c = errorSuccess.left(255); else oppRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
                            }
                        }else{
                            oppRecord.Netsuite_To_Sync__c = false;
                            oppRecord.Netsuite_Sync_Status__c = 'Error';
                            oppRecord.Netsuite_Sync_Error__c = response.getBody().substringBetween('<platformFaults:message>','</platformFaults:message>');
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
        ApexUtil.isOliTriggerInvoked = false;
        if(!opportunityList.isEmpty()){
            List<Database.saveResult> updateResults = Database.update(opportunityList,false);
            for(Database.saveResult updateResult : updateResults) {
                if(!updateResult.isSuccess()){
                    for(Database.Error err : updateResult.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        if(!opportunityLineItemList.isEmpty()){
            List<Database.upsertResult> uResults;
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
                //upsert pbeMap.values();
                uResults = Database.upsert(pbeMap.values(),false);
                for(Database.upsertResult result : uResults) {
                    if(!result.isSuccess()){
                        for(Database.Error err : result.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                    }
                }
            } 
            
            for(OpportunityLineItem oliu : opportunityLineItemList){
                if(oliu.Id == null && pbeMap.get(oliu.Item_ID__c) != null) oliu.PricebookEntryId = pbeMap.get(oliu.Item_ID__c).Id;
            }
            uResults = Database.upsert(opportunityLineItemList,false);
            for(Database.upsertResult result : uResults) {
                if(!result.isSuccess()){
                    for(Database.Error err : result.getErrors()) system.debug(err.getStatusCode() + ': ' + err.getMessage() + '. ' + 'Fields that affected this error: ' + err.getFields());
                }
            }    
        }
    }
    
    @future(callout=true)
	public static void upsertCustomer(Set<String> recordIds){
        Map<String,Object> customSettingMap = new Map<String,Object>();
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
        
        Map<String,List<Address__c>> addressMap = new Map<String,List<Address__c>>();
        List<Address__c> auxList;
        for(Address__c a : [SELECT Id, NS_ID__c, Customer__c, Address_1__c, Address_2__c, Addressee__c, Attention__c, City__c, Country__c, Default_Billing__c, Default_Shipping__c, Phone__c, State__c, Zip__c FROM Address__c WHERE Customer__c IN: recordIds]){
            if(addressMap.get(a.Customer__c) != null) auxList = addressMap.get(a.Customer__c); else auxList = new List<Address__c>();
            auxList.add(a);
            addressMap.put(a.Customer__c,auxList);
        }
        
        List<Account> accountList = new List<Account>();
        String xmlBody;
        HTTPResponse response;
        String prefCcProcessorXML, entityStatusXML, typeCustomerXML, priceLevelXML, associationXML, partnerXML, approvalXML, termsXML, taxItemXML, certificateXML, dedicatedXML, didYourHearXML, didYourHearTradeXML, salesRepXML, errorCode, errorString, errorSuccess;
        Address__c addressAux;
        List<Address__c> addressListAux;
        List<Address__c> addressUpdateList = new List<Address__c>();
        for(Account accountRecord : [SELECT Id, NS_ID__c, Name, Phone, Office_Phone__c, Website, Email__c, Fax, Alt_Contact__c, Alt_Email__c, CC_Processor__c, Netsuite_Status__c, Type_of_Customer__c, Price_Level__c, Partner__c, Association__c, Sales_Order_Notes__c, Address_1__c, Address_2__c, 
                                     Attention_Address__c, Address_Phone__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Annual_Revenue__c, Account_Approval_Process__c, ASI__c, ASI_Number__c, Credit_Limit__c, Tax_Number__c,
                                     Terms__c, Tax_Item__c, Resale_Number__c, Resale_Cert_File_Path__c, Certificate_Approved_By__c, Dedicated_Resort_Extrusion_Rep__c, How_Did_You_Hear__c, How_Did_You_Hear_Trade_Shows__c, Sale_Rep__c FROM Account WHERE Id IN: recordIds]){
                                         prefCcProcessorXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.CC_Processor__c, 'prefCCProcessor', 'listRel');
                                         entityStatusXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Netsuite_Status__c, 'entityStatus', 'listRel'); 
                                         priceLevelXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Price_Level__c, 'priceLevel', 'listRel');
                                         partnerXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Partner__c, 'partner', 'listRel');
                                         typeCustomerXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Type_of_Customer__c, 'custentity_typeofcustomer', '44', '-186');
                                         associationXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Association__c, 'custentity2', '38', '13');
                                         approvalXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Account_Approval_Process__c, 'custentity_ws_accnt_aprvl_prcs', '5927', '805');
                                         termsXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Terms__c, 'terms', 'listRel');
                                         taxItemXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Tax_Item__c, 'taxItem', 'listRel');
                                         certificateXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Certificate_Approved_By__c, 'custentitycustentity_certificate_app_by', '2333', '-4');
                                         dedicatedXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.Dedicated_Resort_Extrusion_Rep__c, 'custentity45', '2712', '-4');
                                         didYourHearXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.How_Did_You_Hear__c, 'custentitylead_survey', '1663', '288');
                                         didYourHearTradeXML = ApexUtil.getFieldSettingCustomSelectNetsuiteXML('customer',customSettingMap,accountRecord.How_Did_You_Hear_Trade_Shows__c, 'custentitylead_survey_tradeshow_value', '1665', '289');
                                         salesRepXML = ApexUtil.getFieldSettingNetsuiteXML('customer',customSettingMap,accountRecord.Sale_Rep__c, 'salesRep', 'listRel');
                                         xmlBody = 
                                             '<'+ (accountRecord.NS_ID__c == null ? 'add' : 'update') +'>' +
                                             (accountRecord.NS_ID__c == null ? '<platformMsgs:record xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' : '<platformMsgs:record internalId="' + accountRecord.NS_ID__c + '" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">') +
                                             '		<listRel:companyName>' + accountRecord.Name + '</listRel:companyName>' +
                                             '		<listRel:phone>' + (accountRecord.Phone != null ? accountRecord.Phone : '') + '</listRel:phone>' +
                                             '		<listRel:altPhone>' + (accountRecord.Office_Phone__c != null ? accountRecord.Office_Phone__c : '') + '</listRel:altPhone>' +
                                             '		<listRel:fax>' + (accountRecord.Fax != null ? accountRecord.Fax : '') + '</listRel:fax>' +
                                             '		<listRel:email>' + (accountRecord.Email__c != null ? accountRecord.Email__c : '') + '</listRel:email>' +
                                             '		<listRel:url>' + (accountRecord.Website != null ? accountRecord.Website : '') + '</listRel:url>' +
                                             '		<listRel:vatRegNumber>' + (accountRecord.Tax_Number__c != null ? accountRecord.Tax_Number__c : '') + '</listRel:vatRegNumber>' +
                                             '		<listRel:resaleNumber>' + (accountRecord.Resale_Number__c != null ? accountRecord.Resale_Number__c : '') + '</listRel:resaleNumber>' +
                                             (accountRecord.Credit_Limit__c != null ? '<listRel:creditLimit>' + accountRecord.Credit_Limit__c + '</listRel:creditLimit>' : '') +
                                             prefCcProcessorXML +
                                             entityStatusXML +
                                             priceLevelXML +
                                             partnerXML +
                                             termsXML +
                                             taxItemXML +
                                             salesRepXML;
                                         if(addressMap.get(accountRecord.Id) != null){
                                             xmlBody += '<listRel:addressbookList>';
                                             for(Address__c aRecord : addressMap.get(accountRecord.Id)){
                                                 xmlBody += '<listRel:addressbook>' +
                                                     '		<listRel:defaultShipping>' + (aRecord.Default_Shipping__c == true ? 'true' : 'false') + '</listRel:defaultShipping>' +
                                                     '		<listRel:defaultBilling>' + (aRecord.Default_Billing__c == true ? 'true' : 'false') + '</listRel:defaultBilling>' +
                                                     '		<listRel:addressbookAddress xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com">' +
                                                     '			<platformCommon:country>' + (aRecord.Country__c == 'US' ? '_unitedStates' : (aRecord.Country__c != null ? '_' + aRecord.Country__c.toLowerCase().subString(0,1) + aRecord.Country__c.subString(1,aRecord.Country__c.length()).replace(' ','').replace('(','').replace(')','') : '')) + '</platformCommon:country>' +
                                                     '			<platformCommon:attention>' + (aRecord.Attention__c != null ? aRecord.Attention__c : '') + '</platformCommon:attention>' +
                                                     '			<platformCommon:addressee>' + (aRecord.Addressee__c != null ? aRecord.Addressee__c : '') + '</platformCommon:addressee>' +
                                                     '			<platformCommon:addrPhone>' + (aRecord.Phone__c != null ? aRecord.Phone__c : '') + '</platformCommon:addrPhone>' +
                                                     '			<platformCommon:addr1>' + (aRecord.Address_1__c != null ? aRecord.Address_1__c : '') + '</platformCommon:addr1>' +
                                                     '			<platformCommon:addr2>' + (aRecord.Address_2__c != null ? aRecord.Address_2__c : '') + '</platformCommon:addr2>' +
                                                     '			<platformCommon:city>' + (aRecord.City__c != null ? aRecord.City__c : '') + '</platformCommon:city>' +
                                                     '			<platformCommon:state>' + (aRecord.State__c != null ? aRecord.State__c : '') + '</platformCommon:state>' +
                                                     '			<platformCommon:zip>' + (aRecord.Zip__c != null ? aRecord.Zip__c : '') + '</platformCommon:zip>' +
                                                     //'			<platformCommon:override>false</platformCommon:override>' +
                                                     '		</listRel:addressbookAddress>' +
                                                     (aRecord.NS_ID__c != null ? '<listRel:internalId>' + aRecord.NS_ID__c + '</listRel:internalId>' : '') +
                                                     '	</listRel:addressbook>';
                                             }
                                             xmlBody += '</listRel:addressbookList>';
                                         }
                                         xmlBody += '		<listRel:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                                             typeCustomerXML +
                                             (accountRecord.Association__c != null ? associationXML : '') +
                                             (accountRecord.Account_Approval_Process__c != null ? approvalXML : '') +
                                             (accountRecord.Certificate_Approved_By__c != null ? certificateXML : '') +
                                             (accountRecord.Dedicated_Resort_Extrusion_Rep__c != null ? dedicatedXML : '') +
                                             (accountRecord.How_Did_You_Hear__c != null ? didYourHearXML : '') +
                                             (accountRecord.How_Did_You_Hear_Trade_Shows__c != null ? didYourHearTradeXML : '') +
                                             '			<platformCore:customField internalId="2708" scriptId="custentitysalesordernotes" xsi:type="platformCore:StringCustomFieldRef">' + 
                                             '				<platformCore:value>' + (accountRecord.Sales_Order_Notes__c != null ? accountRecord.Sales_Order_Notes__c : '') + '</platformCore:value>' + 
                                             '			</platformCore:customField>' +
                                             '			<platformCore:customField internalId="5734" scriptId="custentity_invoice_email" xsi:type="platformCore:StringCustomFieldRef">' +
                                             '				<platformCore:value>' + (accountRecord.Alt_Contact__c != null ? accountRecord.Alt_Contact__c : '') + '</platformCore:value>' +
                                             '			</platformCore:customField>' +
                                             '			<platformCore:customField internalId="5988" scriptId="custentity_order_conf_email" xsi:type="platformCore:StringCustomFieldRef">' +
                                             '				<platformCore:value>' + (accountRecord.Alt_Email__c != null ? accountRecord.Alt_Email__c : '') + '</platformCore:value>' +
                                             '			</platformCore:customField>' +
                                             (accountRecord.Annual_Revenue__c != null ? '<platformCore:customField internalId="17" scriptId="custentity_esc_annual_revenue" xsi:type="platformCore:DoubleCustomFieldRef"><platformCore:value>' + String.valueOf(accountRecord.Annual_Revenue__c) + '</platformCore:value></platformCore:customField>' : '') +
                                             (accountRecord.ASI__c != null ? '<platformCore:customField internalId="1231" scriptId="custentity9" xsi:type="platformCore:BooleanCustomFieldRef"><platformCore:value>' + (accountRecord.ASI__c ? 'true' : 'false') + '</platformCore:value></platformCore:customField>' : '') +
                                             (accountRecord.ASI_Number__c != null ? '<platformCore:customField internalId="1247" scriptId="custentity25" xsi:type="platformCore:StringCustomFieldRef"><platformCore:value>' + accountRecord.ASI_Number__c + '</platformCore:value></platformCore:customField>' : '') +
                                             '			<platformCore:customField internalId="2702" scriptId="custentity_resale_cert_newuser" xsi:type="platformCore:StringCustomFieldRef">' +
                                             '				<platformCore:value>' + (accountRecord.Resale_Cert_File_Path__c != null ? accountRecord.Resale_Cert_File_Path__c : '') + '</platformCore:value>' +
                                             '			</platformCore:customField>' +
                                             '		</listRel:customFieldList>' + 
                                             '	</platformMsgs:record>' +
                                             '</' + (accountRecord.NS_ID__c == null ? 'add' : 'update') +'>';
                                         
                                         response = NetsuiteConnection.postNetsuiteSoap((accountRecord.NS_ID__c == null ? 'add' : 'update'),xmlBody,true);
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
                                             accountRecord.NS_ID__c = (!Test.isRunningTest() ? response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="customer"') : '123');
                                             
                                             if(addressMap.get(accountRecord.Id) != null && accountRecord.NS_ID__c != null){
                                                 xmlBody = '<get><baseRef internalId="' + accountRecord.NS_ID__c + '" type="customer" xsi:type="platformCore:RecordRef"/></get>';
                                                 response = NetsuiteConnection.postNetsuiteSoap('get',xmlBody,true);
                                                 if(response != null && response.getStatusCode() == 200){
                                                     if(String.isNotBlank(response.getBody())){
                                                         errorCode =  response.getBody().substringBetween('<faultcode>', '</faultcode>');
                                                         errorString = response.getBody().substringBetween('<faultstring>', '</faultstring>');
                                                         errorSuccess = response.getBody().substringBetween('<platformCore:status isSuccess="', '"') == 'false' ? response.getBody().substringBetween('<platformCore:message>', '</platformCore:message>') : null;
                                                     }
                                                     if(errorCode == null && errorString == null && errorSuccess == null){
                                                         List<Dom.XmlNode> customerData = NetsuiteMethods.XmlParser(response.getBody());
                                                         for(Dom.XmlNode childElement1 : customerData){
                                                             if(childElement1.getName() == 'Body'){
                                                                 for(Dom.XmlNode childElement2 : childElement1.getChildElements()){
                                                                     for(Dom.XmlNode childElement3 : childElement2.getChildElements()){
                                                                         for(Dom.XmlNode childElement4 : childElement3.getChildElements()){
                                                                             if(childElement4.getName() == 'record'){
                                                                                 for(Dom.XmlNode childElement5 : childElement4.getChildElements()){
                                                                                     if(childElement5.getName() == 'addressbookList'){
                                                                                         addressListAux = new List<Address__c>();
                                                                                         for(Dom.XmlNode childElement6 : childElement5.getChildElements()){
                                                                                             if(childElement6.getName() == 'addressbook'){
                                                                                                 addressAux = new Address__c();
                                                                                                 for(Dom.XmlNode childElement7 : childElement6.getChildElements()){
                                                                                                     if(childElement7.getName() == 'defaultShipping') addressAux.Default_Shipping__c = Boolean.valueOf(childElement7.getText());
                                                                                                     if(childElement7.getName() == 'defaultBilling') addressAux.Default_Billing__c = Boolean.valueOf(childElement7.getText());
                                                                                                     if(childElement7.getName() == 'addressbookAddress'){
                                                                                                         for(Dom.XmlNode childElement8 : childElement7.getChildElements()){
                                                                                                             if(childElement8.getName() == 'attention') addressAux.Attention__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'city') addressAux.City__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'state') addressAux.State__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'addr1') addressAux.Address_1__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'addr2') addressAux.Address_2__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'addrPhone') addressAux.Phone__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'addressee') addressAux.Addressee__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'zip') addressAux.Zip__c = childElement8.getText();
                                                                                                             if(childElement8.getName() == 'country') addressAux.Country__c = childElement8.getText();
                                                                                                         }
                                                                                                     }
                                                                                                     if(childElement7.getName() == 'internalId') addressAux.NS_ID__c = childElement7.getText();
                                                                                                 }
                                                                                                 if(addressAux.Default_Shipping__c){
                                                                                                     accountRecord.ShippingStreet = addressAux.Address_1__c;
                                                                                                     accountRecord.ShippingState = addressAux.State__c;
                                                                                                     accountRecord.ShippingCity = addressAux.City__c;
                                                                                                     accountRecord.ShippingPostalCode = addressAux.Zip__c;
                                                                                                     accountRecord.ShippingCountry = (addressAux.Country__c != null ? (addressAux.Country__c == '_unitedStates' ? 'United States' : addressAux.Country__c.replace('_','')) : null);
                                                                                                 }
                                                                                                 if(addressAux.Default_Billing__c){
                                                                                                     accountRecord.Address_Phone__c = addressAux.Phone__c;
                                                                                                     accountRecord.Address_1__c = addressAux.Address_1__c;
                                                                                                     accountRecord.Address_2__c = addressAux.Address_2__c;
                                                                                                     accountRecord.Attention_Address__c = addressAux.Attention__c;
                                                                                                     accountRecord.BillingStreet = addressAux.Address_1__c;
                                                                                                     accountRecord.BillingState = addressAux.State__c;
                                                                                                     accountRecord.BillingCity = addressAux.City__c;
                                                                                                     accountRecord.BillingPostalCode = addressAux.Zip__c;
                                                                                                     accountRecord.BillingCountry = (addressAux.Country__c != null ? (addressAux.Country__c == '_unitedStates' ? 'United States' : addressAux.Country__c.replace('_','')) : null);
                                                                                                 }
                                                                                                 addressListAux.add(addressAux);
                                                                                             }
                                                                                         }
                                                                                         
                                                                                         for(Address__c aRecord : addressMap.get(accountRecord.Id)){
                                                                                             for(Address__c aRec : addressListAux){
                                                                                                 if(aRecord.NS_ID__c == null && aRecord.City__c == aRec.City__c && aRecord.State__c == aRec.State__c && aRecord.Address_1__c == aRec.Address_1__c &&
                                                                                                    aRecord.Address_2__c == aRec.Address_2__c && aRecord.Addressee__c == aRec.Addressee__c && aRecord.Phone__c == aRec.Phone__c && aRecord.Zip__c == aRec.Zip__c &&
                                                                                                    aRecord.Attention__c == aRec.Attention__c){
                                                                                                        aRecord.NS_ID__c = aRec.NS_ID__c;
                                                                                                        addressUpdateList.add(aRecord);
                                                                                                        break;
                                                                                                    }
                                                                                             }
                                                                                         }
                                                                                     }
                                                                                 }
                                                                             }
                                                                         }
                                                                     }
                                                                 }
                                                             }
                                                         }
                                                     }
                                                 }
                                             }
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
        
        system.debug(addressUpdateList);
        if(!addressUpdateList.isEmpty()) update addressUpdateList;
    }
    
    @future(callout=true)
	public static void upsertContact(Set<String> recordIds){
        Map<String,Object> customSettingMap = new Map<String,Object>();
        for(NetsuiteLead__c nl : NetsuiteLead__c.getall().values()) customSettingMap.put(nl.Name.trim().toLowerCase(),nl);
        
        List<Contact> contactList = new List<Contact>();
        String xmlBody;
        HTTPResponse response;
        String prefCcProcessorXML, entityStatusXML, typeCustomerXML, priceLevelXML, associationXML, partnerXML, errorCode, errorString, errorSuccess;
        for(Contact contactRecord : [SELECT Id, Account.NS_ID__c, NS_ID__c, Name, Salutation, Firstname, Lastname, Title, Phone, MobilePhone, HomePhone, OtherPhone, Fax, Email, Alt_Email__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry FROM Contact WHERE Id IN: recordIds]){
            xmlBody = 
                '<'+ (contactRecord.NS_ID__c == null ? 'add' : 'update') +'>' +
                (contactRecord.NS_ID__c == null ? '<platformMsgs:record xsi:type="listRel:Contact" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">' : '<platformMsgs:record internalId="' + contactRecord.NS_ID__c + '" xsi:type="listRel:Contact" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">') +
                '		<listRel:entityId>' + contactRecord.Name + '</listRel:entityId>' +
                (contactRecord.Account.NS_ID__c != null ? '<listRel:company internalId="' + contactRecord.Account.NS_ID__c + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />' : '') +
                '		<listRel:salutation>' + (contactRecord.Salutation != null ? contactRecord.Salutation : '') + '</listRel:salutation>' +
                '		<listRel:firstName>' + (contactRecord.Firstname != null ? contactRecord.Firstname : '') + '</listRel:firstName>' +
                '		<listRel:lastName>' + contactRecord.Lastname + '</listRel:lastName>' +
                '		<listRel:title>' + (contactRecord.Title != null ? contactRecord.Title : '') + '</listRel:title>' +
                '		<listRel:phone>' + (contactRecord.Phone != null ? contactRecord.Phone : '') + '</listRel:phone>' +
                '		<listRel:fax>' + (contactRecord.Fax != null ? contactRecord.Fax : '') + '</listRel:fax>' +
                '		<listRel:email>' + (contactRecord.Email != null ? contactRecord.Email : '') + '</listRel:email>' +
                '		<listRel:altEmail>' + (contactRecord.Alt_Email__c != null ? contactRecord.Alt_Email__c : '') + '</listRel:altEmail>' +
                '		<listRel:officePhone>' + (contactRecord.OtherPhone != null ? contactRecord.OtherPhone : '') + '</listRel:officePhone>' +
                '		<listRel:homePhone>' + (contactRecord.HomePhone != null ? contactRecord.HomePhone : '') + '</listRel:homePhone>' +
                '		<listRel:mobilePhone>' + (contactRecord.MobilePhone != null ? contactRecord.MobilePhone : '') + '</listRel:mobilePhone>' +
                '<listRel:addressbookList>' +
                '	<listRel:addressbook>' +
                '		<listRel:defaultShipping>true</listRel:defaultShipping>' +
                '		<listRel:defaultBilling>true</listRel:defaultBilling>' +
                '		<listRel:addressbookAddress xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com">' +
                '			<platformCommon:country>' + (contactRecord.MailingCountry != null ? '_' + contactRecord.MailingCountry.toLowerCase().subString(0,1) + contactRecord.MailingCountry.subString(1,contactRecord.MailingCountry.length()).replace(' ','').replace('(','').replace(')','') : '') + '</platformCommon:country>' +
                //'			<platformCommon:attention>' + (contactRecord.Attention_Address__c != null ? contactRecord.Attention_Address__c : '') + '</platformCommon:attention>' +
                '			<platformCommon:addressee>' + (contactRecord.MailingStreet != null ? contactRecord.MailingStreet : '') + '</platformCommon:addressee>' +
                //'			<platformCommon:addrPhone>' + (contactRecord.Address_Phone__c != null ? contactRecord.Address_Phone__c : '') + '</platformCommon:addrPhone>' +
                //'			<platformCommon:addr1>' + (contactRecord.Address_1__c != null ? contactRecord.Address_1__c : '') + '</platformCommon:addr1>' +
                //'			<platformCommon:addr2>' + (contactRecord.Address_2__c != null ? contactRecord.Address_2__c : '') + '</platformCommon:addr2>' +
                '			<platformCommon:city>' + (contactRecord.MailingCity != null ? contactRecord.MailingCity : '') + '</platformCommon:city>' +
                '			<platformCommon:state>' + (contactRecord.MailingState != null ? contactRecord.MailingState : '') + '</platformCommon:state>' +
                '			<platformCommon:zip>' + (contactRecord.MailingPostalCode != null ? contactRecord.MailingPostalCode : '') + '</platformCommon:zip>' +
                '			<platformCommon:override>false</platformCommon:override>' +
                '		</listRel:addressbookAddress>' +
                '	</listRel:addressbook>' +
                '</listRel:addressbookList>' +
                '	</platformMsgs:record>' +
                '</' + (contactRecord.NS_ID__c == null ? 'add' : 'update') +'>';
            
            response = NetsuiteConnection.postNetsuiteSoap((contactRecord.NS_ID__c == null ? 'add' : 'update'),xmlBody,true);
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
                contactRecord.Netsuite_To_Sync__c = false;
                contactRecord.Netsuite_Sync_Status__c = 'Synced';
                contactRecord.Netsuite_Sync_Error__c = '';
                contactRecord.NS_ID__c = response.getBody().subStringBetween('platformMsgs:baseRef internalId="','" type="contact"');
            } else {
                system.debug(errorCode);
                contactRecord.Netsuite_To_Sync__c = false;
                contactRecord.Netsuite_Sync_Status__c = 'Error';
                if(errorSuccess!=null)
                    contactRecord.Netsuite_Sync_Error__c = errorSuccess.left(255);
                else
                    contactRecord.Netsuite_Sync_Error__c = (errorCode + '->' + errorString).left(255);
            }
            contactList.add(contactRecord);
        }
        ApexUtil.isContactTriggerInvoked = false;
        if(!contactList.isEmpty()) update contactList;
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