global class NetsuiteListParser {
    
    public List<Link> links {get; set;}
    public Integer count {get; set;}
    public Boolean hasMore {get; set;}
    public List<Item> items {get; set;}
    
    public class Link {
        public String rel {get; set;} //previous, first, next, last, self
        public String href {get; set;}
    }
    
    public class Item {
        public List<Link> links {get; set;}
        public String id {get; set;}
    }

}