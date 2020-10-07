global class NetsuiteSchedule implements Schedulable {
    
    private String startDate;
    
    global NetsuiteSchedule(){
        Datetime myDateTime = Datetime.now().addMinutes(-21);
        startDate = myDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        System.debug(startDate);
    }
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new NetsuitePostAccountsBatch(startDate), 15);
    }

}