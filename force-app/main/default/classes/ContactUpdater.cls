/**
 * @description Updates Contact fields in bulk using Database methods with error handling.
 * Follows best practices: with sharing, user mode DML, bulkified, avoid DML in loops.
 */
public with sharing class ContactUpdater {
    /**
     * Updates the Email field on Contacts by Id.
     * - Performs a single SOQL query and a single DML statement.
     * - Returns the number of records successfully updated.
     *
     * @param contactIds Set<Id> of Contact Ids to update
     * @param newEmail String value for Contact.Email
     * @return Integer count of successfully updated records
     */
    public static Integer updateContactEmail(Set<Id> contactIds, String newEmail) {
        // Return early if inputs are invalid
        if (contactIds == null || contactIds.isEmpty()) {
            return 0;
        }
        if (String.isBlank(newEmail)) {
            return 0;
        }

        // Load target Contacts in a single query. Enforce security for user context reads.
        List<Contact> contacts = [
            SELECT Id, Email
            FROM Contact
            WHERE Id IN :contactIds
            WITH USER_MODE
        ];

        if (contacts.isEmpty()) {
            return 0;
        }

        for (Contact c : contacts) {
            c.Email = newEmail;
        }

        // Use Database.update with partial success capture; run in USER_MODE per security best practices
        Database.SaveResult[] results = Database.update(contacts, false, AccessLevel.USER_MODE);

        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                successCount++;
            }
        }
        return successCount;
    }
}
