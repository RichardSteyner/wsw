global class NetsuiteAddressbookParser {
	public List<Link> links {get; set;}
    public List<Item> items {get; set;}
       
    public class Item{
        public List<Link> links {get;set;}
    }
    
    public class Link {
        public String rel {get; set;}
        public String href {get; set;}
    }
    
    public class AddressBookDetail{
        public List<Link> links {get;set;}
        public String id {get;set;}
        public String addressId {get;set;}
        public Boolean defaultBilling {get;set;}
        public Boolean defaultShipping {get;set;}
    }
    
    public class AddressBookAddress{
        public String addr1 {get;set;}
        public String addr2 {get;set;}
        public String addressee {get;set;}
        public String addrPhone {get;set;}
        public String city {get;set;}
        public String country {get;set;}
        public String state {get;set;}
        public String zip {get;set;}
        public String attention {get;set;}
        public String addrText {get;set;}
    }
}