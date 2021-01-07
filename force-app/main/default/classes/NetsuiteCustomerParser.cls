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
    public AssociationCustomer custentity2 {get;set;}
    public Partner partner {get;set;}
    public String custentitysalesordernotes {get;set;}
    public String altPhone {get;set;}
    public String fax {get;set;}
    public String email {get;set;}
    public String custentity_invoice_email {get;set;}
    public String custentity_order_conf_email {get;set;}
    public Decimal custentity_esc_annual_revenue {get;set;}
    public DataField custentity_ws_accnt_aprvl_prcs {get;set;}
    public String custentity25 {get;set;}
    public Boolean custentity9 {get;set;}
    public Decimal creditLimit {get;set;}
    public DataField terms {get;set;}
    public String vatRegNumber {get;set;}
    public DataField taxItem {get;set;}
    public String resaleNumber {get;set;}
    public String custentity_resale_cert_newuser {get;set;}
    public DataField custentitycustentity_certificate_app_by {get;set;}
    public DataField custentity45 {get;set;}
    public DataField custentitylead_survey {get;set;}
    public DataField custentitylead_survey_tradeshow_value {get;set;}
    public AddressBook addressBook {get;set;}
    
    public class AddressBook{
        public List<Link> links {get;set;}
    }
    
    public class DataField {
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String refName {get;set;}
    }
    
    public class Partner{
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String refName {get;set;}
    }
    
    public class Association{
        public List<AssocItem> items {get;set;}
    }
    
    public class AssocItem{
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String refName {get;set;}
    }
    
    public class AssociationCustomer{
        public List<Link> links {get;set;}
    }
    
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
    
    public class SalesRep {
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
}