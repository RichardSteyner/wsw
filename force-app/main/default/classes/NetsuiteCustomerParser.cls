global class NetsuiteCustomerParser {
    
    public List<Link> links {get; set;}
    public String companyName {get; set;}//
    public Custentity_esc_industry custentity_esc_industry {get; set;}//
    public Integer custentity_esc_no_of_employees {get; set;}//
    public Boolean custentity_exhibit_catalog {get; set;}//
    public Boolean custentity_firstorder_email {get; set;}//
    public Boolean custentity_resort_catalog {get; set;}//
    public Boolean taxable {get; set;}//
    public Boolean custentity_sc_web_approved {get; set;}//
    public Custentity_typeofcustomer custentity_typeofcustomer {get; set;}
    public String defaultAddress {get; set;}//
    public LeadSource leadSource {get; set;}
    public String phone {get; set;}//
    public PrefCcProcessor prefCcProcessor {get; set;}
    public PriceLevel priceLevel {get; set;}
    public String url {get; set;}//
    public EntityStatus entityStatus {get; set;}
    public SalesRep salesRep {get; set;}
    public Parent parent {get; set;}
    public Boolean custentity_ozlink_bill_shipping_to_3rd {get; set;}//
    public Boolean custentity_ozlink_bill_shipping_to_recip {get; set;}//
    public String custentity_ozlink_website {get; set;}//
    public String id {get; set;}
    public ContactZ contact {get;set;}
    
    public class ContactZ{
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String refName {get;set;}
    }
    
    public class Link {
        public String rel {get; set;}
        public String href {get; set;}
    }
    
    class Custentity_esc_industry {
       	public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Custentity_typeofcustomer {
       	public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class LeadSource {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class PrefCcProcessor {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class PriceLevel {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class EntityStatus {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class SalesRep {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Parent {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    public String getIndustry(){
        if(custentity_esc_industry!=null)
            return '<' + custentity_esc_industry.id + '> ' + custentity_esc_industry.refName;
        return null;
    }
    
    public String getTypeOfCustomer(){
        if(custentity_typeofcustomer!=null)
            return '<' + custentity_typeofcustomer.id + '> ' + custentity_typeofcustomer.refName;
        return null;
    }
    
    public Boolean getWSPrime(){
        return leadSource!=null && leadSource.refName!=null & leadSource.refName.trim().equalsIgnoreCase('4 WSPrime Preferred Customer');
    }
    
    public String getLeadSource(){
        if(leadSource!=null)
            return '<' + leadSource.id + '> ' + leadSource.refName;
        return null;
    }
    
    public String getCCProcessor(){
        if(prefCcProcessor!=null)
            return '<' + prefCcProcessor.id + '> ' + prefCcProcessor.refName;
        return null;
    }
    
    public String getPriceLevel(){
        if(priceLevel!=null)
        	return '<' + priceLevel.id + '> ' + priceLevel.refName;
        return null;
    }
    
    public String geEntityStatus(){
        if(entityStatus!=null)
            return '<' + entityStatus.id + '> ' + entityStatus.refName;
        return null;
    }
    
    public String getParentId(){
        if(parent!=null)
            return parent.id;
        return null;
    }
    
    public String getParentName(){
        if(parent!=null)
            if(String.isNotBlank(parent.refName))
            	return parent.refName;
        return 'Parent Name';
    }
    
    public String getSalesRepId(){
        return salesRep!=null ? salesRep.id : null;
    }
    
    /*
    public Custentity5 custentity5 {get; set;}
    public Boolean custentity50 {get; set;}
    public Boolean custentity52 {get; set;}
    public Boolean custentity53 {get; set;}
    public Boolean custentity8 {get; set;}
    public Boolean custentity9 {get; set;}
    public Boolean custentity_am_survey_sent {get; set;}
    public Boolean custentity_avataxaddresseshandled {get; set;}
    public Boolean custentity_customer_agree_terms {get; set;}
    public Boolean custentity_customer_sent_catalogs {get; set;}
    public Boolean custentity_disablequickproofs {get; set;}
    public Boolean custentity_esc_annual_revenue {get; set;}
    public AccessRole accessRole {get; set;}
    public Addressbook addressbook {get; set;}
    public String alcoholRecipientType {get; set;}
    public Integer balance {get; set;}
    public CampaignCategory campaignCategory {get; set;}
    public String comments {get; set;}
    public Integer consolbalance {get; set;}
    public Integer consoldepositbalance {get; set;}
    public Integer consoloverduebalance {get; set;}
    public Integer consolunbilledorders {get; set;}
    public CreditCards creditCards {get; set;}
    public ContactRole contactRoles {get; set;}
    public String creditholdoverride {get; set;}
    public Integer currencyPrecision {get; set;}
    public Boolean custentity10 {get; set;}
    public Boolean custentity11 {get; set;}
    public Boolean custentity12 {get; set;}
    public Boolean custentity13 {get; set;}
    public Boolean custentity14 {get; set;}
    public Boolean custentity15 {get; set;}
    public Boolean custentity16 {get; set;}
    public Boolean custentity17 {get; set;}
    public Boolean custentity18 {get; set;}
    public Boolean custentity19 {get; set;}
    public Custentity2 custentity2 {get; set;} 
	public String custentity_esc_last_modified_date {get; set;}
    public Boolean custentity_finish_photo {get; set;}
    public String custentity_linktoresalecert {get; set;}
    public Boolean custentity_multi_email_request {get; set;}
    public Boolean custentity_notaxstates_doc_checkbox {get; set;}
    public Boolean custentity_one_choice_catalog {get; set;}
    public Boolean custentity_sc_partner_email_sent {get; set;}
    public Boolean custentity_sc_send_reset_password_email {get; set;}
    public Boolean custentity_sdr_apply_coupon {get; set;}
    public Boolean custentity_sent_email_overdueterm {get; set;}
    public String custentity_total_onechoice_transaction {get; set;}
    public String custentity_total_transactions {get; set;}
    public Boolean custentity_ws_catalog {get; set;}
    public Custentitycustomersurveystatus custentitycustomersurveystatus {get; set;}

	
    
    class Addressbook {
        public List<Link> links {get; set;}
    }
    
    class ContactRole {
        public List<Link> links {get; set;}
    }
    
    class CreditCards {
        public List<Link> links {get; set;}
    }
    
    class Custentity2 {
       	public List<Link> links {get; set;}
    }
    
    class Custentity5 {
       	public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Custentitycustomersurveystatus {
       	public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
	*/

}