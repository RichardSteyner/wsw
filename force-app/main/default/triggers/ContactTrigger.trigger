trigger ContactTrigger on Contact (after insert, after update) {    
    if(ApexUtil.isContactTriggerInvoked){
        Set<String> createContactIds = new Set<String>();
        if(trigger.isInsert){ for(Contact c : trigger.new) createContactIds.add(c.Id); }else{ for(Contact c : trigger.new) createContactIds.add(c.Id);}
        if(!createContactIds.isEmpty()) NetsuiteMethods.upsertContact(createContactIds);
    }
}