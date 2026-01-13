/**
 * @description Updates Case fields in bulk using Database methods with error handling.
 * Follows best practices: with sharing, user mode DML, bulkified, avoid DML in loops.
 */
public with sharing class CaseUpdater {
    /**
     * Updates the Status field on Cases by Id.
     * - Performs a single SOQL query and a single DML statement.
     * - Returns the number of records successfully updated.
     *
     * @param caseIds Set<Id> of Case Ids to update
     * @param newStatus String value for Case.Status (e.g., 'Open', 'Closed', 'Escalated')
     * @return Integer count of successfully updated records
     */
    public static Integer updateCaseStatus(Set<Id> caseIds, String newStatus) {
        // Return early if inputs are invalid
        if (caseIds == null || caseIds.isEmpty()) {
            return 0;
        }
        if (String.isBlank(newStatus)) {
            return 0;
        }

        // Load target Cases in a single query. Enforce security for user context reads.
        List<Case> cases = [
            SELECT Id, Status
            FROM Case
            WHERE Id IN :caseIds
            WITH USER_MODE
        ];

        if (cases.isEmpty()) {
            return 0;
        }

        for (Case c : cases) {
            c.Status = newStatus;
        }

        // Use Database.update with partial success capture; run in USER_MODE per security best practices
        Database.SaveResult[] results = Database.update(cases, false, AccessLevel.USER_MODE);

        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                successCount++;
            }
        }
        return successCount;
    }
}
