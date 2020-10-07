public class NetsuiteSalesOrderParser {
    
    public List<Link> links {get; set;}
    public Decimal balance {get; set;}
    public String custbody10 {get; set;}
    public Custbody11 custbody11 {get; set;}
    public Custbody3 custbody3 {get; set;}
    public String custbody5 {get; set;}
    public String custbody8 {get; set;}
    public Custbody9 custbody9 {get; set;}
    public Boolean custbody_artfile_by_email {get; set;}
    public Custbody_orderstatus custbody_orderstatus {get; set;}
    public Department department {get; set;}
    public String email {get; set;}
    public Decimal discountTotal {get; set;}
    public Entity entity {get; set;}
    public String id {get; set;}
    public Item item {get;set;}
    public SalesRep salesRep {get; set;}
    public Date shipDate {get; set;}
    public ShipMethod shipMethod {get; set;}
    public Decimal shippingCost {get; set;}
    public String status {get; set;}
    public Decimal subtotal {get; set;}
    public Decimal taxTotal {get; set;}
    public Date trandate {get; set;}
    public String tranId {get; set;}
    public Decimal total {get;set;}
    
    public class Item {
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String refName {get;set;}
    }
    
    public class Link {
        public String rel {get; set;}
        public String href {get; set;}
    }
    
    class Custbody11 {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Custbody3 {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Custbody9 {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Custbody_orderstatus {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class Department {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    public class Entity {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class SalesRep {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    class ShipMethod {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    public String getOrderDetail(){
        if(custbody11!=null)
            return '<' + custbody11.id + '> ' + custbody11.refName;
        return null;
    }
    
    public String getStage(){
        if(custbody_orderstatus!=null && custbody_orderstatus.refName!=null)
            return '<' + custbody_orderstatus.id + '> ' + custbody_orderstatus.refName;
        return 'Negotiation';
    }
    
    public String getDepartment(){
        if(department!=null)
            return '<' + department.id + '> ' + department.refName;
        return null;
    }
    
    public String getEntityId(){
        if(entity!=null)
            return entity.Id;
        return null;
    }
    
    public String getShipMethod(){
        if(shipMethod!=null)
            return '<' + shipMethod.id + '> ' + shipMethod.refName;
        return null;
    }
    
    public String getWarehouseNotes(){
    	return custbody8!=null? custbody8.left(255) : custbody8;
    }
    
    public String getWebOrderNumber(){
    	return custbody10!=null? custbody10.left(255) : custbody10;
    }
    
    public String getCustbody3Id(){
        return custbody3!=null ? custbody3.id : null;
    }
    
    public String getCustbody9Id(){
        return custbody9!=null ? custbody9.id : null;
    }
    
    public String getSalesRepId(){
        return salesRep!=null ? salesRep.id : null;
    }

    public class RelatedList{
        public List<Link> links {get;set;}
        public List<ItemLink> items {get;set;}
    }
    
    public class ItemLink{
        public List<Link> links {get;set;}
    }
    
    public class ItemDetail{
        public String id {get;set;}
        public Decimal amount {get;set;}
        public String description {get;set;}
        public Item item {get;set;}
        public String itemType {get;set;}
        public Integer line {get;set;}
        public Decimal quantity {get;set;}
        public Decimal quantityAvailable {get;set;}
        public Decimal quantityBackOrdered {get;set;}
        public Decimal rate {get;set;}
        public Item custcol_item_brand {get;set;}
    }
}