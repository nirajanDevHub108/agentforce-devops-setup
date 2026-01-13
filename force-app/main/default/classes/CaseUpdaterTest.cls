/**
 * @description Tests for CaseUpdater. Ensures bulk behavior, user-mode DML, and input validation.
 */
@IsTest
private class CaseUpdaterTest {
    @TestSetup
    static void setupData() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            cases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                Origin = 'Phone'
            ));
        }
        insert cases;
    }

    @IsTest
    static void testUpdateStatusSuccessBulk() {
        // Arrange
        List<Case> existing = [SELECT Id, Status FROM Case LIMIT 5];
        Set<Id> ids = new Set<Id>();
        for (Case c : existing) ids.add(c.Id);

        Test.startTest();
        Integer updated = CaseUpdater.updateCaseStatus(ids, 'Closed');
        Test.stopTest();

        System.assertEquals(existing.size(), updated, 'All provided cases should be updated');

        // Verify persisted values
        for (Case c : [SELECT Id, Status FROM Case WHERE Id IN :ids]) {
            System.assertEquals('Closed', c.Status, 'Status should be updated to Closed');
        }
    }

    @IsTest
    static void testEmptyInputsReturnEarly() {
        Test.startTest();
        Integer whenNullIds = CaseUpdater.updateCaseStatus(null, 'Escalated');
        Integer whenEmptyIds = CaseUpdater.updateCaseStatus(new Set<Id>(), 'Escalated');
        Integer whenBlankStatus = CaseUpdater.updateCaseStatus(new Set<Id>{'000000000000000AAA'}, '');
        Test.stopTest();

        System.assertEquals(0, whenNullIds, 'Null ids returns 0');
        System.assertEquals(0, whenEmptyIds, 'Empty ids returns 0');
        System.assertEquals(0, whenBlankStatus, 'Blank status returns 0');
    }

    @IsTest
    static void testPartialSuccessHandled() {
        // Create one extra case, then delete it to simulate a partial failure on update
        Case c = new Case(
            Subject = 'To-be-deleted',
            Status = 'New',
            Origin = 'Phone'
        );
        insert c;
        Id deletedId = c.Id;

        // Build target set including one invalid Id
        List<Case> existing = [SELECT Id FROM Case LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (Case e : existing) ids.add(e.Id);
        ids.add(deletedId);

        // Delete one to force partial failure
        delete c;

        Test.startTest();
        Integer updated = CaseUpdater.updateCaseStatus(ids, 'Escalated');
        Test.stopTest();

        // Expect only valid (non-deleted) records to be counted as success
        System.assertEquals(2, updated, 'Only non-deleted cases should be updated');
    }
}
