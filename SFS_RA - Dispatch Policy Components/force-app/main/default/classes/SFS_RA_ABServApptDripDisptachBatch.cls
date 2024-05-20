/**
 * @description       : Make status of scheduled appointments from Scheduled to Dispatch where the assigned resource is having Drip feed as dispatch policy.
 * @author            : Laxman Singh/ Ankit Chawla
 **/
public class SFS_RA_ABServApptDripDisptachBatch implements Database.Batchable<sObject>, Database.Stateful, Database.RaisesPlatformEvents{
    
    Map<String, List<SFS_RA_Agent_Manager_Entry__c>> mapOfAgentManagerStateAndEntries = new Map<String, List<SFS_RA_Agent_Manager_Entry__c>>();
    Integer intervalMinutes;
    Integer batchSize;
    String defaultSAStatus;
    Integer timeSlotInHours;
    Datetime currentDateTime;
    Datetime endDateTime;
    
    List<SFS_RA_Agent_Manager__c> agentManager = new List<SFS_RA_Agent_Manager__c>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) { 
        String dispatchPolicy = SFS_RA_ConstantsUtil.AM_AGENT_TYPE_DRIP_FEED;
        agentManager = SFS_RA_SerApptDispatchingPolicyHelper.getControllerRecordDetails(dispatchPolicy);
        if(agentManager.isEmpty()){
            return Database.getQueryLocator(SFS_RA_ConstantsUtil.AR_BLANK_QUERY);
        }
        else{
            intervalMinutes = agentManager[0].SFS_RA_Schedule_Frequency__c != null ? (Integer.valueOf(agentManager[0].SFS_RA_Schedule_Frequency__c) ) : 15;
            batchSize = agentManager[0].SFS_RA_Batch_Size__c != null ? (Integer.valueOf(agentManager[0].SFS_RA_Batch_Size__c) ) : 200;
            if(!agentManager[0].SFS_RA_Agent_Manager_Entries__r.isEmpty()){
 	  			defaultSAStatus = agentManager[0].SFS_RA_Agent_Manager_Entries__r[0].SFS_RA_Status__c != null ?	agentManager[0].SFS_RA_Agent_Manager_Entries__r[0].SFS_RA_Status__c : SFS_RA_ConstantsUtil.SA_STATUS_SCHEDULED;
                timeSlotInHours = agentManager[0].SFS_RA_Agent_Manager_Entries__r[0].SFS_RA_Start_Time__c  != null ? (Integer.valueOf(agentManager[0].SFS_RA_Agent_Manager_Entries__r[0].SFS_RA_Start_Time__c ))/60 : 2;
            }
            else{
                return Database.getQueryLocator(SFS_RA_ConstantsUtil.AR_BLANK_QUERY);
            }
        }
        currentDateTime = datetime.now();
        endDateTime = currentDateTime.addHours(timeSlotInHours);
		
        
        String query;
        //query = 'SELECT Id, ServiceAppointmentId FROM AssignedResource WHERE ServiceAppointment.Status =: defaultSAStatus AND ServiceResource.Dispatch_Policy__c =: dispatchPolicy AND (ServiceAppointment.SchedStartTime >=: currentDateTime AND ServiceAppointment.SchedStartTime <=: endDateTime)';    
		query = 'SELECT Id, ServiceAppointmentId, EstimatedTravelTime, ServiceAppointment.SchedStartTime FROM AssignedResource WHERE ServiceAppointment.Status =: defaultSAStatus AND ServiceResource.Dispatch_Policy__c =: dispatchPolicy';            
        if(String.isNotBlank(agentManager[0].SFS_RA_Additional_Considerations__c) && agentManager[0].SFS_RA_Additional_Considerations__c.contains('ServiceAppointment.SchedStartTime')){
            query += ' AND ' + agentManager[0].SFS_RA_Additional_Considerations__c;
        }
        else{
            query += ' AND ServiceAppointment.SchedStartTime = TODAY';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<AssignedResource> scope) {
        List<ServiceAppointment> serviceAppointmentsToUpdate = new List<ServiceAppointment>();
        Set<String> serviceAppointmentsIdSet = new Set<String>();

        for(AssignedResource assignedResourceRec : scope){
            DateTime scheduledStartDateTimeWithEstimatedTravelTime = assignedResourceRec.EstimatedTravelTime != null ? assignedResourceRec.ServiceAppointment.SchedStartTime.addMinutes(-Integer.valueOf(assignedResourceRec.EstimatedTravelTime)) : assignedResourceRec.ServiceAppointment.SchedStartTime;
            if(scheduledStartDateTimeWithEstimatedTravelTime >= currentDateTime && scheduledStartDateTimeWithEstimatedTravelTime <= endDateTime) {
            	serviceAppointmentsIdSet.add(assignedResourceRec.ServiceAppointmentId); 	   
            }
        }

        for(ServiceAppointment sa : [SELECT Id, Status FROM ServiceAppointment WHERE Id IN : serviceAppointmentsIdSet]){
            sa.Status = SFS_RA_ConstantsUtil.SA_STATUS_DISPATCHED;
            serviceAppointmentsToUpdate.add(sa);
        }

        if(!serviceAppointmentsToUpdate.isEmpty()){
            List<Database.SaveResult> result = Database.update(serviceAppointmentsToUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        if(!Test.isRunningTest()){
            System.scheduleBatch(new SFS_RA_ABServApptDripDisptachBatch(), 'SA_Status_Dispatch_Update', intervalMinutes, batchSize);    
        }
    }
}