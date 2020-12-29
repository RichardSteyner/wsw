public class ApexUtil {
    
    public static Boolean isLeadTriggerInvoked = true;
    public static Boolean isAccountTriggerInvoked = true;
    public static Boolean isContactTriggerInvoked = true;
    public static Boolean isOpportunityTriggerInvoked = true;
    public static Boolean isAddressTriggerInvoked = true;
    public static Boolean isOliTriggerInvoked = true;
    public static Map<String, String> globalSubscriptionStatusContact = new Map<String, String>{'1'=>'_softOptIn', '2'=>'_softOptOut', '3'=>'_confirmedOptIn', '4'=>'_confirmedOptOut'};
    
    /*public static String getFieldSelectNetsuiteXML(String fieldSF, String fieldNetsuite, String pref){
        String resultXML='', resultId='', resultText='';
        resultId = fieldSF != null ? fieldSF.substringBetween('<', '>') : null;
        if(resultId!=null){
        	resultText = fieldSF.substringAfter('>').trim();
            resultXML = '		<' + pref + ':' + fieldNetsuite + ' internalId="' + resultId + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com">' +
                    	'			<platformCore:name>' + resultText + '</platformCore:name>' +
                		'		</' + pref + ':' + fieldNetsuite + '>';
        }else{
        	resultXML = '';
        }
        return resultXML;
    }*/
    
    public static String getFieldSettingNetsuiteXML(String typez,Map<String,Object> customMap,String fieldSF, String fieldNetsuite, String pref){
        String resultXML = '', resultId, resultText;
        if(fieldSF != null && fieldSF != ''){
            resultId = null;
            if(typez == 'customer'){
                NetsuiteLead__c obj;
                for(Object nsl : customMap.values()){
                    obj = (NetsuiteLead__c) nsl;
                    if(fieldNetsuite == 'leadSource' && obj.Type__c == 'LeadSource' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'prefCCProcessor' && obj.Type__c == 'CCProcessor' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'priceLevel' && obj.Type__c == 'PriceLevel' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'entityStatus' && obj.Type__c == 'EntityStatus' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'partner' && obj.Type__c == 'Partner' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'terms' && obj.Type__c == 'Terms' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'taxItem' && obj.Type__c == 'TaxItem' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'salesRep' && obj.Type__c == 'SalesRep' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }
                }
            }else if(typez == 'order'){
                NetsuiteOpp__c obj;
                for(Object nsl : customMap.values()){
                    obj = (NetsuiteOpp__c) nsl;
                    if(fieldNetsuite == 'shipMethod' && obj.Type__c == 'ShipMethod' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }
                }
            }
            if(resultId!=null){
                resultXML = '<' + pref + ':' + fieldNetsuite + ' internalId="' + resultId + '" xmlns:platformCore="urn:core_2020_1.platform.webservices.netsuite.com" />';
                    //'			<platformCore:name>' + resultText + '</platformCore:name>' +
                    //'		</' + pref + ':' + fieldNetsuite + '>';
            }
        }
        return resultXML;
    }
    
    /*public static String getFieldCustomSelectNetsuiteXML(String fieldSF, String fieldNetsuite, String internalId, String typeId){
        String resultXML='', resultId='', resultText='';
        resultId = fieldSF != null ? fieldSF.substringBetween('<', '>') : null;
        if(resultId!=null){
        	resultText = fieldSF.substringAfter('>').trim();
            resultXML = '			<platformCore:customField internalId="' + internalId +'" scriptId="' + fieldNetsuite + '" xsi:type="platformCore:SelectCustomFieldRef">' + 
                          '               <platformCore:value internalId="' + resultId + '" typeId="' + typeId + '">' +
                          '                   <platformCore:name>' + resultText + '</platformCore:name>' +
                          '               </platformCore:value>' +
                          '           </platformCore:customField>';
        }else{
        	resultXML = '';
        }
        return resultXML;
    }*/
    
    public static String getFieldSettingCustomSelectNetsuiteXML(String typez, Map<String,Object> customMap,String fieldSF, String fieldNetsuite, String internalId, String typeId){
        String resultXML='', resultId, resultText;
        Boolean isMultiPicklist;
        if(fieldSF != null && fieldSF != ''){
            resultId = null;
            isMultiPicklist = false;
            if(typez == 'customer'){
                NetsuiteLead__c obj;
                for(Object nsl : customMap.values()){
                    obj = (NetsuiteLead__c) nsl;
                    if(fieldNetsuite == 'custentity_esc_industry' && obj.Type__c == 'Industry' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentity_typeofcustomer' && obj.Type__c == 'TypeOfCustomer' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentity2' && obj.Type__c == 'Association' && fieldSF != null){
                        for(String fsplit : fieldSF.split(';')){
                            if(obj.Value__c == fsplit) resultId = (resultId != null ? resultId + ';' : '') + obj.ID__c;
                        }                        
                        isMultiPicklist = true;
                    }else if(fieldNetsuite == 'custentity_ws_accnt_aprvl_prcs' && obj.Type__c == 'ApprovalProcess' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentitycustentity_certificate_app_by' && obj.Type__c == 'Employee' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentity45' && obj.Type__c == 'Employee' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentitylead_survey' && obj.Type__c == 'HowDidYourHear' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custentitylead_survey_tradeshow_value' && obj.Type__c == 'HowDidYourHearTradeShow' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }
                }
            }else if(typez == 'order'){
                NetsuiteOpp__c obj;
                for(Object nsl : customMap.values()){
                    obj = (NetsuiteOpp__c) nsl;
                    if(fieldNetsuite == 'custbody11' && obj.Type__c == 'OrderDetail' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }else if(fieldNetsuite == 'custbody_orderstatus' && obj.Type__c == 'Stage' && obj.Value__c == fieldSF){
                        resultId = obj.ID__c;
                        resultText = obj.Value__c;
                        break;
                    }
                }
            }
            if(resultId!=null){
                if(isMultiPicklist){
                    resultXML = '<platformCore:customField internalId="' + internalId +'" scriptId="' + fieldNetsuite + '" xsi:type="platformCore:MultiSelectCustomFieldRef">';
                    for(String split : resultId.split(';')) resultXML += '<platformCore:value internalId="' + split + '" typeId="' + typeId + '" />';
                    resultXML += '</platformCore:customField>';
                }else{
                    resultXML = '			<platformCore:customField internalId="' + internalId +'" scriptId="' + fieldNetsuite + '" xsi:type="platformCore:SelectCustomFieldRef">' + 
                    '               <platformCore:value internalId="' + resultId + '" typeId="' + typeId + '" />' +
                    //'                   <platformCore:name>' + resultText + '</platformCore:name>' +
                    //'               </platformCore:value>' +
                    '           </platformCore:customField>';
                }
            }
        }
        return resultXML;
    }

}