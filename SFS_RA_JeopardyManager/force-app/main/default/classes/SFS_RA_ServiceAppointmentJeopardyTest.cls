@isTest
public class SFS_RA_ServiceAppointmentJeopardyTest {
    
    @TestSetup
    static void testSetup() {
        User newUser = new User();
        newUser.FirstName = 'test';
        newUser.LastName = 'Usersfs';
        newUser.Email = 'testUsersfs@test.com';
        newUser.Alias = 'tu23456';
        newUser.Username = 'testUsersfs@test.com.ra';
        newUser.IsActive = true;
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.TimeZoneSidKey = 'America/New_York';
        newUser.FederationIdentifier = 'test68168315136131686851';
        
        Profile sysAdminProfile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        newUser.ProfileId = sysAdminProfile.Id;
        
        insert newUser;
        
        System.runAs(newUser) {
            
            OperatingHours testOpp = new OperatingHours();
            testOpp.Name = 'Test Operating Hours';
            insert testOpp;
            
            ServiceTerritory territory = new ServiceTerritory();
            territory.Name = 'test Territory';
            territory.OperatingHoursId = testOpp.Id;
            territory.IsActive = true;
            insert territory;
            
            ServiceResource newSR = new ServiceResource();
            newSR.IsActive = true;
            newSR.Name = 'Test Resource';
            newSR.ResourceType = 'T';
            newSR.RelatedRecordId = newUser.Id;
            insert newSR;
            
            //Creating Service Territory Member
            ServiceTerritoryMember territoryMember = new ServiceTerritoryMember();
            territoryMember.ServiceResourceId = newSR.Id;
            territoryMember.ServiceTerritoryId = territory.Id;
            territoryMember.TerritoryType = 'P';
            territoryMember.EffectiveStartDate = Datetime.now().addDays(-10);
            territoryMember.Street = 'test Rd';
            territoryMember.City = 'testCity';
            territoryMember.State = 'testState';
            territoryMember.Country = 'testCountry';
            territoryMember.PostalCode = '12345';
            insert territoryMember;
            
            //Create Parent Work Order for SA
            WorkOrder wo = new WorkOrder();
            wo.Status = SFS_RA_ConstantsUtil.WO_STATUS_OPEN;
            insert wo;
            
            //Create Service Appointment
            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            
            ServiceAppointment openSA = new ServiceAppointment();
            openSA.ArrivalWindowStartTime = Datetime.now().addMinutes(0);
            openSA.ArrivalWindowEndTime = Datetime.now().addMinutes(30);
            openSA.ServiceTerritoryId = territory.Id;
            openSA.Duration = 2;
            openSA.Status = SFS_RA_ConstantsUtil.SA_STATUS_OPEN;
            openSA.ParentRecordId = wo.Id;
            openSA.Subject='Open SA';
            insert openSA;
            
            ServiceAppointment scheduledSA = openSA;
            scheduledSA.FSL__InJeopardy__c =false;
            scheduledSA.Id=null;
            scheduledSA.ArrivalWindowStartTime=Datetime.now();
            scheduledSA.SchedStartTime = Datetime.now().addMinutes(-10);
            scheduledSA.SchedEndTime = Datetime.now().addMinutes(100);
            scheduledSA.Status= SFS_RA_ConstantsUtil.SA_STATUS_SCHEDULED;
            insert scheduledSA;
            
            ServiceAppointment dispatchedSA = scheduledSA;
            dispatchedSA.FSL__InJeopardy__c =false;
            dispatchedSA.Id=null;
            dispatchedSA.ArrivalWindowStartTime=Datetime.now();
            dispatchedSA.ServiceTerritoryId = territory.Id;
            dispatchedSA.SchedStartTime = Datetime.now().addMinutes(-10);
            dispatchedSA.SchedEndTime = Datetime.now().addMinutes(50);
            dispatchedSA.Status= SFS_RA_ConstantsUtil.SA_STATUS_DISPATCHED;
            insert dispatchedSA;
            
            Id schSAId = [SELECT Id FROM ServiceAppointment WHERE status =: SFS_RA_ConstantsUtil.SA_STATUS_SCHEDULED].Id;
            
            // Insert Assigned Resources 
            List<AssignedResource> assignedResources = new List<AssignedResource>();
            
            AssignedResource ar_schSA = new AssignedResource();
            ar_schSA.ServiceAppointmentId = schSAId;
            ar_schSA.ServiceResourceId = newSR.Id;
            assignedResources.add(ar_schSA);
            
            insert assignedResources;
            
            SFS_RA_Agent_Manager__c agentManagerController = new SFS_RA_Agent_Manager__c();
            agentManagerController.SFS_RA_Enabled__c = true;
            agentManagerController.SFS_RA_Type__c = SFS_RA_ConstantsUtil.AM_CONTROLLER_RECORD;
            agentManagerController.SFS_RA_Agent_Type__c = SFS_RA_ConstantsUtil.AM_AGENT_TYPE_JEOPARDY;
            agentManagerController.SFS_RA_Schedule_Frequency__c = 15;
            insert agentManagerController;
            
            SFS_RA_Agent_Manager__c agentManagerTD = new SFS_RA_Agent_Manager__c();
            agentManagerTD.SFS_RA_Enabled__c = true;
            agentManagerTD.SFS_RA_Service_Territory__c = territory.id;
            agentManagerTD.SFS_RA_Agent_Type__c = SFS_RA_ConstantsUtil.AM_AGENT_TYPE_JEOPARDY;
            agentManagerTD.SFS_RA_Type__c = SFS_RA_ConstantsUtil.AM_TERRITORY_DECOMPOSITION;
            insert agentManagerTD;
            
            List<SFS_RA_Agent_Manager_Entry__c> agentManagerEntryList = new List<SFS_RA_Agent_Manager_Entry__c>();
            
            SFS_RA_Agent_Manager_Entry__c agentManagerEntryDis = new SFS_RA_Agent_Manager_Entry__c();
            agentManagerEntryDis.SFS_RA_Enabled__c = true;
            agentManagerEntryDis.SFS_RA_Agent_Manager__c = agentManagerTD.Id;
            agentManagerEntryDis.SFS_RA_Based_On__c = 'SchedStartTime';
            agentManagerEntryDis.SFS_RA_End_Time__c = 60;
            agentManagerEntryDis.SFS_RA_Start_Time__c = 0;
            agentManagerEntryDis.SFS_RA_Jeopardy_Type__c = 'Late Start Travel';
            agentManagerEntryDis.SFS_RA_Sequence_No__c = 3;
            agentManagerEntryDis.SFS_RA_Status__c = SFS_RA_ConstantsUtil.SA_STATUS_DISPATCHED;
            agentManagerEntryList.add(agentManagerEntryDis);
            
            SFS_RA_Agent_Manager_Entry__c agentManagerEntrySch = new SFS_RA_Agent_Manager_Entry__c();
            agentManagerEntrySch.SFS_RA_Enabled__c = true;
            agentManagerEntrySch.SFS_RA_Agent_Manager__c = agentManagerTD.Id;
            agentManagerEntrySch.SFS_RA_Based_On__c = 'SchedStartTime';
            agentManagerEntrySch.SFS_RA_End_Time__c = 20;
            agentManagerEntrySch.SFS_RA_Start_Time__c = -10;
            agentManagerEntrySch.SFS_RA_Jeopardy_Type__c = 'Late Start Travel';
            agentManagerEntrySch.SFS_RA_Sequence_No__c = 2;
            agentManagerEntrySch.SFS_RA_Status__c = SFS_RA_ConstantsUtil.SA_STATUS_SCHEDULED;
            agentManagerEntrySch.SFS_RA_Consider_Travel_Time__c = true;
            agentManagerEntryList.add(agentManagerEntrySch);
            
            SFS_RA_Agent_Manager_Entry__c agentManagerEntryOpen = new SFS_RA_Agent_Manager_Entry__c();
            agentManagerEntryOpen.SFS_RA_Enabled__c = true;
            agentManagerEntryOpen.SFS_RA_Agent_Manager__c = agentManagerTD.Id;
            agentManagerEntryOpen.SFS_RA_Based_On__c = 'ArrivalWindowStartTime ';
            agentManagerEntryOpen.SFS_RA_End_Time__c = 10;
            agentManagerEntryOpen.SFS_RA_Start_Time__c = -60;
            agentManagerEntryOpen.SFS_RA_Jeopardy_Type__c = 'Rescheduling Required';
            agentManagerEntryOpen.SFS_RA_Sequence_No__c = 1;
            agentManagerEntryOpen.SFS_RA_Status__c = SFS_RA_ConstantsUtil.SA_STATUS_OPEN;
            agentManagerEntryList.add(agentManagerEntryOpen);
            
            insert agentManagerEntryList;
        }
    }
    @isTest
    static void testSFS_ABServiceAppointmentJeopardy (){
        User newUser=[select Id from User where Username='testUsersfs@test.com.ra'];
        System.runAs(newUser) {
            
            Test.startTest();
            SFS_RA_ServiceAppointmentJeopardyBatch obj = new SFS_RA_ServiceAppointmentJeopardyBatch();
            Database.executeBatch(obj);
            Test.stopTest();
            
            List<ServiceAppointment> jeopardySAs = [SELECT Id,Subject FROM ServiceAppointment WHERE FSL__InJeopardy__c=TRUE AND FSL__InJeopardyReason__c!=NULL];
            System.assertEquals(3,jeopardySAs.size());
        }
    }
    
}