-- =============================================================
--  Anti-phishing app — Prototype 1: Database schema
--  Run this first, then seed.sql
-- =============================================================

-- Clean slate (safe to re-run during development)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS user_reports CASCADE;
DROP TABLE IF EXISTS phishing_patterns CASCADE;

-- ----------------------------------------------------------
--  ENUM: what kind of pattern are we storing?
-- ----------------------------------------------------------
DROP TYPE IF EXISTS pattern_type CASCADE;
CREATE TYPE pattern_type AS ENUM (
    'exact_url',        -- full URL match  e.g. http://evil.com/login
    'domain',           -- match any URL on this domain  e.g. evil.com
    'keyword',          -- message contains this word/phrase
    'regex'             -- flexible pattern for future use
);

-- ----------------------------------------------------------
--  ENUM: where did this pattern come from?
-- ----------------------------------------------------------
DROP TYPE IF EXISTS pattern_source CASCADE;
CREATE TYPE pattern_source AS ENUM (
    'developer',        -- added by the dev team directly
    'user_approved'     -- submitted by a user and approved by admin
);

-- ----------------------------------------------------------
--  TABLE 1: phishing_patterns
--  The live lookup table the check engine queries.
-- ----------------------------------------------------------
CREATE TABLE phishing_patterns (
    id              SERIAL PRIMARY KEY,
    pattern         TEXT NOT NULL,               -- the actual string/url/keyword
    pattern_type    pattern_type NOT NULL,
    description     TEXT,                        -- human-readable note
    source          pattern_source NOT NULL DEFAULT 'developer',
    severity        SMALLINT NOT NULL DEFAULT 2  -- 1=low 2=medium 3=high
                        CHECK (severity BETWEEN 1 AND 3),
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_patterns_type   ON phishing_patterns (pattern_type);
CREATE INDEX idx_patterns_active ON phishing_patterns (active);

-- ----------------------------------------------------------
--  TABLE 2: user_reports
--  Crowd-sourced submissions — held for admin review.
-- ----------------------------------------------------------
DROP TYPE IF EXISTS report_status CASCADE;
CREATE TYPE report_status AS ENUM (
    'pending',   -- waiting for admin to review
    'approved',  -- admin approved → copied to phishing_patterns
    'rejected'   -- admin rejected, stays here for audit trail
);

CREATE TABLE user_reports (
    id               SERIAL PRIMARY KEY,
    submitted_text   TEXT NOT NULL,              -- the raw message/url the user flagged
    reason_impersonation  BOOLEAN DEFAULT FALSE, -- checklist answers
    reason_urgency        BOOLEAN DEFAULT FALSE,
    reason_link_mismatch  BOOLEAN DEFAULT FALSE,
    reason_requests_info  BOOLEAN DEFAULT FALSE,
    reason_other          TEXT,                  -- free-text "other" reason
    status           report_status NOT NULL DEFAULT 'pending',
    pattern_id       INT REFERENCES phishing_patterns(id),  -- set when approved
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at      TIMESTAMPTZ
);

CREATE INDEX idx_reports_status ON user_reports (status);

-- ----------------------------------------------------------
--  TABLE 3: audit_log
--  Immutable record of every admin action.
-- ----------------------------------------------------------
DROP TYPE IF EXISTS audit_action CASCADE;
CREATE TYPE audit_action AS ENUM (
    'pattern_added',
    'pattern_deactivated',
    'report_approved',
    'report_rejected'
);

CREATE TABLE audit_log (
    id          SERIAL PRIMARY KEY,
    action      audit_action NOT NULL,
    report_id   INT REFERENCES user_reports(id),
    pattern_id  INT REFERENCES phishing_patterns(id),
    notes       TEXT,
    performed_by TEXT NOT NULL DEFAULT 'admin',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
--  Auto-update updated_at on phishing_patterns
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_patterns_updated_at
BEFORE UPDATE ON phishing_patterns
FOR EACH ROW EXECUTE FUNCTION update_updated_at();
