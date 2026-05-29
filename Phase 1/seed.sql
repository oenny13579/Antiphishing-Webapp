-- =============================================================
--  Anti-phishing app — Prototype 1: Seed data
--  Run after schema.sql
--  20 realistic patterns covering all 4 pattern types
-- =============================================================

INSERT INTO phishing_patterns (pattern, pattern_type, description, severity) VALUES

-- ── EXACT URLs (known bad links) ────────────────────────────
('http://mysingpass-verify.com/login',
 'exact_url', 'Fake Singpass login page harvesting credentials', 3),

('https://paypal-secure-update.com/confirm',
 'exact_url', 'Fake PayPal account confirmation page', 3),

('http://dbs-alert.net/verify-account',
 'exact_url', 'Impersonates DBS Bank security alert', 3),

('https://netflix-billing-update.com/payment',
 'exact_url', 'Fake Netflix billing update page', 2),

('http://grab-promo-sg.com/free-rides',
 'exact_url', 'Fake Grab promo page collecting personal info', 2),

-- ── DOMAINS (all URLs on these domains are suspicious) ──────
('mysingpass-verify.com',
 'domain', 'Typosquat of official Singpass domain', 3),

('dbs-alert.net',
 'domain', 'Impersonates DBS Bank — not an official domain', 3),

('ocbc-secure-login.com',
 'domain', 'Impersonates OCBC Bank login', 3),

('iras-refund-sg.com',
 'domain', 'Fake IRAS tax refund site', 2),

('posb-verify.net',
 'domain', 'Typosquat of POSB bank domain', 2),

-- ── KEYWORDS (suspicious phrases in message body) ───────────
('Your account has been suspended. Click here immediately',
 'keyword', 'Classic urgency + suspension threat combo', 3),

('Congratulations! You have been selected for a cash reward',
 'keyword', 'Lottery/prize scam opener', 2),

('Verify your Singpass details to avoid account termination',
 'keyword', 'Singpass impersonation with termination threat', 3),

('Your parcel could not be delivered. Pay SGD 0.50 to reschedule',
 'keyword', 'Parcel delivery scam common in SG', 2),

('Your CPF statement is ready. Login to confirm your identity',
 'keyword', 'CPF Board impersonation — common local scam', 3),

('URGENT: Your bank account will be frozen in 24 hours',
 'keyword', 'Bank freeze threat — high urgency scam trigger', 3),

('You have a pending tax refund of SGD. Click to claim',
 'keyword', 'IRAS tax refund scam', 2),

-- ── REGEX (flexible pattern matching for future engine) ──────
('(singpass|cpf|iras|myinfo).*verify.*\.(?!gov\.sg)',
 'regex', 'Catches gov agency impersonation on non-.gov.sg domains', 3),

('(dbs|ocbc|posb|uob|maybank).*secure.*login',
 'regex', 'Catches bank name + secure login keyword on phishing domains', 3),

('free.*(?:iphone|samsung|airpods|voucher).*click',
 'regex', 'Prize/giveaway scam pattern with call to action', 1);
