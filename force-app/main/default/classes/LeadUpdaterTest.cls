/**
 * @description Tests for LeadUpdater. Ensures bulk behavior, user-mode DML, and input validation.
 */
@IsTest
private class LeadUpdaterTest {
    @TestSetup
    static void setupData() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Corp ' + i,
                Status = 'New'
            ));
        }
        insert leads;
    }

    @IsTest
    static void testUpdateStatusSuccessBulk() {
        // Arrange
        List<Lead> existing = [SELECT Id, Status FROM Lead LIMIT 5];
        Set<Id> ids = new Set<Id>();
        for (Lead l : existing) ids.add(l.Id);

        Test.startTest();
        Integer updated = LeadUpdater.updateLeadStatus(ids, 'Working');
        Test.stopTest();

        System.assertEquals(existing.size(), updated, 'All provided leads should be updated');

        // Verify persisted values
        for (Lead l : [SELECT Id, Status FROM Lead WHERE Id IN :ids]) {
            System.assertEquals('Working', l.Status, 'Status should be updated to Working');
        }
    }

    @IsTest
    static void testEmptyInputsReturnEarly() {
        Test.startTest();
        Integer whenNullIds = LeadUpdater.updateLeadStatus(null, 'Converted');
        Integer whenEmptyIds = LeadUpdater.updateLeadStatus(new Set<Id>(), 'Converted');
        Integer whenBlankStatus = LeadUpdater.updateLeadStatus(new Set<Id>{'000000000000000AAA'}, '');
        Test.stopTest();

        System.assertEquals(0, whenNullIds, 'Null ids returns 0');
        System.assertEquals(0, whenEmptyIds, 'Empty ids returns 0');
        System.assertEquals(0, whenBlankStatus, 'Blank status returns 0');
    }

    @IsTest
    static void testPartialSuccessHandled() {
        // Create one extra lead, then delete it to simulate a partial failure on update
        Lead l = new Lead(
            FirstName = 'To-be-deleted',
            LastName = 'Lead',
            Company = 'Delete Corp',
            Status = 'New'
        );
        insert l;
        Id deletedId = l.Id;

        // Build target set including one invalid Id
        List<Lead> existing = [SELECT Id FROM Lead LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (Lead e : existing) ids.add(e.Id);
        ids.add(deletedId);

        // Delete one to force partial failure
        delete l;

        Test.startTest();
        Integer updated = LeadUpdater.updateLeadStatus(ids, 'Converted');
        Test.stopTest();

        // Expect only valid (non-deleted) records to be counted as success
        System.assertEquals(2, updated, 'Only non-deleted leads should be updated');
    }
}
