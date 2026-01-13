/**
 * @description Tests for AccountRatingUpdater. Ensures bulk behavior, user-mode DML, and input validation.
 */
@IsTest
private class AccountRatingUpdaterTest {
    @TestSetup
    static void setupData() {
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accs.add(new Account(Name = 'Acct ' + i, Rating = 'Cold'));
        }
        insert accs;
    }

    @IsTest
    static void testUpdateRatingsSuccessBulk() {
        // Arrange
        List<Account> existing = [SELECT Id, Rating FROM Account LIMIT 5];
        Set<Id> ids = new Set<Id>();
        for (Account a : existing) ids.add(a.Id);

        Test.startTest();
        Integer updated = AccountRatingUpdater.updateAccountRatings(ids, 'Hot');
        Test.stopTest();

        System.assertEquals(existing.size(), updated, 'All provided accounts should be updated');

        // Verify persisted values
        for (Account a : [SELECT Id, Rating FROM Account WHERE Id IN :ids]) {
            System.assertEquals('Hot', a.Rating, 'Rating should be updated to Hot');
        }
    }

    @IsTest
    static void testEmptyInputsReturnEarly() {
        Test.startTest();
        Integer whenNullIds = AccountRatingUpdater.updateAccountRatings(null, 'Warm');
        Integer whenEmptyIds = AccountRatingUpdater.updateAccountRatings(new Set<Id>(), 'Warm');
        Integer whenBlankRating = AccountRatingUpdater.updateAccountRatings(new Set<Id>{'001000000000000AAA'}, '');
        Test.stopTest();

        System.assertEquals(0, whenNullIds, 'Null ids returns 0');
        System.assertEquals(0, whenEmptyIds, 'Empty ids returns 0');
        System.assertEquals(0, whenBlankRating, 'Blank rating returns 0');
    }

    @IsTest
    static void testPartialSuccessHandled() {
        // Create one extra account, then delete it to simulate a partial failure on update
        Account a = new Account(Name = 'To-be-deleted', Rating = 'Cold');
        insert a;
        Id deletedId = a.Id;

        // Build target set including one invalid Id
        List<Account> existing = [SELECT Id FROM Account LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (Account e : existing) ids.add(e.Id);
        ids.add(deletedId);

        // Delete one to force partial failure
        delete a;

        Test.startTest();
        Integer updated = AccountRatingUpdater.updateAccountRatings(ids, 'Warm');
        Test.stopTest();

        // Expect only valid (non-deleted) records to be counted as success
        System.assertEquals(2, updated, 'Only non-deleted accounts should be updated');
    }
}
