# Scout

**An agentic outreach pipeline for Claude Code:** it finds authors, researches them, writes personalized cold emails and queues them in Smartlead, with a human approving every step.

Scout is a [Claude Code skill](https://docs.claude.com/en/docs/claude-code/skills). It was built for an author-focused publishing startup to replace manual prospecting: what used to be hours of searching, spreadsheet work and email drafting per batch of authors became a conversation like *"find 20 fantasy authors going wide and draft emails for the best ten"*.

## How it works

```
 Discover  →  Research  →  Personalize  →  Send
 web search    profiles in    7-email          Smartlead
 + scoring     Google Sheets  sequences        campaigns
```

| Phase | What Scout does | Where it's defined |
|---|---|---|
| **Discover** | Scans platforms, bestseller lists and communities; finds contact details; scores each prospect against an ideal profile | `workflows/discover.md` |
| **Research** | Builds a profile per author (books, platforms, audience, pain points, red flags) and writes it to a Google Sheet | `workflows/research.md`, `workflows/enrich.md` |
| **Personalize** | Chooses sender, angle and template; writes a full sequence with subject-line variants; runs a quality checklist | `workflows/personalize.md` |
| **Send** | Creates the campaign, adds leads and sequences, sets the schedule, waits for a final go-ahead | `workflows/send.md` |

Every phase can also run on its own, e.g. *"enrich the authors I added manually"*.

### Design choices
- **Human in the loop.** Nothing is sent without explicit approval; prospects and drafts are always presented for review first.
- **Facts from files, not memory.** Before each task Scout re-reads the product, tone and writing-style files, so emails never cite outdated features.
- **No middleware.** Claude talks to Google Sheets through a small Apps Script web app guarded by a shared secret, and to Smartlead through its REST API. Two shell helpers wrap both.
- **Writing that sounds human.** `knowledge/writing-style.md` bans the usual AI tells (em dashes, "delve", "leverage", bullet points in emails).

## Repository layout

```
SKILL.md                 Skill entry point: pipeline, rules, what to read when
workflows/               Step-by-step instructions for each phase
knowledge/               Product, audience, voice and template files (fill these in)
scripts/
  appsscript_backend.gs  Google Apps Script: JSON API over the authors sheet
  sheets.sh              CLI wrapper for the Apps Script (append, update, read)
  smartlead.sh           CLI wrapper for the Smartlead API (campaigns, leads, sequences)
```

## Setup

**Requirements:** [Claude Code](https://claude.com/claude-code), `bash`, `curl`, `jq`, a Google account, a Smartlead account.

### 1. Install the skill
```bash
git clone https://github.com/gaiaengineer/scout-skill.git ~/code/scout-skill
ln -s ~/code/scout-skill ~/.claude/skills/scout
```

### 2. Create the authors sheet and its API
1. Create a Google Sheet with a tab named `Authors`. Use the column names listed in `workflows/research.md` as the header row.
2. Open **Extensions → Apps Script** and paste in `scripts/appsscript_backend.gs`.
3. Set the `SECRET` constant to a long random string (`openssl rand -hex 32`).
4. **Deploy → New deployment → Web app**, execute as yourself, access "Anyone" (the secret gates access). Copy the web app URL.

### 3. Add your credentials
Either as environment variables:
```bash
export SHEETS_WEBAPP_URL="https://script.google.com/macros/s/<deployment-id>/exec"
export SHEETS_SECRET="<the same secret as in the Apps Script>"
export SMARTLEAD_API_KEY="<your Smartlead API key>"
```
or in a config file at `~/.claude/scout-config.json` (or the path in `$SCOUT_CONFIG`):
```json
{
  "sheets_webapp_url": "https://script.google.com/macros/s/<deployment-id>/exec",
  "sheets_secret": "<the same secret as in the Apps Script>",
  "smartlead_api_key": "<your Smartlead API key>"
}
```
Environment variables win when both are set. Credentials never go into the repository; `.gitignore` blocks env and config files.

### 4. Check the connections
```bash
scripts/sheets.sh health        # {"ok":true,...}
scripts/smartlead.sh health     # {"ok":true,...}
```

### 5. Make it yours
Fill in the templates in `knowledge/`: your product, ideal author profile, tone of voice, founder persona, email templates and objection handling. Scout reads them before every task.

## Usage

In Claude Code:
- *"Find me 20 cozy-mystery authors with their own newsletters."*
- *"Research these authors: …"*
- *"Write emails for the researched authors in the sheet."*
- *"Send the approved emails."*

## Author

Built by [Olga Alexeeva](https://olgaalexeeva.com) · [LinkedIn](https://www.linkedin.com/in/gaiaengineer)
