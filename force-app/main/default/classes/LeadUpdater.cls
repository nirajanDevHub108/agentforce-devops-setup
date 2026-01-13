/**
 * @description Updates Lead fields in bulk using Database methods with error handling.
 * Follows best practices: with sharing, user mode DML, bulkified, avoid DML in loops.
 */
public with sharing class LeadUpdater {
    /**
     * Updates the Status field on Leads by Id.
     * - Performs a single SOQL query and a single DML statement.
     * - Returns the number of records successfully updated.
     *
     * @param leadIds Set<Id> of Lead Ids to update
     * @param newStatus String value for Lead.Status (e.g., 'New', 'Working', 'Converted')
     * @return Integer count of successfully updated records
     */
    public static Integer updateLeadStatus(Set<Id> leadIds, String newStatus) {
        // Return early if inputs are invalid
        if (leadIds == null || leadIds.isEmpty()) {
            return 0;
        }
        if (String.isBlank(newStatus)) {
            return 0;
        }

        // Load target Leads in a single query. Enforce security for user context reads.
        List<Lead> leads = [
            SELECT Id, Status
            FROM Lead
            WHERE Id IN :leadIds
            WITH USER_MODE
        ];

        if (leads.isEmpty()) {
            return 0;
        }

        for (Lead l : leads) {
            l.Status = newStatus;
        }

        // Use Database.update with partial success capture; run in USER_MODE per security best practices
        Database.SaveResult[] results = Database.update(leads, false, AccessLevel.USER_MODE);

        Integer successCount = 0;
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                successCount++;
            }
        }
        return successCount;
    }
}
