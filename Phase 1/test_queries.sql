-- =============================================================
--  Anti-phishing app — Prototype 1: Test queries
--  Run these after setup_db.sh to verify everything works.
--  Usage: psql -U postgres -d antiphishing -f test_queries.sql
-- =============================================================

\echo ''
\echo '=== Test 1: Total patterns loaded ==='
SELECT COUNT(*) AS total_patterns FROM phishing_patterns;
-- Expected: 20

\echo ''
\echo '=== Test 2: Breakdown by type ==='
SELECT pattern_type, COUNT(*) AS count
FROM phishing_patterns
GROUP BY pattern_type
ORDER BY pattern_type;
-- Expected: domain=5, exact_url=5, keyword=7, regex=3

\echo ''
\echo '=== Test 3: Breakdown by severity ==='
SELECT severity,
       CASE severity WHEN 1 THEN 'low' WHEN 2 THEN 'medium' WHEN 3 THEN 'high' END AS label,
       COUNT(*) AS count
FROM phishing_patterns
GROUP BY severity
ORDER BY severity;

\echo ''
\echo '=== Test 4: Simulate exact URL check ==='
-- This mimics what the check engine will do for an exact_url lookup
SELECT id, pattern, severity, description
FROM phishing_patterns
WHERE active = TRUE
  AND pattern_type = 'exact_url'
  AND pattern = 'http://mysingpass-verify.com/login';
-- Expected: 1 row returned (severity 3)

\echo ''
\echo '=== Test 5: Simulate domain check ==='
-- Extract domain from a submitted URL and check against domain table
-- In the real backend, the URL parsing happens in Python
SELECT id, pattern, severity, description
FROM phishing_patterns
WHERE active = TRUE
  AND pattern_type = 'domain'
  AND 'http://dbs-alert.net/verify-account' LIKE '%' || pattern || '%';
-- Expected: 1 row (dbs-alert.net)

\echo ''
\echo '=== Test 6: Simulate keyword scan ==='
-- Check if a message body contains any active keyword patterns
SELECT id, pattern, severity
FROM phishing_patterns
WHERE active = TRUE
  AND pattern_type = 'keyword'
  AND 'Your account has been suspended. Click here immediately to verify.' ILIKE '%' || pattern || '%';
-- Expected: 1 row

\echo ''
\echo '=== Test 7: Insert a sample user report ==='
INSERT INTO user_reports (
    submitted_text,
    reason_impersonation,
    reason_urgency,
    reason_link_mismatch
) VALUES (
    'http://ocbc-secure-login.com/reset-password',
    TRUE,
    TRUE,
    FALSE
) RETURNING id, submitted_text, status, created_at;
-- Expected: 1 row with status = 'pending'

\echo ''
\echo '=== Test 8: Confirm report is pending review ==='
SELECT id, submitted_text, status, reason_impersonation, reason_urgency
FROM user_reports
WHERE status = 'pending';
-- Expected: the row we just inserted

\echo ''
\echo '=== Test 9: Simulate admin approving report ==='
-- Step A: Promote the report content into phishing_patterns
INSERT INTO phishing_patterns (pattern, pattern_type, description, source, severity)
SELECT submitted_text, 'exact_url', 'User-submitted, admin approved', 'user_approved', 2
FROM user_reports WHERE status = 'pending'
RETURNING id, pattern, source;

-- Step B: Mark the report as approved and link the new pattern
WITH new_pattern AS (
    SELECT id FROM phishing_patterns
    WHERE source = 'user_approved'
    ORDER BY created_at DESC LIMIT 1
)
UPDATE user_reports
SET status = 'approved',
    pattern_id = (SELECT id FROM new_pattern),
    reviewed_at = NOW()
WHERE status = 'pending'
RETURNING id, status, pattern_id, reviewed_at;

-- Step C: Write to audit log
INSERT INTO audit_log (action, report_id, pattern_id, notes)
SELECT 'report_approved', ur.id, ur.pattern_id, 'Approved via test query'
FROM user_reports ur
WHERE ur.status = 'approved'
ORDER BY ur.reviewed_at DESC LIMIT 1
RETURNING id, action, created_at;

\echo ''
\echo '=== Test 10: Final state check ==='
\echo '-- phishing_patterns (should now be 21 rows):'
SELECT COUNT(*) AS total FROM phishing_patterns;

\echo '-- user_reports status summary:'
SELECT status, COUNT(*) FROM user_reports GROUP BY status;

\echo '-- audit_log entries:'
SELECT action, notes, created_at FROM audit_log;

\echo ''
\echo 'All tests complete. Prototype 1 is verified.'
