public class SFS_RA_ServiceAppointmentJeopardyHelper {
    
    public Static Set<String> getTerritoryValues(List<SFS_RA_Agent_Manager__c> agentManagerSD){
        Set<String> territoryValues = new Set<String>();
        for(SFS_RA_Agent_Manager__c agentManagerRecord : agentManagerSD){
            territoryValues.add(agentManagerRecord.SFS_RA_Service_Territory__c);
        }
        return territoryValues;
    }
    
    public Static Set<String> getStatusValues(List<SFS_RA_Agent_Manager__c> agentManagerSD){
        Set<String> statusValues = new Set<String>();
        for(SFS_RA_Agent_Manager__c agentManagerRecord : agentManagerSD){
            if(!agentManagerRecord.SFS_RA_Agent_Manager_Entries__r.isEmpty()){
                for(SFS_RA_Agent_Manager_Entry__c agentManagerEntryRecord: agentManagerRecord.SFS_RA_Agent_Manager_Entries__r){
                    statusValues.add(agentManagerEntryRecord.SFS_RA_Status__c);
                }
            }
        }
        return statusValues;
    }
    
    public Static List<SFS_RA_Agent_Manager__c> getControllerAgentManager(){
        return [SELECT id,SFS_RA_Schedule_Frequency__c, SFS_RA_Additional_Considerations__c, SFS_RA_Batch_Size__c FROM SFS_RA_Agent_Manager__c WHERE SFS_RA_Enabled__c = true 
                AND SFS_RA_Type__c =: SFS_RA_ConstantsUtil.AM_CONTROLLER_RECORD AND SFS_RA_Agent_Type__c =: SFS_RA_ConstantsUtil.AM_AGENT_TYPE_JEOPARDY LIMIT 1];
    }
    
    public Static List<SFS_RA_Agent_Manager__c> getSDAgentManager(){
        return [SELECT id,SFS_RA_Service_Territory__c, 
                (SELECT id,SFS_RA_Enabled__c,SFS_RA_Agent_Manager__c,SFS_RA_Based_On__c,
                 SFS_RA_End_Time__c,SFS_RA_Start_Time__c,SFS_RA_Jeopardy_Type__c,
                 SFS_RA_Sequence_No__c,SFS_RA_Status__c, SFS_RA_Consider_Travel_Time__c
                 FROM SFS_RA_Agent_Manager_Entries__r where SFS_RA_Enabled__c = true ORDER BY SFS_RA_Sequence_No__c )
                FROM SFS_RA_Agent_Manager__c WHERE SFS_RA_Enabled__c = true AND SFS_RA_Type__c =: SFS_RA_ConstantsUtil.AM_TERRITORY_DECOMPOSITION
                AND SFS_RA_Agent_Type__c =: SFS_RA_ConstantsUtil.AM_AGENT_TYPE_JEOPARDY];   
    }
    
    public Static Map<Id, AssignedResource> getAssignedResourceForAppointment(List<ServiceAppointment> serviceAppointments){
        Map<Id, AssignedResource> mapOfServiceAppointmentAndAssignedResource = new Map<Id, AssignedResource>();
        List<ServiceAppointment> listOfAppointmentWithResource = new List<ServiceAppointment>();
        
        listOfAppointmentWithResource = [SELECT ID, (SELECT ID, EstimatedTravelTime FROM ServiceResources ORDER By CreatedDate) FROM ServiceAppointment WHERE ID IN :serviceAppointments];
        
        for(ServiceAppointment appointment : listOfAppointmentWithResource){
            if(!mapOfServiceAppointmentAndAssignedResource.containsKey(appointment.Id)){
                if(!appointment.ServiceResources.isEmpty()){
                    mapOfServiceAppointmentAndAssignedResource.put(appointment.Id, appointment.ServiceResources[0]);
                }
            }
        }     
        return mapOfServiceAppointmentAndAssignedResource; 
    }    
}