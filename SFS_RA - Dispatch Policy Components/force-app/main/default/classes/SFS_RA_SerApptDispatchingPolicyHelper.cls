public class SFS_RA_SerApptDispatchingPolicyHelper {
    
    public Static List<SFS_RA_Agent_Manager__c> getControllerRecordDetails(String feedType){
        return [SELECT id,SFS_RA_Schedule_Frequency__c, SFS_RA_Additional_Considerations__c, SFS_RA_Batch_Size__c,
                (SELECT id,SFS_RA_Enabled__c,SFS_RA_Agent_Manager__c,SFS_RA_Based_On__c,
                 SFS_RA_End_Time__c,SFS_RA_Start_Time__c,SFS_RA_Jeopardy_Type__c,
                 SFS_RA_Sequence_No__c,SFS_RA_Status__c, SFS_RA_Consider_Travel_Time__c
                 FROM SFS_RA_Agent_Manager_Entries__r WHERE SFS_RA_Enabled__c = true ORDER BY SFS_RA_Sequence_No__c DESC LIMIT 1)
                FROM SFS_RA_Agent_Manager__c 
                WHERE SFS_RA_Enabled__c = true AND SFS_RA_Type__c =: SFS_RA_ConstantsUtil.AM_CONTROLLER_RECORD 
                AND ( SFS_RA_Agent_Type__c =: feedType ) 
                LIMIT 1];
    }
    
}