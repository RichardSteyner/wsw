global class NetsuiteSchedule implements Schedulable {
    private String startDate;
    global NetsuiteSchedule(){
        Datetime myDateTime = Datetime.now().addDays(-1).addHours(-1);
        startDate = myDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        System.debug(startDate);
    }
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new NetsuiteGetSalesOrderBatch(startDate), 10);
    }
}