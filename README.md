**Prompts**
<br>
This program is done by vibecoding. 
<br>
<br>
The following is the prompt used:
<br>
"I attached my plan of a mobile anti-phishing app. It warns the users if a message is flagged as suspicious. This app leverages on a database that stores messages or formats so that the system can cross check incoming messages with this database. Users of this app can contribute as well to building the database by flagging suspicious messages following a check list. I need you as my assistant and knowledgeable other to build this mobile app system. What do you need so that you can help me build this app?"

**Files**

db/
├── schema.sql        ← Run first — creates all tables, types, indexes
├── seed.sql          ← Run second — loads 20 phishing patterns
├── setup_db.sh       ← Runs both automatically
└── test_queries.sql  ← Verifies everything works

Step 1 — Check if Homebrew is installed
Open Terminal and run:
bashbrew --version
If you see a version number, you have Homebrew. If you get "command not found", install it first:
bash/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Step 2 — Install PostgreSQL
bashbrew install postgresql@16
This takes 1–3 minutes. When it finishes, run:
bashbrew services start postgresql@16

Step 3 — Add psql to your PATH
Homebrew installs PostgreSQL in a non-default location, so you need to tell your terminal where to find it. Run:
bashecho 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
If you're on an older Intel Mac (pre-2021), replace /opt/homebrew with /usr/local in that command.

Step 4 — Verify it's working
bashpsql --version
You should see something like psql (PostgreSQL) 16.x. Then:
bashpsql postgres
If you get a postgres=# prompt, you're in. Type \q to exit.

**One-time setup (do this only once)**

1. Install PostgreSQL
bashbrew install postgresql@16

2. Set your language settings
bashexport LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

3. Initialise the database
bashinitdb -U $(whoami) /opt/homebrew/var/postgresql@16

4. Start PostgreSQL
bashbrew services start postgresql@16

5. Add PostgreSQL to your PATH (so psql works)
bashecho 'export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

6. Verify PostgreSQL is running
bashpsql postgres

You should see a postgres=# prompt. Type \q to exit.

**Prototype 1 — Database**

Step 1 — Go to your Downloads folder
bashcd ~/Downloads

Step 2 — Create the database
bashcreatedb antiphishing

Step 3 — Run the setup script
Open setup_db.sh and make sure DB_USER matches your Mac username
(run whoami to check). Then run:
bashbash setup_db.sh

You should see a table showing 4 pattern types loaded
(exact_url, domain, keyword, regex).

Step 4 — Run the test queries
bashpsql -U raphaeloen -d antiphishing -f test_queries.sql

Replace raphaeloen with your own username.

✅ Done when you see: "All tests complete. Prototype 1 is verified."

Prototype 2 — Backend

Step 1 — Create a Python virtual environment
bashcd ~/Downloads
python3 -m venv venv
source venv/bin/activate

You should see (venv) at the start of your prompt.

Step 2 — Install psycopg2 first (avoids version conflict)
bashpip install psycopg2-binary --no-cache-dir

Step 3 — Fix the requirements file and install everything else
bashsed -i '' 's/psycopg2-binary==2.9.9/psycopg2-binary/' requirements.txt
pip install -r requirements.txt

Step 4 — Check your .env file
The file may have been saved without the dot. Check and rename if needed:
bashls -la | grep env

If you see env instead of .env, rename it:
bashmv env .env

Then confirm the DB_USER is your Mac username:
bashcat .env

It should say DB_USER=raphaeloen (or your own username).
If it still says postgres, fix it:
bashsed -i '' 's/DB_USER=postgres/DB_USER=raphaeloen/' .env

Step 5 — Start the backend server
bashuvicorn main:app --reload

Leave this terminal window open and running.

Step 6 — Test the backend
Open your browser and go to:
http://127.0.0.1:8000/docs

Click GET /health → Try it out → Execute.

✅ Done when you see: "status": "healthy" and "patterns_loaded": 20

Prototype 3 — Scanner frontend

Step 1 — Open the scanner
Double-click index.html in your Downloads folder.

Step 2 — Scan a test URL
Paste this into the text box and click Scan message:
http://mysingpass-verify.com/login

Step 3 — Try a safe message
Hey, are we still on for lunch tomorrow?

✅ Done when: phishing URL shows an amber warning card, safe message shows a green "Looks safe" card.

Prototype 4 — Flagging + admin review

Step 1 — Test the user flagging flow
In index.html, after scanning a message:
Click the "flag this" link below the verdict
The message text is pre-filled — check off one or more reasons
Click Submit report
You should see "Report submitted"

Step 2 — Open the admin review queue
Double-click admin.html in your Downloads folder.
You should see the report you just submitted in the queue.

Step 3 — Approve the report
Pick a severity (low / medium / high)
Click Approve
The queue should empty

Step 4 — Confirm it's live
Go back to index.html, scan the same message you flagged.
It should now show as phishing detected.

✅ Done when: flagged message is caught by the scanner after approval.

(Every time you come back)

Run these two commands to start everything up:
bashbrew services start postgresql@16
cd ~/Downloads && source venv/bin/activate && uvicorn main:app --reload

Then open index.html and admin.html in your browser.
