#!/bin/bash
# =============================================================
#  Anti-phishing app — Prototype 1 setup script
#  Usage: bash setup_db.sh
#
#  Requirements:
#    - PostgreSQL running locally (or update DB_* vars below)
#    - psql available on your PATH
# =============================================================

set -e  # exit immediately on any error

# ── Config — change these to match your Postgres setup ───────
DB_NAME="antiphishing"
DB_USER="raphaeloen"       # or your local postgres username
DB_HOST=""
DB_PORT="5432"

echo ""
echo "  Anti-phishing app — Prototype 1 database setup"
echo "=================================================="

# Step 1: Create the database (skip if it already exists)
echo ""
echo "  [1/3] Creating database '$DB_NAME'..."
psql -h ""  -U $DB_USER \
    -c "CREATE DATABASE $DB_NAME;" 2>/dev/null \
    && echo "        Database created." \
    || echo "        Database already exists — skipping."

# Step 2: Apply schema
echo ""
echo "  [2/3] Applying schema..."
psql -h ""  -U $DB_USER -d $DB_NAME \
    -f "$(dirname "$0")/schema.sql"
echo "        Schema applied."

# Step 3: Seed data
echo ""
echo "  [3/3] Seeding 20 phishing patterns..."
psql -h ""  -U $DB_USER -d $DB_NAME \
    -f "$(dirname "$0")/seed.sql"
echo "        Seed data loaded."

# Quick verification query
echo ""
echo "  Verification — rows per pattern type:"
echo "  ──────────────────────────────────────"
psql -h ""  -U $DB_USER -d $DB_NAME \
    -c "SELECT pattern_type, COUNT(*) AS count FROM phishing_patterns GROUP BY pattern_type ORDER BY pattern_type;"

echo ""
echo "  Prototype 1 is ready."
echo "  Connect to it with:"
echo "    psql -U $DB_USER -d $DB_NAME"
echo ""
