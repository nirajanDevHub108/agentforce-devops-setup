 /**
 * @description Provides a method to update Account.Rating for a set of Accounts.
 * Follows bulkified patterns and avoids DML in loops.
 * Note: Plain Apex method per requirement (not invocable). Uses Database methods with error capture.
 */
public with sharing class AccountRatingUpdater {
    /**
     * Updates the Rating field on Accounts by Id.
     * - Performs a single SOQL query and a single DML statement.
     * - Returns the number of records successfully updated.
     *
     * @param accountIds Set<Id> of Account Ids to update
     * @param newRating String value for Account.Rating (e.g., 'Hot', 'Warm', 'Cold')
     * @return Integer count of successfully updated records
     */
    public static Integer updateAccountRatings(Set<Id> accountIds, String newRating) {
        // Return early if inputs are invalid
        if (accountIds == null || accountIds.isEmpty()) {
            return 0;
        }
        if (String.isBlank(newRating)) {
            return 0;
        }

        // Load target Accounts in a single query. Enforce security for user context reads.
        List<Account> accts = [
            SELECT Id, Rating
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ];

        if (accts.isEmpty()) {
            return 0;
        }

        for (Account a : accts) {
            a.Rating = newRating;
        }

        // Use Database.update with partial success capture; run in USER_MODE per security best practices
        Database.SaveResult[] results = Database.update(accts, false, AccessLevel.USER_MODE);

        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                successCount++;
            }
        }
        return successCount;
    }
}
