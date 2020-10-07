public class NetsuiteGetIds {

    public Netsuite__c authentication = Netsuite__c.getOrgDefaults();
    public String XML= '';
    public String Response= '';
    public String platformRelName = 'platformRel';
    public String platformRelValue = '="urn:relationships_2020_1.lists.webservices.netsuite.com"';
    public String platformRelTypeCustomer = 'platformRel:CustomerSearchAdvanced';
    public String platformRelTypeContact = 'platformRel:ContactSearchAdvanced';
    public String platformSalesTransacName = 'PlatformSalesTransac';
    public String platformSalesTransacValue = '="urn:sales_2020_1.transactions.webservices.netsuite.com"';
    public String platformSalesTransacTypeSales = 'PlatformSalesTransac:TransactionSearchAdvanced';

    public String searchId = '';
    public integer TotalPages = 0;
    public integer CurrentPage = 0;
    public integer Total = 0;
    public String typeGet = '';
    public String SOAPAction = '';
    public String lastHttpStatus = '';
    public Boolean next = false;

    public NetsuiteGetIds(String type){
        typeGet = type;
    }
    public String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    public void SetStructureXML(String HeaderNSReplace, String BodySearchReplace, String BodySearchDateReplace){
        String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String nonce = generateRandomString(10);
        String baseString = authentication.Account_Id__c + '&' + authentication.Consumer_Key__c + '&' + authentication.Token_Id__c + '&' + nonce + '&' + timestamp;
        Blob signature = Crypto.generateMac('HmacSHA256', Blob.valueOf(baseString), Blob.valueOf(authentication.Consumer_Secret__c + '&' + authentication.Token_Secret__c));


        String body;

        if(next){
            SOAPAction = 'searchMoreWithId';
            body = '<platformMsgs:searchMoreWithId>'+
                        +'<searchId>'+ searchId +'</searchId>'+
                        +'<pageIndex>'+( CurrentPage+1 )+'</pageIndex>'+
                    +'</platformMsgs:searchMoreWithId>';
            HeaderNSReplace = '';
        }else{
            String extraparam = (typeGet == 'salesorder')?('<mainLine xmlns="urn:common_2020_1.platform.webservices.netsuite.com">'+
                                '    <searchValue xmlns="urn:core_2020_1.platform.webservices.netsuite.com">true</searchValue>'+
                                '</mainLine>'+
                                '<platformCommon:type operator="anyOf">'+
                                '    <platformCore:searchValue>_salesOrder</platformCore:searchValue>'+
                                '</platformCommon:type> ') : '';
            SOAPAction = 'search';
            body = '<search>'+
                        +'<platformCore:SearchRecord xsi:type="'+BodySearchReplace+'">'+
                            +'<criteria>'+
                                +'<basic>'+ extraparam +
                                    +'<platformCommon:lastModifiedDate operator="after" xsi:type="platformCore:SearchDateField">'+
                                        '<platformCore:searchValue xsi:type="xsd:dateTime">'+BodySearchDateReplace+'</platformCore:searchValue>'+
                                    +'</platformCommon:lastModifiedDate>'+
                                +'</basic>'+
                            +'</criteria>'+
                            +'<columns>'+
                                +'<basic>'+
                                    +'<platformCommon:internalId/>'+
                                +'</basic>'+
                            +'</columns>'+
                        +'</platformCore:SearchRecord>'+
                    +'</search>';
        }

        XML = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com" '+HeaderNSReplace+' >' + 
            				'<soapenv:Header>' + 
            				'   <platformMsgs:tokenPassport>' +
            				'		<platformCore:account>' + authentication.Account_Id__c + '</platformCore:account>' + 
            				'		<platformCore:consumerKey>' + authentication.Consumer_Key__c + '</platformCore:consumerKey>' + 
            				'		<platformCore:token>' + authentication.Token_Id__c + '</platformCore:token>' + 
            				'		<platformCore:nonce>' + nonce + '</platformCore:nonce>' + 
            				'		<platformCore:timestamp>' + timestamp + '</platformCore:timestamp>' + 
            				'		<platformCore:signature algorithm="HMAC-SHA256">' + EncodingUtil.base64Encode(signature) + '</platformCore:signature>' + 
                            '   </platformMsgs:tokenPassport>' + 
                            /*'    <searchPreferences>'+
                            '        <pageSize>10</pageSize>'+
                            '    </searchPreferences>'+*/
            				'</soapenv:Header>' + 
            				'<soapenv:Body>' + 
                                body+
            				'</soapenv:Body>' + 
            			'</soapenv:Envelope>';
    }
    public String SendSearchToNetSuite(string dateSearch){
        if(typeGet != null && dateSearch!=null){
            String NS;
            switch on typeGet {
                when 'customer' {
                    NS = 'xmlns:'+platformRelName+platformRelValue;
                    SetStructureXML(NS,platformRelTypeCustomer,dateSearch);
                }
                when 'contact'{
                    NS = 'xmlns:'+platformRelName+platformRelValue;
                    SetStructureXML(NS,platformRelTypeContact,dateSearch);                    
                }
                when 'salesorder'{
                    NS = 'xmlns:'+platformSalesTransacName+platformSalesTransacValue;
                    SetStructureXML(NS,platformSalesTransacTypeSales,dateSearch);                    
                }
            }
            HttpRequest request = new HttpRequest();
            request.setEndpoint(authentication.Base_URL_Soap__c);
            request.setMethod('POST');
            request.setBody(XML);
            request.setHeader('Content-type','text/xml');
            request.setHeader('SOAPAction',SOAPAction);
            request.setTimeout(120000);
            Http http = new Http();
            HTTPResponse response;
            try{
                if(!Test.isRunningTest()){
                    response = http.send(request);
                    lastHttpStatus = String.valueOf(response.getStatusCode());
                    return response.getBody();
                } else {
                    response = new HTTPResponse();
                    lastHttpStatus = '200';
                    response.setBody('<?xml version="1.0" encoding="UTF-8"?> <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> <soapenv:Header> <platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com"> <platformMsgs:nsId>WEBSERVICES_1030411_0815202017839218274886207_98696b16f8d753</platformMsgs:nsId> </platformMsgs:documentInfo> </soapenv:Header> <soapenv:Body> <searchResponse xmlns=""> <platformCore:searchResult xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"> <platformCore:status isSuccess="true"/> <platformCore:totalRecords>89</platformCore:totalRecords> <platformCore:pageSize>10</platformCore:pageSize> <platformCore:totalPages>1</platformCore:totalPages> <platformCore:pageIndex>1</platformCore:pageIndex> <platformCore:searchId>WEBSERVICES_1030411_0815202017839218274886207_98696b16f8d753</platformCore:searchId> <platformCore:searchRowList> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="4323"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T13:10:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="4699"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-14T17:04:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="46099"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T10:26:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="53993"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T11:07:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65121"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-14T19:55:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65178"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-14T19:58:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65283"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-14T20:16:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65343"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T07:14:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65411"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T07:15:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> <platformCore:searchRow xsi:type="listRel:CustomerSearchRow" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com"> <listRel:basic xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com"> <platformCommon:internalId> <platformCore:searchValue internalId="65563"/> </platformCommon:internalId> <platformCommon:lastModifiedDate> <platformCore:searchValue>2020-08-15T07:18:00.000-07:00</platformCore:searchValue> </platformCommon:lastModifiedDate> </listRel:basic> </platformCore:searchRow> </platformCore:searchRowList> </platformCore:searchResult> </searchResponse> </soapenv:Body> </soapenv:Envelope>');
                    return response.getBody();
                }
            }
            catch(Exception e){
                lastHttpStatus = '500';
                System.debug('###NetSuiteGetIds.SendSearchToNetSuite - Callout Exception: ' + e.getLineNumber() + '-' +e.getMessage());
            }
            System.debug('SendSearchToNetSuite-Response Status Code: ' + response.getStatusCode() + ', Response Body: ' + (String.isNotEmpty(response.getBody()) ? response.getBody().left(255) : ''));
            System.debug(response.getBody().substringBetween('<faultstring>', '</faultstring>'));
        }
        return null;
    }

    public List<String> processXML(String responseXML){
        List<String> Ids = new List<String>();

        Dom.Document doc = new Dom.Document();
        doc.load(responseXML);
        Dom.XMLNode root = doc.getRootElement();
        String rootNS = root.getNameSpace();
        Dom.XMLNode body = root.getChildElement('Body',rootNS);
        Dom.XMLNode searchResult = body.getChildElements().get(0).getChildElements().get(0);
        String platformCore = searchResult.getNameSpace();

        Dom.XMLNode[] searchRowList = searchResult.getChildElement('searchRowList',platformCore).getChildElements();
        for(Dom.XMLNode searchRow : searchRowList){
            Dom.XMLNode searchValue = searchRow.getChildElements().get(0).getChildElements().get(0).getChildElement('searchValue',platformCore);
            if(searchValue != null){
                Ids.add(searchValue.getAttributeValue('internalId',null));
            }
        }
        if(searchResult.getChildElement('pageIndex',platformCore)!=null){
            CurrentPage = Integer.valueOf(searchResult.getChildElement('pageIndex',platformCore).getText());
            System.debug(CurrentPage);
        }

        return ids;
    }

    public list<String> getUpdatedIds(string dateSearch){
        List<String> Ids,aux = new List<String>();
        CurrentPage = 1;
        String responseXML = SendSearchToNetSuite(dateSearch);
        if(lastHttpStatus == '200'){
            searchId = responseXML.substringBetween('<platformCore:searchId>', '</platformCore:searchId>');
            totalPages = Integer.valueOf(responseXML.substringBetween('<platformCore:totalPages>', '</platformCore:totalPages>'));        
            Total = Integer.valueOf(responseXML.substringBetween('<platformCore:totalRecords>', '</platformCore:totalRecords>'));
            Ids = processXML(responseXML);
            next = (totalPages != CurrentPage)? true : false;
            System.debug(totalPages);

            for(Integer i = 1 ; i < totalPages ; i++){
                responseXML = SendSearchToNetSuite(dateSearch);
                aux = processXML(responseXML);
                ids.addAll(aux);
            }
        }else{
            System.debug(lastHttpStatus);
        }

        return Ids;
    }

}