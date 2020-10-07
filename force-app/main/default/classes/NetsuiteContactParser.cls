global class NetsuiteContactParser {
    
    public List<Link> links {get; set;}
    public String email {get; set;}
    public String entityId {get; set;}
    public String firstName {get; set;}
    public String globalsubscriptionstatus {get; set;}
    public String id {get; set;}
    public Boolean isinactive {get; set;}
    public String lastName {get; set;}
    public Integer owner {get; set;}
    public String phone {get; set;}
    public Company company {get; set;}
    public Address addressbook {get;set;}
    
    public class Address{
        public List<Link> links {get;set;}
    }
    
    public class Link {
        public String rel {get; set;}
        public String href {get; set;}
    }
    
    public class Company {
        public List<Link> links {get; set;}
        public String id {get; set;}
        public String refName {get; set;}
    }
    
    public String getCompanyId(){
        if(company!=null) return company.id;
        return null;
    }
    
    public String getLastName(){
        if(String.isNotBlank(lastName)) return lastName;
        return 'Last Null';
    }

}