/**
 * @description       : Cover the code coverage of SFS_RA_ABServApptDisptachBatch apex class
 * @author            : Laxman Singh / Annkit Chawla
 **/
@IsTest
public class SFS_RA_ABServApptDripDisptachBatchTest {

    @TestSetup
    static void setup(){
        Profile servicesProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User serviceUser1 = new User();
        serviceUser1.FirstName = 'Test';
        serviceUser1.LastName = 'ServiceResource1';
        serviceUser1.ProfileId = servicesProfile.Id;
        serviceUser1.username = 'test_service_user1@test.com';
        serviceUser1.email = 'TestServiceUser@invalid.com';
        serviceUser1.Alias = '2222202';
        serviceUser1.TimeZoneSidKey = 'America/New_York';
        serviceUser1.LocaleSidKey = 'en_US';
        serviceUser1.EmailEncodingKey = 'UTF-8';
        serviceUser1.LanguageLocaleKey = 'en_US';
        serviceUser1.IsActive = true;
        serviceUser1.FederationIdentifier = 'test6816815136131686851';
        insert serviceUser1;

        //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Field_Service_Manage_Work'];
        //insert new PermissionSetAssignment(AssigneeId = serviceUser1.id, PermissionSetId = ps.Id);

        System.runAs(serviceUser1) {

            //Creating Operating Hours Record
            OperatingHours estOperatingHour = new OperatingHours();
            estOperatingHour.Name = 'Eastern Standard Time';
            estOperatingHour.TimeZone = 'America/New_York';
            insert estOperatingHour;
            
            //Creating Service Resource
            ServiceResource serviceResource1 = new ServiceResource();
            serviceResource1.Name	= 'Test Resource';
            serviceResource1.RelatedRecordId = userInfo.getUserId();
            serviceResource1.Dispatch_Policy__c = 'Drip Feed';
            serviceResource1.IsActive = true;
            insert serviceResource1;

            //Creating Service Territory
            ServiceTerritory serviceTerritory1 = new ServiceTerritory();
            serviceTerritory1.Name = 'Brooklyn';
            serviceTerritory1.OperatingHoursId = estOperatingHour.Id;
            serviceTerritory1.IsActive = true;
            insert serviceTerritory1;

            //Creating Service Territory Member
            ServiceTerritoryMember member1 = new ServiceTerritoryMember();
            member1.ServiceTerritoryId = serviceTerritory1.Id;
            member1.ServiceResourceId = serviceResource1.Id;
            member1.EffectiveStartDate = Date.today();
            insert member1;

            //Create Parent Work Order for SA
            WorkOrder wo = new WorkOrder();
            wo.Status = 'Open';
            insert wo;
            
            //Create Service Appointment
            ServiceAppointment sa = new ServiceAppointment();
            sa.SchedStartTime = Datetime.now().addHours(1);
            sa.SchedEndTime = Datetime.now().addHours(2);
            sa.ServiceTerritoryId = serviceTerritory1.Id;
            sa.Subject = 'Scheduled within next 2 hours';
            sa.Duration = 1;
            sa.Status = 'Scheduled';
            sa.ParentRecordId = wo.Id;
            insert sa;

            ServiceAppointment sa1 = new ServiceAppointment();
            sa1.SchedStartTime = Datetime.now().addHours(1);
            sa1.SchedEndTime = Datetime.now().addHours(2);
            sa1.ServiceTerritoryId = serviceTerritory1.Id;
            sa1.Subject = 'Scheduled beyond next 2 hours';
            sa1.Duration = 1;
            sa1.Status = 'Scheduled';
            sa1.ParentRecordId = wo.Id;
            insert sa1;
            //Create Assigned Resources
            AssignedResource ar = new AssignedResource();
            ar.ServiceAppointmentId = sa.Id;
            ar.ServiceResourceId = serviceResource1.Id;
            insert ar;

            AssignedResource ar1 = new AssignedResource();
            ar1.ServiceAppointmentId = sa1.Id;
            ar1.ServiceResourceId = serviceResource1.Id;
            insert ar1;
        }
        
        SFS_RA_Agent_Manager__c agentManagerController = new SFS_RA_Agent_Manager__c();
        agentManagerController.SFS_RA_Enabled__c = true;
        agentManagerController.SFS_RA_Type__c = SFS_RA_ConstantsUtil.AM_CONTROLLER_RECORD;
        agentManagerController.SFS_RA_Agent_Type__c = SFS_RA_ConstantsUtil.AM_AGENT_TYPE_DRIP_FEED;
        agentManagerController.SFS_RA_Schedule_Frequency__c = 15;
        insert agentManagerController;
        
        SFS_RA_Agent_Manager_Entry__c agentManagerEntry = new SFS_RA_Agent_Manager_Entry__c();
        agentManagerEntry.SFS_RA_Enabled__c = true;
        agentManagerEntry.SFS_RA_Agent_Manager__c = agentManagerController.Id;
        agentManagerEntry.SFS_RA_Based_On__c = 'SchedStartTime';
        agentManagerEntry.SFS_RA_End_Time__c = 0;
        agentManagerEntry.SFS_RA_Start_Time__c = 120;
        agentManagerEntry.SFS_RA_Jeopardy_Type__c = 'Late Start Travel';
        agentManagerEntry.SFS_RA_Sequence_No__c = 3;
        agentManagerEntry.SFS_RA_Status__c = SFS_RA_ConstantsUtil.SA_STATUS_SCHEDULED;
        insert agentManagerEntry;
        
    }

    @IsTest
    public static void testServApptDispatchStatusBatch(){
        ServiceAppointment scheduledSA = [SELECT Id, Status FROM ServiceAppointment ORDER BY SchedStartTime ASC LIMIT 1];
        Test.startTest();
        Database.executeBatch(new SFS_RA_ABServApptDripDisptachBatch(), 200);
        Test.stopTest();
        List<ServiceAppointment> updatedSA = [SELECT Id, Status FROM ServiceAppointment ORDER BY SchedStartTime ASC];
        System.assertEquals(SFS_RA_ConstantsUtil.SA_STATUS_DISPATCHED, updatedSA[0].Status, 'The Service Appointment should have updated status as Dispatched.');
    }
}