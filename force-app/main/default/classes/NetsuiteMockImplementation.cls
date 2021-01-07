@isTest
global class NetsuiteMockImplementation implements HttpCalloutMock{

   	public static HTTPResponse respond(HTTPRequest request) {
   		HttpResponse response = new HttpResponse();
        String xmlBody;
        system.debug('enter mock');
		if((request.getBody().contains('<get>') && (request.getBody().contains('type="salesOrder"') || request.getBody().contains('type="estimate"'))) ||  
          (request.getBody().contains('<add>') && request.getBody().contains('xsi:type="tranSales:Estimate"'))
          ){
              system.debug('enter DATA');
			response.setHeader('Content-Type', 'text/xml;charset=utf-8');
            xmlBody = '<?xml version="1.0" encoding="UTF-8"?>'+
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
                							'<tranSales:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:customField internalId="87" scriptId="custbody_ozlink_bill_shipping_to_recip" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1643" scriptId="custbodyfulfillment_email" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5920" scriptId="custbody_ca_cert_status" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>F</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5989" scriptId="custbodycustentity_order_conf_email" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>ctremper83@testing.com;</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="4546" scriptId="custbody_allgraphicsapproved" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6434" scriptId="custbody_ava_taxoverride" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5881" scriptId="custbody_cbackproofapproved" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1580" scriptId="custbody61" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>bj@wsdisplay.com</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2254" scriptId="custbody_transaction_cnfo_email_chck" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>true</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2711" scriptId="custbodymaincompanyaddress" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>Mr. Jones TestingXperts 1000 main Street Austin CA 92231</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="4550" scriptId="custbody_allgraphicssent" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2149" scriptId="custbody_artfile_by_email" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2707" scriptId="custbodycustomernotes" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>Notes go here</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2726" scriptId="custbody_quickproofemailsent" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="1">'+
                                                        '<platformCore:name>Net Amount</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="116" scriptId="custbody17" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="70" scriptId="custbody11" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="3" typeId="21">'+
                                                        '<platformCore:name>Graphics</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="66" scriptId="custbody10" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>WO98232</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="76" scriptId="custbody13" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5943" scriptId="custbody_graphicapprovalscreated" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5990" scriptId="custbody_multi_order_conf_email" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5866" scriptId="custbody_cr_status" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="1" typeId="-160">'+
                                                        '<platformCore:name>Auto</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1194" scriptId="custbody_sc_buyers_email" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>ctremper83@testing.com</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5932" scriptId="custbody_readytoprint" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6018" scriptId="custbody_verifiedinproduction" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="145" scriptId="custbody_ozlink_websitelink" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>http://www.ozlinkshipping.com</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5896" scriptId="custbody_split_order" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="3115" scriptId="custbody_ava_shiptousecode" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="54" typeId="488">'+
                                                        '<platformCore:name>Z</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5922" scriptId="custbody_art_file_exemption" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1394" scriptId="custbody_sc_third_party_billing" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="88" scriptId="custbody_ozlink_bill_shipping_to_3rd" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6065" scriptId="custbody_numtouches" xsi:type="platformCore:LongCustomFieldRef">'+
                                                    '<platformCore:value>0</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2709" scriptId="custbodymaincompanyemail" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>ctremper83@testing.com</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5925" scriptId="custbody_sentprodauto" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6195" scriptId="custbody_donotautoassignqueue" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="4555" scriptId="custbody_disabledqpzcust" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="22" scriptId="custbody_esc_created_date" xsi:type="platformCore:DateCustomFieldRef">'+
                                                    '<platformCore:value>2020-12-04T00:00:00.000-08:00</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2363" scriptId="custbody_check_productreview_email" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="43" scriptId="custbody1" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="6" typeId="-186">'+
                                                        '<platformCore:name>WS Display</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="56" scriptId="custbody3" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="103073" typeId="-4">'+
                                                        '<platformCore:name>BJ Sansano</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="60" scriptId="custbody4" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>test</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1392" scriptId="custbody_sc_bill_to_receiver" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5771" scriptId="custbodycheckedbybusinessdev" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6064" scriptId="custbody_touchedbygraphics" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="61" scriptId="custbody5" xsi:type="platformCore:StringCustomFieldRef">'+
                                                    '<platformCore:value>SO-540086</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="65" scriptId="custbody9" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="236789" typeId="-4">'+
                                                        '<platformCore:name>Arlene Velazquez</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="6817" scriptId="custbody_ava_taxdateoverride" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="1611" scriptId="custbodysend_email_after_g_approve" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="21" scriptId="custbody_esc_last_modified_date" xsi:type="platformCore:DateCustomFieldRef">'+
                                                    '<platformCore:value>2021-01-06T00:00:00.000-08:00</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2718" scriptId="custbody88" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="2261" scriptId="custbody83" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="2" typeId="400">'+
                                                        '<platformCore:name>File needs to be prepped</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="45" scriptId="custbody_orderstatus" xsi:type="platformCore:SelectCustomFieldRef">'+
                                                    '<platformCore:value internalId="15" typeId="18">'+
                                                        '<platformCore:name>Manufacturing</platformCore:name>'+
                                                    '</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="4108" scriptId="custbody91" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="4227" scriptId="custbody92" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="3147" scriptId="custbody_ava_is_sellerimporter" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                                '<platformCore:customField internalId="5864" scriptId="custbody94" xsi:type="platformCore:BooleanCustomFieldRef">'+
                                                    '<platformCore:value>false</platformCore:value>'+
                                                '</platformCore:customField>'+
                                            '</tranSales:customFieldList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
	        response.setBody(xmlBody);
	        response.setStatusCode(200);
	        response.setStatus('OK');
		}
        if((request.getBody().contains('<get>') && request.getBody().contains('type="contact"')) || ((request.getBody().contains('<add>') || request.getBody().contains('<update>')) && request.getBody().contains('xsi:type="listRel:Contact"'))){
            system.debug('enter contact');
			response.setHeader('Content-Type', 'text/xml;charset=utf-8');
            xmlBody = '<?xml version="1.0" encoding="UTF-8"?>'+
                        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                            '<soapenv:Header>'+
                                '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                    '<platformMsgs:nsId>WEBSERVICES_1030411_01062021662119770930914980_a9c4c3e35b27f</platformMsgs:nsId>'+
                                '</platformMsgs:documentInfo>'+
                            '</soapenv:Header>'+
                            '<soapenv:Body>'+
                                '<getResponse xmlns="">'+
                                    '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                        '<platformMsgs:record internalId="243463" xsi:type="listRel:Contact" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">'+
                                            '<listRel:customForm internalId="22" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>Custom Contact Form</platformCore:name>'+
                                            '</listRel:customForm>'+
                                            '<listRel:entityId>Test Cloud 4.2x</listRel:entityId>'+
                                            '<listRel:company internalId="241248" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>61093 Cloud Test 4</platformCore:name>'+
                                            '</listRel:company>'+
                                            '<listRel:salutation>Ms.</listRel:salutation>'+
                                            '<listRel:firstName>Test</listRel:firstName>'+
                                            '<listRel:lastName>Cloud 4.2x</listRel:lastName>'+
                                            '<listRel:title>title test</listRel:title>'+
                                            '<listRel:phone>993-436-5625</listRel:phone>'+
                                            '<listRel:fax>993-436-5627</listRel:fax>'+
                                            '<listRel:email>test42@cloudcreations.com</listRel:email>'+
                                            '<listRel:defaultAddress></listRel:defaultAddress>'+
                                            '<listRel:isPrivate>false</listRel:isPrivate>'+
                                            '<listRel:isInactive>false</listRel:isInactive>'+
                                            '<listRel:altEmail>test42alt@cloudcreations.com</listRel:altEmail>'+
                                            '<listRel:officePhone>993-436-5621</listRel:officePhone>'+
                                            '<listRel:homePhone>993-436-5629</listRel:homePhone>'+
                                            '<listRel:mobilePhone>993-436-5628</listRel:mobilePhone>'+
                                            '<listRel:globalSubscriptionStatus>_softOptIn</listRel:globalSubscriptionStatus>'+
                                            '<listRel:dateCreated>2020-11-23T13:46:55.000-08:00</listRel:dateCreated>'+
                                            '<listRel:lastModifiedDate>2020-11-23T15:54:31.000-08:00</listRel:lastModifiedDate>'+
                                            '<listRel:customFieldList xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:customField internalId="20" scriptId="custentity_esc_last_modified_date" xsi:type="platformCore:DateCustomFieldRef">'+
                                                    '<platformCore:value>2020-11-23T00:00:00.000-08:00</platformCore:value>'+
                                                '</platformCore:customField>'+
                                            '</listRel:customFieldList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
	        response.setBody(xmlBody);
	        response.setStatusCode(200);
	        response.setStatus('OK');
		}
        if((request.getBody().contains('<get>') && request.getBody().contains('type="customer"')) || ((request.getBody().contains('<add>') || request.getBody().contains('<update>')) && request.getBody().contains('xsi:type="listRel:Customer"'))){
            system.debug('enter contact');
			response.setHeader('Content-Type', 'text/xml;charset=utf-8');
            xmlBody = '<?xml version="1.0" encoding="UTF-8"?>'+
                        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'+
                            '<soapenv:Header>'+
                                '<platformMsgs:documentInfo xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                    '<platformMsgs:nsId>WEBSERVICES_1030411_01062021659405170910233556_16a99a9ceff61</platformMsgs:nsId>'+
                                '</platformMsgs:documentInfo>'+
                            '</soapenv:Header>'+
                            '<soapenv:Body>'+
                                '<getResponse xmlns="">'+
                                    '<platformMsgs:readResponse xmlns:platformMsgs="urn:messages_2020_1.platform.webservices.netsuite.com">'+
                                        '<platformCore:status isSuccess="true" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com"/>'+
                                        '<platformMsgs:record internalId="243631" xsi:type="listRel:Customer" xmlns:listRel="urn:relationships_2020_1.lists.webservices.netsuite.com">'+
                                            '<listRel:customForm internalId="117" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>WS: Customer Form</platformCore:name>'+
                                            '</listRel:customForm>'+
                                            '<listRel:entityId>61208 TestingXperts</listRel:entityId>'+
                                            '<listRel:isPerson>false</listRel:isPerson>'+
                                            '<listRel:companyName>TestingXperts</listRel:companyName>'+
                                            '<listRel:entityStatus internalId="13" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>CUSTOMER-Closed Won</platformCore:name>'+
                                            '</listRel:entityStatus>'+
                                            '<listRel:email>ctremper83@testing.com</listRel:email>'+
                                            '<listRel:url>https://www.testingxperts.com/</listRel:url>'+
                                            '<listRel:defaultAddress></listRel:defaultAddress>'+
                                            '<listRel:isInactive>false</listRel:isInactive>'+
                                            '<listRel:dateCreated>2020-12-03T13:31:54.000-08:00</listRel:dateCreated>'+
                                            '<listRel:emailPreference>_default</listRel:emailPreference>'+
                                            '<listRel:partner internalId="237400" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">'+
                                                '<platformCore:name>074 Victoria M Rodriguez</platformCore:name>'+
                                            '</listRel:partner>'+
                                            '<listRel:taxExempt>false</listRel:taxExempt>'+
                                            '<listRel:creditHoldOverride>_auto</listRel:creditHoldOverride>'+
                                            '<listRel:overrideCurrencyFormat>false</listRel:overrideCurrencyFormat>'+
                                            '<listRel:displaySymbol>$</listRel:displaySymbol>'+
                                            '<listRel:symbolPlacement>_beforeNumber</listRel:symbolPlacement>'+
                                            '<listRel:balance>0.0</listRel:balance>'+
                                            '<listRel:overdueBalance>0.0</listRel:overdueBalance>'+
                                            '<listRel:unbilledOrders>1044.63</listRel:unbilledOrders>'+
                                            '<listRel:consolUnbilledOrders>1044.63</listRel:consolUnbilledOrders>'+
                                            '<listRel:consolOverdueBalance>0.0</listRel:consolOverdueBalance>'+
                                            '<listRel:consolDepositBalance>0.0</listRel:consolDepositBalance>'+
                                            '<listRel:consolBalance>0.0</listRel:consolBalance>'+
                							'<listRel:addressbookList>'+
                                                '<listRel:addressbook>'+
                                                    '<listRel:defaultShipping>true</listRel:defaultShipping>'+
                                                    '<listRel:defaultBilling>false</listRel:defaultBilling>'+
                                                    '<listRel:isResidential>false</listRel:isResidential>'+
                                                    '<listRel:label>235 W Woodin Blvd</listRel:label>'+
                                                    '<listRel:addressbookAddress xmlns:platformCommon="urn:common_2020_1.platform.webservices.netsuite.com">'+
                                                        '<platformCommon:country>_unitedStates</platformCommon:country>'+
                                                        '<platformCommon:addr1>235 W Woodin Blvd</platformCommon:addr1>'+
                                                        '<platformCommon:city>Austin</platformCommon:city>'+
                                                        '<platformCommon:state>TX</platformCommon:state>'+
                                                        '<platformCommon:zip>78665</platformCommon:zip>'+
                                                        '<platformCommon:addrText>235 W Woodin Blvd</platformCommon:addrText>'+
                                                        '<platformCommon:override>false</platformCommon:override>'+
                                                    '</listRel:addressbookAddress>'+
                                                    '<listRel:internalId>782255</listRel:internalId>'+
                                                '</listRel:addressbook>'+
                                            '</listRel:addressbookList>'+
                                        '</platformMsgs:record>'+
                                    '</platformMsgs:readResponse>'+
                                '</getResponse>'+
                            '</soapenv:Body>'+
                        '</soapenv:Envelope>';
	        response.setBody(xmlBody);
	        response.setStatusCode(200);
	        response.setStatus('OK');
		}
		return response;
   	}

}