public class SFS_RA_ConstantsUtil {
    
    public static final String AM_CONTROLLER_RECORD = 'Controller Record';
    public static final String AM_TERRITORY_DECOMPOSITION = 'Territory Decomposition';
    public static final String SA_STATUS = 'Status';
    
    public static final String WO_STATUS_OPEN = 'Open';
    public static final String SA_STATUS_OPEN = 'Open';
    public static final String SA_STATUS_DISPATCHED = 'Dispatched';
    public static final String SA_STATUS_SCHEDULED = 'Scheduled';
    
    public static final String SA_BLANK_QUERY = 'SELECT ID FROM ServiceAppointment WHERE createdDate > today';
    public static final String AR_BLANK_QUERY = 'SELECT ID FROM AssignedResource WHERE createdDate > today';
    
    //For JEeopardy Agent Changes
    public static final String AM_AGENT_TYPE_JEOPARDY = 'Jeopardy Agent';
    //For Drip Feed Changes
    public static final String AM_AGENT_TYPE_DRIP_FEED = 'Drip Feed';
    //For Bulk Feed Changes
    public static final String AM_AGENT_TYPE_BULK_FEED = 'Bulk Feed';
  
}