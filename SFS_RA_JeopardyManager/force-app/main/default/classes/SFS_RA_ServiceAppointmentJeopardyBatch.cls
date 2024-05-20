public class SFS_RA_ServiceAppointmentJeopardyBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents {
    
    List<SFS_RA_Agent_Manager__c> agentManagerSD = new List<SFS_RA_Agent_Manager__c>();
    List<SFS_RA_Agent_Manager__c> agentManager = new List<SFS_RA_Agent_Manager__c>();
    Map<String, List<SFS_RA_Agent_Manager_Entry__c>> mapOfAgentManagerStateAndEntries = new Map<String, List<SFS_RA_Agent_Manager_Entry__c>>();
    Integer intervalMinutes;
    Integer batchSize;
        
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        agentManager = SFS_RA_ServiceAppointmentJeopardyHelper.getControllerAgentManager();
        
        if(agentManager.isEmpty()){
            
            return Database.getQueryLocator(SFS_RA_ConstantsUtil.SA_BLANK_QUERY);
        }
        else{
            
            intervalMinutes = agentManager[0].SFS_RA_Schedule_Frequency__c != null ? (Integer.valueOf(agentManager[0].SFS_RA_Schedule_Frequency__c) ) : 60;
            batchSize = agentManager[0].SFS_RA_Batch_Size__c != null ? (Integer.valueOf(agentManager[0].SFS_RA_Batch_Size__c) ) : 200;
            agentManagerSD = SFS_RA_ServiceAppointmentJeopardyHelper.getSDAgentManager();
            
            if(agentManagerSD.isEmpty()){
                return Database.getQueryLocator(SFS_RA_ConstantsUtil.SA_BLANK_QUERY);
            }
            else{
                for(SFS_RA_Agent_Manager__c agentManagerRecord : agentManagerSD){
                    if(!agentManagerRecord.SFS_RA_Agent_Manager_Entries__r.isEmpty()){
                        mapOfAgentManagerStateAndEntries.put(agentManagerRecord.SFS_RA_Service_Territory__c , agentManagerRecord.SFS_RA_Agent_Manager_Entries__r);
                    }
                }
                Set<String> territoryValues = SFS_RA_ServiceAppointmentJeopardyHelper.getTerritoryValues(agentManagerSD);
                Set<String> statusValues = SFS_RA_ServiceAppointmentJeopardyHelper.getStatusValues(agentManagerSD);

                if(!statusValues.isEmpty() && !territoryValues.isEmpty()){
                    
                    String query ='SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, DueDate ,ArrivalWindowStartTime, ActualStartTime, Status, ServiceTerritoryId, ServiceTerritory.Name, FSL__InJeopardy__c, FSL__InJeopardyReason__c FROM ServiceAppointment ';
                    query += 'WHERE Status IN: statusValues AND ServiceTerritoryId IN: territoryValues AND FSL__InJeopardy__c = FALSE';
                    
                    if(String.isNotBlank(agentManager[0].SFS_RA_Additional_Considerations__c)){
                        query += ' AND ' + agentManager[0].SFS_RA_Additional_Considerations__c;
                    }
                    
                    return Database.getQueryLocator(query);
                }
                else{
                    return Database.getQueryLocator(SFS_RA_ConstantsUtil.SA_BLANK_QUERY);
                }
            }
        }
    }
    
    public void execute(Database.BatchableContext BC, List<ServiceAppointment> serviceAppointments){
		List<ServiceAppointment> appointmentListToUpdate = new List<ServiceAppointment>();
        List<SFS_RA_Agent_Manager_Entry__c> agentManagerEntriesForTerritory = new List<SFS_RA_Agent_Manager_Entry__c>();        
        
        Map<Id, AssignedResource> mapOfServiceAppointmentAndAssignedResource = new Map<Id, AssignedResource>();
        mapOfServiceAppointmentAndAssignedResource = SFS_RA_ServiceAppointmentJeopardyHelper.getAssignedResourceForAppointment(serviceAppointments);
        
        for(ServiceAppointment appointment : serviceAppointments){
            if(mapOfAgentManagerStateAndEntries.containsKey(appointment.ServiceTerritoryId)){ 
                agentManagerEntriesForTerritory = mapOfAgentManagerStateAndEntries.get(appointment.ServiceTerritoryId);
                
                for(SFS_RA_Agent_Manager_Entry__c agentManagerEntry : agentManagerEntriesForTerritory){
                    Integer startTimeAddMinutes = agentManagerEntry.SFS_RA_Start_Time__c.intValue();
                    Integer endTimeAddMinutes   = agentManagerEntry.SFS_RA_End_Time__c.intValue();
                    
                    Datetime startTimetoCheck;
                    Datetime endTimetoCheck;
                    
                    if(appointment.get(agentManagerEntry.SFS_RA_Based_On__c)!=null){
                        
                        startTimetoCheck   = Datetime.valueOf(appointment.get(agentManagerEntry.SFS_RA_Based_On__c)).addMinutes(startTimeAddMinutes);
                        endTimetoCheck     = Datetime.valueOf(appointment.get(agentManagerEntry.SFS_RA_Based_On__c)).addMinutes(endTimeAddMinutes);
                        
                        if(agentManagerEntry.SFS_RA_Consider_Travel_Time__c == true){
                            if(mapOfServiceAppointmentAndAssignedResource.containsKey(appointment.ID)){
                                
                                //subtract the travel time
                                Integer travelTime = (mapOfServiceAppointmentAndAssignedResource.get(appointment.ID).EstimatedTravelTime != null) ? ((-1)*mapOfServiceAppointmentAndAssignedResource.get(appointment.ID).EstimatedTravelTime.intValue()) : 0 ;
                                startTimetoCheck = startTimetoCheck.addMinutes(travelTime);
                                
                            }
                        } 
                    }
                    else{
                        continue;
                    }
                    
                    if(
                        (appointment.get(SFS_RA_ConstantsUtil.SA_STATUS) == agentManagerEntry.SFS_RA_Status__c) &&
                        (Datetime.now() >= startTimetoCheck) &&
                        (Datetime.now() <= endTimetoCheck)
                    ) {
                        
                        appointment.FSL__InJeopardy__c = TRUE;
                        appointment.FSL__InJeopardyReason__c = agentManagerEntry.SFS_RA_Jeopardy_Type__c ;
                        appointmentListToUpdate.add(appointment);
                        break;
                        
                    }
                }
            }
        }
        
        if(!appointmentListToUpdate.isEmpty()){
            Database.update(appointmentListToUpdate, false);
        }
            
    }
    
    public void finish(Database.BatchableContext BC){
        if(!Test.isRunningTest())
        {
            //Schedule the batch to run again
            String jobId = System.scheduleBatch(new SFS_RA_ServiceAppointmentJeopardyBatch(), 'SFS_RA_ServiceAppointmentJeopardyBatch', intervalMinutes, batchSize);
        }
    }
}