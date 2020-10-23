public class NetsuiteConnection {
    
    public static Netsuite__c authentication = Netsuite__c.getOrgDefaults();
    
    public static String getURL(){
        return authentication.Base_URL__c;
    }
    
    public static String getNetsuiteObject(String netsuiteObject, String filters){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(authentication.Base_URL__c + netsuiteObject + (!Test.isRunningTest() && String.isNotBlank(filters) ? '?' + filters : ''));
        request.setMethod('GET');
        Map<String, String> parametersAuthorization = new Map<String,String>();
        String nonce = String.valueOf(Crypto.getRandomLong());
    	String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        parametersAuthorization.put('oauth_consumer_key', authentication.Consumer_Key__c);
        parametersAuthorization.put('oauth_token', authentication.Token_Id__c);
        parametersAuthorization.put('oauth_signature_method','HMAC-SHA256');
        parametersAuthorization.put('oauth_timestamp', timestamp);
        parametersAuthorization.put('oauth_nonce', generateRandomString(6));
        parametersAuthorization.put('oauth_version', '1.0');
        String oauthSignature = getAuthSignature(request, parametersAuthorization);
        parametersAuthorization.put('realm',authentication.Account_Id__c);
        parametersAuthorization.put('oauth_signature', oauthSignature);
        //System.debug('EndPoint: ' + authentication.Base_URL__c + netsuiteObject + (!Test.isRunningTest() && String.isNotBlank(filters) ? '?' + filters : ''));
        String header = '';
		for (String key : parametersAuthorization.keySet()) {
			header = header + key + '="'+parametersAuthorization.get(key)+'",';
		}
        //System.debug('header: ' + header);
        header = header.removeEnd(',');
        //System.debug('header: ' + header);
        request.setHeader('Authorization', 'OAuth ' + header/*EncodingUtil.base64Encode(Blob.valueOf(authentication.Username__c+':'+authentication.Password__c))*/);
        request.setHeader('Accept','application/json');
        request.setTimeout(120000);
        Http http = new Http();
        HTTPResponse response;
        try{
            if(!Test.isRunningTest()){
                response = http.send(request);
            }else {
                response = new HTTPResponse();
                response.setStatusCode(200);
                if(netsuiteObject.equalsIgnoreCase('customer')) response.setBody('{ "links": [ { "rel": "next", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer?limit=1000&offset=1000" }, { "rel": "last", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer?limit=1000&offset=47000" }, {"rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer?limit=1000&offset=0" } ], "count": 1000, "hasMore": true, "items": [ { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/26" } ], "id": "26" } ], "offset": 0, "totalResults": 47598 }');
                else if(netsuiteObject.equalsIgnoreCase('contact')) response.setBody('{ "links": [ { "rel": "next", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact?limit=1000&offset=1000" }, { "rel": "last", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact?limit=1000&offset=47000" }, {"rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact?limit=1000&offset=0" } ], "count": 1000, "hasMore": true, "items": [ { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact/26" } ], "id": "26" } ], "offset": 0, "totalResults": 47598 }');
                else if(netsuiteObject.equalsIgnoreCase('salesOrder')) response.setBody('{ "links": [ { "rel": "next", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesOrder?limit=1000&offset=1000" }, { "rel": "last", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesOrder?limit=1000&offset=47000" }, {"rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesOrder?limit=1000&offset=0" } ], "count": 1000, "hasMore": true, "items": [ { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesOrder/26" } ], "id": "26" } ], "offset": 0, "totalResults": 47598 }');
                else if(netsuiteObject.contains('customer/')) response.setBody('{ "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5" } ], "accessRole": { "links": [], "id": "14", "refName": "Customer Center" }, "addressbook": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/addressbook" } ] }, "alcoholRecipientType": "CONSUMER", "balance": 0, "campaignCategory": { "links": [], "id": "-4", "refName": "Online" }, "comments": "test coments", "companyName": "T-San Diego sign company", "consolbalance": 0, "consoldepositbalance": 0, "consoloverduebalance": 0, "consolunbilledorders": 0, "contactRoles": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/contactRoles" } ] }, "creditCards": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/creditCards" } ] }, "creditholdoverride": "AUTO", "currencyPrecision": 2, "custentity10": false, "custentity11": false, "custentity12": true, "custentity13": false, "custentity14": false, "custentity15": false, "custentity16": false, "custentity17": false, "custentity18": false, "custentity19": false, "custentity2": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/custentity2" } ] }, "custentity20": false, "custentity21": false, "custentity22": false, "custentity23": false, "custentity24": false, "custentity31": false, "custentity32": false, "custentity33": false, "custentity34": false, "custentity37": false, "custentity38": false, "custentity39": false, "custentity40": false, "custentity41": false, "custentity42": true, "custentity46": false, "custentity5": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/employee/16" } ], "id": "16", "refName": "Orlando Cosme" }, "custentity50": false, "custentity52": false, "custentity53": false, "custentity8": false, "custentity9": false, "custentity_am_survey_sent": false, "custentity_avataxaddresseshandled": false, "custentity_customer_agree_terms": false, "custentity_customer_sent_catalogs": false, "custentity_disablequickproofs": false, "custentity_esc_annual_revenue": 12, "custentity_esc_industry": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customlist_esc_industries/22" } ], "id": "22", "refName": "Manufacturing" }, "custentity_esc_last_modified_date": "2018-08-22", "custentity_esc_no_of_employees": 85, "custentity_exhibit_catalog": false, "custentity_finish_photo": false, "custentity_firstorder_email": false, "custentity_linktoresalecert": "https://s3.console.aws.amazon.com/s3/buckets/wsdisplay-sca/5/resale_certificate/", "custentity_multi_email_request": false, "custentity_notaxstates_doc_checkbox": false, "custentity_one_choice_catalog": false, "custentity_onechoice_promo_group": false, "custentity_ozlink_bill_shipping_to_3rd": false, "custentity_ozlink_bill_shipping_to_recip": false, "custentity_ozlink_website": "http://www.ozlinkshipping.com", "custentity_resort_catalog": false, "custentity_sc_partner_email_sent": false, "custentity_sc_send_reset_password_email": false, "custentity_sc_web_approved": false, "custentity_sdr_apply_coupon": false, "custentity_sent_email_overdueterm": false, "custentity_total_onechoice_transaction": "0", "custentity_total_transactions": "0", "custentity_typeofcustomer": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/pricelevel/7" } ], "id": "7", "refName": "SD Sign" }, "custentity_ws_catalog": false, "custentitycustomersurveystatus": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customlistsurveysubscription/1" } ], "id": "1", "refName": "Yes" }, "custentityinterested_wsprime": false, "custentityweb_tour": false, "customForm": "117", "dateCreated": "2012-07-06T14:36:00Z", "defaultAddress": "", "depositbalance": 0, "email": "mannysdsign@gmail.com", "emailPreference": "PDF", "emailTransactions": true, "entityId": "1 T-San Diego sign company", "entityStatus": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customerstatus/13" } ], "id": "13", "refName": "CUSTOMER-Closed Won" }, "faxTransactions": false, "giveAccess": false, "globalsubscriptionstatus": "2", "grouppricing": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/grouppricing" } ] }, "id": "5", "isBudgetApproved": false, "isinactive": false, "isJob": false, "isPerson": false, "itempricing": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/itempricing" } ] }, "lastModifiedDate": "2018-08-22T14:50:00Z", "leadSource": { "links": [], "id": "818", "refName": "4 WSPrime Preferred Customer" }, "overduebalance": 0, "phone": "8082780525", "prefCcProcessor": { "links": [], "id": "1", "refName": "SDsign" }, "priceLevel": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/pricelevel/7" } ], "id": "7", "refName": "SD Sign" }, "printTransactions": true, "receivablesaccount": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/account/-10" } ], "id": "-10", "refName": "Use System Preference" }, "salesRep": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/employee/953" } ], "id": "953", "refName": "Unassigned Sales Rep" }, "sendEmail": false, "shipComplete": true, "shippingCarrier": "nonups", "stage": "CUSTOMER", "startDate": "2012-11-09", "subscriptions": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/5/subscriptions" } ] }, "subsidiary": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/subsidiary/1" } ], "id": "1", "refName": "Parent Company" }, "taxable": true, "taxItem": { "links": [], "id": "19388", "refName": "AVATAX" }, "thirdPartyCountry": "US", "unbilledorders": 0, "unsubscribe": "T", "url": "http://Www.sdsign.com" }');
                else if(netsuiteObject.contains('contact/')) response.setBody('{ "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact/50146" } ], "addressbook": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact/50146/addressbook" } ] }, "category": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/contact/50146/category" } ] }, "custentity_esc_last_modified_date": "2016-02-29", "customForm": "22", "dateCreated": "2013-02-25T19:23:00Z", "defaultAddress": "", "email": "orders@heynobody.com", "entityId": "(no name)", "firstName": "(no", "globalsubscriptionstatus": "4", "id": "50146", "isinactive": false, "isPrivate": false, "lastModifiedDate": "2016-02-29T22:47:00Z", "lastName": "name)", "owner": 959, "phone": "(702) 589-4689", "subsidiary": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/subsidiary/1" } ], "id": "1", "refName": "Parent Company" }, "unsubscribe": "T" }');
                else if(netsuiteObject.contains('salesOrder/')) response.setBody('{ "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788" } ], "accountingBookDetail": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/accountingBookDetail" } ] }, "allowEmptyCards": false, "altShippingCost": 0, "balance": 0, "billAddress": "", "billingaddress": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/billingaddress" } ] }, "canHaveStackable": false, "ccApproved": false, "consolidatebalance": 0, "createdDate": "2013-01-02T13:49:00Z", "currency": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/currency/1" } ], "id": "1", "refName": "1" }, "currencysymbol": "USD", "custbody1": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/pricelevel/7" } ], "id": "7", "refName": "SD Sign" }, "custbody10": "SD#35384", "custbody107": false, "custbody11": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customlist21/2" } ], "id": "2", "refName": "Hardware + Graphics" }, "custbody13": false, "custbody15": false, "custbody17": false, "custbody29": false, "custbody3": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/employee/2682" } ], "id": "2682", "refName": "Brian H Irick" }, "custbody30": false, "custbody32": false, "custbody33": false, "custbody34": false, "custbody5": "SO-0657", "custbody69": false, "custbody79": false, "custbody8": "", "custbody88": false, "custbody9": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/employee/1057" } ], "id": "1057", "refName": "Ana Gonzalez" }, "custbody91": false, "custbody92": false, "custbody94": false, "custbody_allgraphicsapproved": false, "custbody_allgraphicssent": false, "custbody_amtdue": "ERROR: Field Not Found", "custbody_art_file_exemption": false, "custbody_artfile_by_email": false, "custbody_ava_customercompanyname": "Coffee Shop Creatives", "custbody_ava_customerentityid": "16090", "custbody_ava_customerisperson": false, "custbody_ava_customertaxable": true, "custbody_ava_is_sellerimporter": false, "custbody_ava_partnerisperson": false, "custbody_ava_pickup": false, "custbody_ava_scis_trans_flag": false, "custbody_ava_shippingtaxinclude": false, "custbody_ava_suspendtaxcall": false, "custbody_ava_taxinclude": false, "custbody_ava_taxoverride": false, "custbody_ca_cert_status": "F", "custbody_cbackproofapproved": false, "custbody_check_productreview_email": false, "custbody_cm_expire_date": "2013-04-28", "custbody_cr_status": "1", "custbody_disabledqpzcust": false, "custbody_donotautoassignqueue": false, "custbody_esc_created_date": "2013-01-02", "custbody_esc_last_modified_date": "2018-01-07", "custbody_graphicapprovalscreated": false, "custbody_multi_order_conf_email": false, "custbody_orderstatus": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customlist18/9" } ], "id": "9", "refName": "Released" }, "custbody_ozlink_bill_shipping_to_3rd": false, "custbody_ozlink_bill_shipping_to_recip": false, "custbody_ozlink_websitelink": "http://www.ozlinkshipping.com", "custbody_quickproofemailsent": false, "custbody_readytoprint": false, "custbody_sc_bill_to_receiver": false, "custbody_sc_third_party_billing": false, "custbody_sent_invoice_email": false, "custbody_sentprodauto": false, "custbody_shipdatepopulated": false, "custbody_split_order": false, "custbody_touchedbygraphics": false, "custbody_transaction_cnfo_email_chck": false, "custbody_verifiedinproduction": false, "custbodycheckedbybusinessdev": false, "custbodycustentity_order_conf_email": "phil@cscreatives.com;", "custbodyfulfillment_email": false, "custbodysend_email_after_g_approve": false, "customForm": "111", "department": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/department/3" } ], "id": "3", "refName": "Operations : Research and Development" }, "discountTotal": 0, "email": "liz@cscreatives.com", "endDate": "2013-01-02", "entity": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/customer/34702" } ], "id": "34702", "refName": "16090 Coffee Shop Creatives" }, "entityNexus": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/nexus/2" } ], "id": "2", "refName": "PA" }, "estGrossProfit": 1798, "estGrossProfitPercent": 100, "exchangeRate": 1, "getAuth": false, "id": "6788", "ignoreAvs": false, "ignoreCsc": false, "isBaseCurrency": true, "isMultiShipTo": false, "isRecurringPayment": false, "item": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/item" } ] }, "lastModifiedDate": "2018-01-07T19:47:00Z", "nexus": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/nexus/2" } ], "id": "2", "refName": "PA" }, "orderStatus": "G", "overrideHold": false, "overrideHoldChecked": false, "paymentMethod": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/paymentmethod/9" } ], "id": "9", "refName": "SDsign Store Payment" }, "payPalProcess": false, "promotions": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/promotions" } ] }, "saleseffectivedate": "2012-12-28", "salesRep": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/employee/953" } ], "id": "953", "refName": "Unassigned Sales Rep" }, "shipAddress": "", "shipAddressList": { "links": [], "id": "33438", "refName": "Scenic Ridge Whitetale" }, "shipComplete": true, "shipDate": "2012-12-28", "shipGroup": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/shipGroup" } ] }, "shipIsResidential": false, "shipMethod": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/shipitem/134" } ], "id": "134", "refName": "In Store Pick Up" }, "shipOverride": false, "shippingAddress": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/salesorder/6788/shippingAddress" } ] }, "shippingCost": 0, "shippingCostOverridden": false, "shippingTaxCode": { "links": [], "id": "-8", "refName": "-Not Taxable-" }, "startDate": "2013-01-02", "status": "Billed", "subsidiary": { "links": [ { "rel": "self", "href": "https://1030411.suitetalk.api.netsuite.com/services/rest/record/v1/subsidiary/1" } ], "id": "1", "refName": "Parent Company" }, "subtotal": 1798, "taxTotal": 0, "toBeEmailed": false, "toBeFaxed": false, "toBePrinted": false, "total": 1798, "totalCostEstimate": 0, "trandate": "2012-12-28", "tranId": "SO-0657", "unbilledOrders": 0 }');
           	}
        }
        catch(Exception e){
            response = new HTTPResponse();
            response.setStatusCode(500);
            //System.debug('###NetsuiteConnection.getNetsuiteObject - Callout Exception: '+e.getMessage());
        }
        //System.debug('getNetsuiteObject(netsuiteObject = ' + netsuiteObject + ', filters = ' +  filters + ') => Response Status Code: ' + response.getStatusCode() + ', Response Body: ' + (String.isNotEmpty(response.getBody()) ? response.getBody().left(255) : ''));
        return response.getStatusCode() == 200 /*&& ( response.getBody().contains('"status_code":200') || response.getBody().contains('"status_code": 200')  || response.getBody().contains('"status_code" : 200') || response.getBody().contains('"status_code" :200') )*/ ? response.getBody() : /*'{"status":{"status_code":200,"page":1,"total_pages":0},"result":[]}'*/ null;
    }
    
    private static Map<String,String> getUrlParams(String value) {

		Map<String,String> res = new Map<String,String>();
		if(value==null || value=='') {
			return res;
		}
		for(String s : value.split('&')) {
			//System.debug('getUrlParams: '+s);
			List<String> kv = s.split('=');
			if(kv.size()>1) {
			  // RFC 5849 section 3.4.1.3.1 and 3.4.1.3.2 specify that parameter names 
			  // and values are decoded then encoded before being sorted and concatenated
			  // Section 3.6 specifies that space must be encoded as %20 and not +
			  String encName = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[0], 'UTF-8'), 'UTF-8').replace('+','%20');
			  String encValue = EncodingUtil.urlEncode(EncodingUtil.urlDecode(kv[1], 'UTF-8'), 'UTF-8').replace('+','%20');
			  System.debug('getUrlParams:  -> '+encName+','+encValue);
			  res.put(encName,encValue);
			}
		}
		return res;
	}
    
    private static String createBaseString(HttpRequest request, Map<String,String> oauthParams) {
		Map<String,String> p = oauthParams.clone();
		if(request.getMethod().equalsIgnoreCase('post') && request.getBody()!=null && 
		   request.getHeader('Content-Type')=='application/x-www-form-urlencoded') {
		   p.putAll(getUrlParams(request.getBody()));
		}
		String host = request.getEndpoint();
		Integer n = host.indexOf('?');
		if(n>-1) {
			p.putAll(getUrlParams(host.substring(n+1)));
			host = host.substring(0,n);
		}
		List<String> keys = new List<String>();
		keys.addAll(p.keySet());
		keys.sort();
		String s = keys.get(0)+'='+p.get(keys.get(0));
		for(Integer i=1;i<keys.size();i++) {
			s = s + '&' + keys.get(i)+'='+p.get(keys.get(i));
		}
		//System.debug('s: ' + s);
		// According to OAuth spec, host string should be lowercased, but Google and LinkedIn
		// both expect that case is preserved.
		return request.getMethod().toUpperCase()+ '&' + 
			EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
			EncodingUtil.urlEncode(s, 'UTF-8');
	}
    
    public static String getAuthSignature(HttpRequest request, Map<String,String> oauthParams){
        String baseString = createBaseString(request, oauthParams);
        //System.debug('baseString: ' + baseString);
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(baseString), Blob.valueOf(authentication.Consumer_Secret__c +
                                                                                             '&' + authentication.Token_Secret__c));
        String signatureEncode = EncodingUtil.urlEncode(EncodingUtil.base64Encode(signature), 'UTF-8');
        //System.debug('signatureEncode: ' + signatureEncode);
        return signatureEncode;       
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    /*public static HTTPResponse updateNetsuiteObject(String netsuiteObject, String body){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(authentication.Base_URL__c + netsuiteObject + '?_HttpMethod=PATCH');
        request.setMethod('PATCH');
        request.setBody(body);
        Map<String, String> parametersAuthorization = new Map<String,String>();
        String nonce = String.valueOf(Crypto.getRandomLong());
    	String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        parametersAuthorization.put('oauth_consumer_key', authentication.Consumer_Key__c);
        parametersAuthorization.put('oauth_token', authentication.Token_Id__c);
        parametersAuthorization.put('oauth_signature_method','HMAC-SHA256');
        parametersAuthorization.put('oauth_timestamp', timestamp);
        parametersAuthorization.put('oauth_nonce', generateRandomString(6));
        parametersAuthorization.put('oauth_version', '1.0');
        String oauthSignature = getAuthSignature(request, parametersAuthorization);
        parametersAuthorization.put('realm',authentication.Account_Id__c);
        parametersAuthorization.put('oauth_signature', oauthSignature);
        System.debug('EndPoint: ' + authentication.Base_URL__c + netsuiteObject + '?_HttpMethod=PATCH');
        String header = '';
		for (String key : parametersAuthorization.keySet()) {
			header = header + key + '="'+parametersAuthorization.get(key)+'",';
		}
        //System.debug('header: ' + header);
        header = header.removeEnd(',');
        //System.debug('header: ' + header);
        request.setHeader('Authorization', 'OAuth ' + header);
        request.setHeader('Content-type','application/json');
        request.setTimeout(120000);
        Http http = new Http();
        HTTPResponse response;
        try{
            if(!Test.isRunningTest())
            	response = http.send(request);
            else {
                response = new HTTPResponse();
                response.setStatusCode(200);
                if(netsuiteObject.equalsIgnoreCase('contacts')) response.setBody('{"status":{"text":"OK","status_code":200,"description":null,"sort_field":"created_at","sort_direction": "asc","page": 1,"page_size": 10,"total_pages": 1,"total_records":1},"result": [{"id": "6021fc93-7f41-4f0a-88ae-a813432fb571","title": null,"fullName": "Michael Hudson","notes": null,"external_id": null,"service_id": "40e821f9-db31-4da5-87da-7d2f150407cc","first_name": "Michael","last_name": "Hudson","assigned_to_team_id": null,"assigned_to_user_id": null,"is_messageable": true,"is_confirmed": true,"is_starred": false,"is_closed": true,"avatar_uri": "https://storage.googleapis.com/zingle-public/aec/16/2f/73/6b2f02acc6caa645dd10a61878e84a7.png","optin_status": null,"unconfirmed_at": 1571148951,"created_at": 1539700280,"updated_at": 1571148951,"locked_by_source": null,"last_message": {"id": "9f49bef7-3043-4e6f-bfc3-987fe986188d","body": "Order meds","created_at": 1571086051},"channels":[{"id": "0ee15f6a-439c-4246-ac51-5f09d9cdd366","display_name": "MOBILE","value": "+17202997543","formatted_value": "(720) 299-7543","country": "US","is_default": true,"is_default_for_type": false,"block_inbound": false,"block_outbound": false,"is_messageable": true,"channel_type": {"id": "0a293ea3-4721-433e-a031-610ebcf43255","type_class": "PhoneNumber","display_name": "Phone Number","inbound_notification_url": null,"outbound_notification_url": null,"allow_communications": true}}],"custom_field_values": [{"value": "Hudson","custom_field": {"id": "0df80524-3b27-4fb0-8eeb-c81bd448d294","display_name": "Last Name","data_type": "string","code": "last_name","replacement_variable":"LAST NAME","is_global": false,"options": null}}],"labels": [{"id": "f043f196-f7b8-4837-9a67-a37bc2820b86","code": "ed_1_year_plan","display_name": "ED 1 year plan","background_color": "#FEE9E8","text_color": "#FD612C","is_automatic": false,"is_global": false}],"contact_groups": [],"calendar_events": []}]}');
                else if(netsuiteObject.equalsIgnoreCase('services/40e821f9-db31-4da5-87da-7d2f150407cc/messages')) { response.setBody('{"status": {"text": "OK","status_code": 200,"description": null,"sort_field":"created_at","sort_direction": "asc","page": 1,"page_size":10,"total_pages": 1,"total_records": 1},"result": [{"body": "Hi, this is Michael with the RMMC.","id": "ee08abb2-8921-42a2-9bb9-42664c8f04f7","template_id": null,"created_at": 1539700280,"updated_at": 1539700280,"read_at": null,"deleted_by_contact_at": null,"triggered_by_user_id": "ecdeda26-882a-44cd-a320-75f9c099e0d2","triggered_by_user": {"id": "ecdeda26-882a-44cd-a320-75f9c099e0d2","email": "michael@rmmensclinic.com","first_name": "Michael","last_name": "Hudson","title": null,"username": "michael@rmmensclinic.com","avatar_uri": null},"sender_type": "service","sender": {"id": "40e821f9-db31-4da5-87da-7d2f150407cc","channel": {"type_class": "PhoneNumber","display_name": null,"value": "+17205132410","formatted_value": "(720) 513-2410"}},"recipient_type": "contact","recipient": {"id": "6021fc93-7f41-4f0a-88ae-a813432fb571","channel": {"type_class": "PhoneNumber","display_name": "(720) 299-7543","value": "+17202997543","formatted_value": "(720) 299-7543"}},"communication_direction": "outbound","attachments": [],"is_delayed": false,"execute_at": 0,"executed_at": null,"forwarded_by_service_uuid": null,"translated_body_language_code": null,"translated_body": null,"body_language_code": null}]}');}
            }
        }
        catch(Exception e){
            response = new HTTPResponse();
            response.setStatusCode(500);
            System.debug('###NetsuiteConnection.getNetsuiteObject - Callout Exception: '+e.getMessage());
        }
        System.debug('getNetsuiteObject(netsuiteObject = ' + netsuiteObject + ') => Response Status Code: ' + response.getStatusCode() + ', Response Body: ' + (String.isNotEmpty(response.getBody()) ? response.getBody().left(255) : ''));
        return response;
    }*/
    
    public static HttpResponse postNetsuiteSoap(String action, String bodyXML){
        Http http = new Http();
        HTTPResponse response;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(authentication.Base_URL_Soap__c);
        request.setMethod('POST');
    	String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String nonce = generateRandomString(10);
        String baseString = authentication.Account_Id__c + '&' + authentication.Consumer_Key__c + '&' + authentication.Token_Id__c + '&' + nonce + '&' + timestamp; 
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(baseString), Blob.valueOf(authentication.Consumer_Secret__c + '&' + authentication.Token_Secret__c));
        String body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' + 
            				'<soapenv:Header>' + 
            				'   <platformMsgs:tokenPassport>' +
            				'		<platformCore:account>' + authentication.Account_Id__c + '</platformCore:account>' + 
            				'		<platformCore:consumerKey>' + authentication.Consumer_Key__c + '</platformCore:consumerKey>' + 
            				'		<platformCore:token>' + authentication.Token_Id__c + '</platformCore:token>' + 
            				'		<platformCore:nonce>' + nonce + '</platformCore:nonce>' + 
            				'		<platformCore:timestamp>' + timestamp + '</platformCore:timestamp>' + 
            				'		<platformCore:signature algorithm="HMAC-SHA256">' + EncodingUtil.base64Encode(signature) + '</platformCore:signature>' + 
            				'   </platformMsgs:tokenPassport>' + 
            				//'	<preferences>' +
         					//'		<runServerSuiteScriptAndTriggerWorkflows>false</runServerSuiteScriptAndTriggerWorkflows>' +
      						//'</preferences>' +
            				'</soapenv:Header>' + 
            				'<soapenv:Body>' + 
            					bodyXML + 
            				'</soapenv:Body>' + 
            			'</soapenv:Envelope>';
        
        request.setBody(body);
        request.setHeader('Content-type','text/xml');
        request.setHeader('SOAPAction',action);
        request.setTimeout(120000);
        try{
            if(!Test.isRunningTest()) response = http.send(request);
            else {
                response = new HTTPResponse();
                response.setStatusCode(200);
                response.setBody('<success>true</success>');
            }
        }
        catch(Exception e){
            response = new HttpResponse();
            response.setStatusCode(500);
            System.debug('###NetsuiteConnection.updateNetsuiteObjectSoap - Callout Exception: '+e.getMessage());
        }
        System.debug('updateNetsuiteObjectSoap-Response Status Code: ' + response.getStatusCode() + ', Response Body: ' + (String.isNotEmpty(response.getBody()) ? response.getBody().left(255) : ''));
        System.debug(response.getBody().substringBetween('<faultstring>', '</faultstring>'));
        return response;
    }
    public static HTTPResponse updateNetsuiteObjectSoap(String bodyXML){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(authentication.Base_URL_Soap__c);
        request.setMethod('POST');
    	String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String nonce = generateRandomString(10);
        String baseString = authentication.Account_Id__c + '&' + authentication.Consumer_Key__c + '&' + authentication.Token_Id__c + '&' + nonce + '&' + timestamp; 
        //System.debug('baseString: ' + baseString);
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(baseString), Blob.valueOf(authentication.Consumer_Secret__c +
                                                                                             '&' + authentication.Token_Secret__c));
        //String signatureEncode = EncodingUtil.urlEncode(EncodingUtil.base64Encode(signature), 'UTF-8');
        String body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' + 
            				'<soapenv:Header>' + 
            				'   <platformMsgs:tokenPassport>' +
            				'		<platformCore:account>' + authentication.Account_Id__c + '</platformCore:account>' + 
            				'		<platformCore:consumerKey>' + authentication.Consumer_Key__c + '</platformCore:consumerKey>' + 
            				'		<platformCore:token>' + authentication.Token_Id__c + '</platformCore:token>' + 
            				'		<platformCore:nonce>' + nonce + '</platformCore:nonce>' + 
            				'		<platformCore:timestamp>' + timestamp + '</platformCore:timestamp>' + 
            				'		<platformCore:signature algorithm="HMAC-SHA256">' + EncodingUtil.base64Encode(signature) + '</platformCore:signature>' + 
            				'   </platformMsgs:tokenPassport>' + 
            				'</soapenv:Header>' + 
            				'<soapenv:Body>' + 
            					bodyXML + 
            				'</soapenv:Body>' + 
            			'</soapenv:Envelope>';
        
        request.setBody(body);
        System.debug(body);
        request.setHeader('Content-type','text/xml');
        request.setHeader('SOAPAction','update');
        request.setTimeout(120000);
        Http http = new Http();
        HTTPResponse response;
        try{
            if(!Test.isRunningTest())
            	response = http.send(request);
            else {
                response = new HTTPResponse();
                response.setStatusCode(200);
                response.setBody('<success>true</success>');
                //if(netsuiteObject.equalsIgnoreCase('contacts')) response.setBody('{"status":{"text":"OK","status_code":200,"description":null,"sort_field":"created_at","sort_direction": "asc","page": 1,"page_size": 10,"total_pages": 1,"total_records":1},"result": [{"id": "6021fc93-7f41-4f0a-88ae-a813432fb571","title": null,"fullName": "Michael Hudson","notes": null,"external_id": null,"service_id": "40e821f9-db31-4da5-87da-7d2f150407cc","first_name": "Michael","last_name": "Hudson","assigned_to_team_id": null,"assigned_to_user_id": null,"is_messageable": true,"is_confirmed": true,"is_starred": false,"is_closed": true,"avatar_uri": "https://storage.googleapis.com/zingle-public/aec/16/2f/73/6b2f02acc6caa645dd10a61878e84a7.png","optin_status": null,"unconfirmed_at": 1571148951,"created_at": 1539700280,"updated_at": 1571148951,"locked_by_source": null,"last_message": {"id": "9f49bef7-3043-4e6f-bfc3-987fe986188d","body": "Order meds","created_at": 1571086051},"channels":[{"id": "0ee15f6a-439c-4246-ac51-5f09d9cdd366","display_name": "MOBILE","value": "+17202997543","formatted_value": "(720) 299-7543","country": "US","is_default": true,"is_default_for_type": false,"block_inbound": false,"block_outbound": false,"is_messageable": true,"channel_type": {"id": "0a293ea3-4721-433e-a031-610ebcf43255","type_class": "PhoneNumber","display_name": "Phone Number","inbound_notification_url": null,"outbound_notification_url": null,"allow_communications": true}}],"custom_field_values": [{"value": "Hudson","custom_field": {"id": "0df80524-3b27-4fb0-8eeb-c81bd448d294","display_name": "Last Name","data_type": "string","code": "last_name","replacement_variable":"LAST NAME","is_global": false,"options": null}}],"labels": [{"id": "f043f196-f7b8-4837-9a67-a37bc2820b86","code": "ed_1_year_plan","display_name": "ED 1 year plan","background_color": "#FEE9E8","text_color": "#FD612C","is_automatic": false,"is_global": false}],"contact_groups": [],"calendar_events": []}]}');
                //else if(netsuiteObject.equalsIgnoreCase('services/40e821f9-db31-4da5-87da-7d2f150407cc/messages')) { response.setBody('{"status": {"text": "OK","status_code": 200,"description": null,"sort_field":"created_at","sort_direction": "asc","page": 1,"page_size":10,"total_pages": 1,"total_records": 1},"result": [{"body": "Hi, this is Michael with the RMMC.","id": "ee08abb2-8921-42a2-9bb9-42664c8f04f7","template_id": null,"created_at": 1539700280,"updated_at": 1539700280,"read_at": null,"deleted_by_contact_at": null,"triggered_by_user_id": "ecdeda26-882a-44cd-a320-75f9c099e0d2","triggered_by_user": {"id": "ecdeda26-882a-44cd-a320-75f9c099e0d2","email": "michael@rmmensclinic.com","first_name": "Michael","last_name": "Hudson","title": null,"username": "michael@rmmensclinic.com","avatar_uri": null},"sender_type": "service","sender": {"id": "40e821f9-db31-4da5-87da-7d2f150407cc","channel": {"type_class": "PhoneNumber","display_name": null,"value": "+17205132410","formatted_value": "(720) 513-2410"}},"recipient_type": "contact","recipient": {"id": "6021fc93-7f41-4f0a-88ae-a813432fb571","channel": {"type_class": "PhoneNumber","display_name": "(720) 299-7543","value": "+17202997543","formatted_value": "(720) 299-7543"}},"communication_direction": "outbound","attachments": [],"is_delayed": false,"execute_at": 0,"executed_at": null,"forwarded_by_service_uuid": null,"translated_body_language_code": null,"translated_body": null,"body_language_code": null}]}');}
            }
        }
        catch(Exception e){
            response = new HTTPResponse();
            response.setStatusCode(500);
            System.debug('###NetsuiteConnection.updateNetsuiteObjectSoap - Callout Exception: '+e.getMessage());
        }
        System.debug('updateNetsuiteObjectSoap-Response Status Code: ' + response.getStatusCode() + ', Response Body: ' + (String.isNotEmpty(response.getBody()) ? response.getBody().left(255) : ''));
        System.debug(response.getBody().substringBetween('<faultstring>', '</faultstring>'));
        return response;
    }

}