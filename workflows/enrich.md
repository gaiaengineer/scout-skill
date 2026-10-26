# Enrichment Workflow — Fill in Missing Data for Existing Rows

## Overview

This workflow runs when the user has manually added authors to the Google Sheet (typically with just a few fields like name, email, and website) and asks the skill to research the rest.

It's a complement to `workflows/research.md`:
- **Research** starts from a name/URL and creates a new row.
- **Enrichment** starts from an existing row and fills its gaps.

## When to Use

Trigger phrases from the user:
- "Fill in missing data for the authors I added"
- "Research the new rows in the Sheet"
- "Enrich rows where we have just a name and email"
- "Complete the data for [specific author]"

## Step 1: Identify Rows That Need Enrichment

Two modes depending on what the user asked:

**Mode A — by status.** Find every row the user marked as needing research:

```bash
scripts/sheets.sh read_by_status '{"research_status":"discovered_by_user"}' | jq '.rows'
```

**Mode B — by missing fields.** Find rows where specific fields are empty, regardless of status:

```bash
scripts/sheets.sh read_missing_data \
  '["genre","num_books","top_book","instagram_followers","goodreads_ratings","audience_size"]' \
  '{"research_status":"discovered_by_user"}' | jq '.rows'
```

The Apps Script returns rows with an added `_missing_fields` array showing exactly which fields are empty per row.

**Mode C — by email.** If the user named a specific author:

```bash
scripts/sheets.sh read_by_status '{}' \
  | jq '.rows[] | select(.email == "author@example.com")'
```

(We don't have a dedicated `read_by_email` action because it's equivalent to reading all + filtering; cheap enough at our volume.)

## Step 2: Present Rows to User for Confirmation

Before running research on N rows, show the user a short list:

```
Found 3 rows marked "discovered_by_user":

1. Example Author (author@example.com) — missing: genre, num_books, instagram_followers, ...
2. Jane Doe (jane@example.com) — missing: website, goodreads, facebook, ...
3. Unknown Author (xyz@example.com) — missing: EVERYTHING except email

Shall I research all 3, or pick specific ones?
```

Wait for user approval. Don't fire off 20 parallel researches without confirming.

## Step 3: Run the Research Protocol

For each approved row, follow the same research steps from `workflows/research.md`:

1. Use `WebSearch` + `WebFetch` to find the author
2. Gather data for every missing field listed in `_missing_fields` (and any other gaps you notice)
3. Apply URL field rules (full URLs, never handles — see `research.md`)
4. Respect the author's anti-AI or anti-blockchain stance if discovered
5. Flag edge cases (not found, already a user, opted out)

**Key difference from fresh research:** don't invent an `email` field or overwrite existing fields the user already populated. Only fill in fields that were empty.

## Step 4: Update the Sheet Row

Use `update_by_email` to patch only the fields you found:

```bash
scripts/sheets.sh update_by_email 'author@example.com' '{
  "instagram": "https://www.instagram.com/exampleauthor/",
  "instagram_followers": 20300,
  "tiktok_followers": 11700,
  "genre": "Romantasy",
  "sub_genres": "Example sub-genre 1, Example sub-genre 2",
  "num_books": 20,
  "top_book": "Example Book Title (Series #1)",
  "goodreads_ratings": 19887,
  "goodreads_avg": 4.35,
  "audience_size": "medium",
  "research_status": "researched",
  "research_confidence": "high",
  "researched_at": "2026-04-16",
  "notes": "User-provided row, enriched via web research. See original source notes."
}'
```

Always flip `research_status` from `discovered_by_user` to `researched` (or `not_found` / `skipped` per edge cases in `research.md`). This signals to the Personalize phase that the row is ready.

## Step 5: Report to User

After enriching all rows, show a summary:

```
Enriched 3 rows:

✓ Example Author — 18 fields added (Tier 1, priority 9)
✓ Jane Doe — 14 fields added, 2 still unknown (Tier 2, priority 6)
✗ Unknown Author — marked not_found (no public profile; needs human clarification)

The Personalize workflow can now draft emails for the 2 successfully researched rows.
```

## Handling Partial Data

Sometimes the user gives you just a name and no email:
- The web research might find the author
- But without an email, there's no outreach path
- Set `research_status = "researched"` if you found a public profile, OR set `research_status = "discovered_by_user"` and leave as-is if the author couldn't be identified with confidence
- Always update `notes` to explain what was found and what's still missing

Sometimes the user gives you a name that matches multiple authors (e.g., "John Smith"):
- Ask the user for disambiguation before researching
- Don't guess and overwrite their row with the wrong person

## Common Failure Modes

| Problem | What to do |
|---|---|
| Row has no email and no website | Ask user for more context, or set research_status to researched without email and flag in notes |
| Author name matches multiple people | Stop, ask user to disambiguate before writing anything |
| User typed name with typo | Research original name, but also try common corrections; confirm with user before updating |
| Author found but anti-AI stance noted | Set `anti_ai: true` and add to `cautions`; do not suggest AI tools in future outreach |
| Clay references still in notes field | These are leftover from the old architecture; fine to leave but rewrite when you next touch the row |

## What Enrichment Does NOT Do

- **Does not create new rows.** Use the Research workflow (fresh mode) for that.
- **Does not draft emails.** That's the Personalize workflow's job, run separately once `research_status = "researched"`.
- **Does not decide to skip outreach.** It marks research complete; humans decide whether to approve the row for emails.
