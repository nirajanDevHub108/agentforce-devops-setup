/**
 * @description Tests for ContactUpdater. Ensures bulk behavior, user-mode DML, and input validation.
 */
@IsTest
private class ContactUpdaterTest {
    @TestSetup
    static void setupData() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;
    }

    @IsTest
    static void testUpdateEmailSuccessBulk() {
        // Arrange
        List<Contact> existing = [SELECT Id, Email FROM Contact LIMIT 5];
        Set<Id> ids = new Set<Id>();
        for (Contact c : existing) ids.add(c.Id);

        Test.startTest();
        Integer updated = ContactUpdater.updateContactEmail(ids, 'updated@example.com');
        Test.stopTest();

        System.assertEquals(existing.size(), updated, 'All provided contacts should be updated');

        // Verify persisted values
        for (Contact c : [SELECT Id, Email FROM Contact WHERE Id IN :ids]) {
            System.assertEquals('updated@example.com', c.Email, 'Email should be updated');
        }
    }

    @IsTest
    static void testEmptyInputsReturnEarly() {
        Test.startTest();
        Integer whenNullIds = ContactUpdater.updateContactEmail(null, 'new@example.com');
        Integer whenEmptyIds = ContactUpdater.updateContactEmail(new Set<Id>(), 'new@example.com');
        Integer whenBlankEmail = ContactUpdater.updateContactEmail(new Set<Id>{'000000000000000AAA'}, '');
        Test.stopTest();

        System.assertEquals(0, whenNullIds, 'Null ids returns 0');
        System.assertEquals(0, whenEmptyIds, 'Empty ids returns 0');
        System.assertEquals(0, whenBlankEmail, 'Blank email returns 0');
    }

    @IsTest
    static void testPartialSuccessHandled() {
        // Create one extra contact, then delete it to simulate a partial failure on update
        Contact c = new Contact(
            FirstName = 'To-be-deleted',
            LastName = 'Contact',
            Email = 'delete@example.com'
        );
        insert c;
        Id deletedId = c.Id;

        // Build target set including one invalid Id
        List<Contact> existing = [SELECT Id FROM Contact LIMIT 2];
        Set<Id> ids = new Set<Id>();
        for (Contact e : existing) ids.add(e.Id);
        ids.add(deletedId);

        // Delete one to force partial failure
        delete c;

        Test.startTest();
        Integer updated = ContactUpdater.updateContactEmail(ids, 'partial@example.com');
        Test.stopTest();

        // Expect only valid (non-deleted) records to be counted as success
        System.assertEquals(2, updated, 'Only non-deleted contacts should be updated');
    }
}
