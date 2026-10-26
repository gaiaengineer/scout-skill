# Send Workflow — Smartlead Integration

## Overview

Takes approved email drafts from the Google Sheet and stages them in Smartlead as a **paused campaign**, ready for a human to review and start manually. Updates the Sheet with campaign_id and smartlead_lead_id for tracking.

**Hard rule: this workflow never starts a campaign automatically.** Starting a campaign is always a deliberate, separate action by the operator — see "Starting a Campaign" below.

## Prerequisites

- `SMARTLEAD_API_KEY` is in `~/.claude/scout-config.json` (or env var)
- At least one email account connected and warmed up in Smartlead (SMTP/Gmail/Outlook) — needed before you can *start* a campaign, but not needed to stage one
- `scripts/smartlead.sh` and `scripts/sheets.sh` are both working (test with `smartlead.sh health` and `sheets.sh health`)

## Architecture

The skill never hits Smartlead's API directly with raw curl. Everything goes through `scripts/smartlead.sh`, which wraps the API with credential loading, JSON handling, and two guardrails:

- `add_lead` refuses if the target campaign is already `ACTIVE`
- `start_campaign` refuses without an explicit `--confirm` flag AND requires the campaign to have leads AND not already be running

Run `smartlead.sh --help` to see all subcommands.

---

## Step 0: Read Approved Authors from the Sheet

```bash
scripts/sheets.sh read_by_status '{"email_status":"approved"}' | jq '.rows'
```

Each returned row includes the author's data PLUS the drafted emails (`email_1_subject`, `email_1_body`, … `email_7_body`, `subject_variants`).

If a row doesn't have `email_1_body` populated, it was approved by mistake or the Personalize workflow hasn't run. Skip it and report to the user.

## Step 1: Pick or Create a Campaign

Campaigns are grouped by segment, not by genre. Naming convention:

```
{Product} / {segment} / {angle} / {YYYY-MM-DD}
```

Examples:
- `{Product} / Big Names / Direct Sellers / 2026-04-16`
- `{Product} / Mid-Tier / Going Wide / 2026-04-16`
- `{Product} / Bookstagrammers / Partnership / 2026-04-16`

Check existing campaigns first to avoid duplicates:

```bash
scripts/smartlead.sh list_campaigns | jq '.[] | {id, name, status}'
```

Create a new one if needed:

```bash
scripts/smartlead.sh create_campaign "{Product} / Mid-Tier / Direct Sellers / 2026-04-16" | jq '.id'
```

The response includes the new campaign's `id`. Save it for the next steps. New campaigns start in `DRAFTED` status — no sending happens until you explicitly start them.

## Step 2: Stage the Email Sequence on the Campaign

The skill drafts a 7-email sequence per row (`email_1_*` through `email_7_*`). Translate that to Smartlead's sequence format:

```bash
scripts/smartlead.sh add_sequence $CAMPAIGN_ID '{
  "sequences": [
    {
      "seq_number": 1,
      "seq_delay_details": {"delay_in_days": 0},
      "subject": "SUBJECT_FROM_email_1_subject",
      "email_body": "BODY_FROM_email_1_body"
    },
    {
      "seq_number": 2,
      "seq_delay_details": {"delay_in_days": 3},
      "subject": "",
      "email_body": "BODY_FROM_email_2_body"
    },
    {
      "seq_number": 3,
      "seq_delay_details": {"delay_in_days": 5},
      "subject": "",
      "email_body": "BODY_FROM_email_3_body"
    },
    {
      "seq_number": 4,
      "seq_delay_details": {"delay_in_days": 6},
      "subject": "",
      "email_body": "BODY_FROM_email_4_body"
    },
    {
      "seq_number": 5,
      "seq_delay_details": {"delay_in_days": 6},
      "subject": "",
      "email_body": "BODY_FROM_email_5_body"
    },
    {
      "seq_number": 6,
      "seq_delay_details": {"delay_in_days": 6},
      "subject": "",
      "email_body": "BODY_FROM_email_6_body"
    },
    {
      "seq_number": 7,
      "seq_delay_details": {"delay_in_days": 6},
      "subject": "",
      "email_body": "BODY_FROM_email_7_body"
    }
  ]
}'
```

Delays are cumulative from the previous email. The schedule above = ~32 days from first touch to breakup email, matching what `knowledge/email-templates.md` specifies.

### Formatting: convert bodies to HTML before uploading

The Sheet stores email bodies as plain text with `\n` paragraph breaks. Smartlead's composer renders `email_body` as HTML, so raw `\n` collapses and the email reads as one wall of text. Before uploading, convert:

- `\n\n` → paragraph break (`</p><p>`)
- `\n` (single) → `<br>`

A jq one-liner that does both:

```jq
def to_html: . | gsub("\r\n"; "\n") | split("\n\n")
  | map("<p>" + (. | gsub("\n"; "<br>")) + "</p>") | join("");
```

Apply it to every `email_body` field before posting to `add_sequence`. The subject stays plain text.

Follow-ups (sequences 2-7) have empty subjects because Smartlead threads them with `Re:` automatically, matching how human follow-ups look in a real inbox.

**`add_sequence` is a full replace, not append.** Every call overwrites the entire sequence for that campaign. Always upload all 7 steps in one call. Never post a partial update hoping it merges.

### A/B Testing Subject Lines

If the row's `subject_variants` field has A/B/C options, wire them in as variants for sequence 1:

```json
{
  "seq_number": 1,
  "variants": [
    {"subject": "VARIANT_A", "email_body": "BODY", "variant_label": "A"},
    {"subject": "VARIANT_B", "email_body": "BODY", "variant_label": "B"}
  ],
  "variant_distribution": "equal"
}
```

## Step 3: Add the Author as a Lead

```bash
scripts/smartlead.sh add_lead $CAMPAIGN_ID '{
  "email": "author@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "custom_fields": {
    "genre": "Romance",
    "top_book": "Title Here",
    "angle": "Direct-seller with Shopify store",
    "source": "scout_skill"
  }
}'
```

`add_lead` will refuse if the campaign is already `ACTIVE` — a safety check that prevents duplicate sends if someone accidentally re-runs the workflow against a running campaign.

Each email (`email_1_body`, etc.) contains the full personalized copy. Don't use Smartlead's `{{first_name}}` placeholders — the skill already bakes the author's name into every draft.

## Step 4: Configure Sending Schedule and Tracking

Smartlead splits this across two endpoints. Both payloads are flat (no outer `settings` wrapper).

**Schedule (timezone, hours, days, daily limit):**

```bash
scripts/smartlead.sh set_schedule $CAMPAIGN_ID '{
  "timezone": "America/New_York",
  "days_of_the_week": [1, 2, 3, 4, 5],
  "start_hour": "09:00",
  "end_hour": "17:00",
  "min_time_btw_emails": 10,
  "max_new_leads_per_day": 30,
  "schedule_start_time": "2026-04-23T09:00:00.000Z"
}'
```

`days_of_the_week` uses 0=Sunday … 6=Saturday. `[1,2,3,4,5]` is Mon–Fri.

**Tracking / general settings:**

```bash
scripts/smartlead.sh set_settings $CAMPAIGN_ID '{
  "track_settings": ["DONT_TRACK_LINK_CLICK"],
  "send_as_plain_text": false,
  "follow_up_percentage": 100
}'
```

`track_settings` is an array. Omit an entry to enable that tracking. Options: `DONT_TRACK_EMAIL_OPEN`, `DONT_TRACK_LINK_CLICK`. We track opens but not clicks by default.

**Why these defaults:**
- **No click tracking on first email** — tracking URLs hurt deliverability
- **Business hours in recipient's timezone** — authors check email during work hours
- **Daily limit 30** — start low; raise after seeing deliverability data over the first week
- **No weekends** — Mon–Fri only; personal outreach reads as spam if it lands on a Sunday

## Step 5: Stop Here and Get Human Approval

At this point the campaign is staged in Smartlead but **not running**. No emails have been sent. The operator should:

1. Open the Smartlead dashboard in a browser
2. Open the campaign by name
3. Review the drafted sequence: every email body, every subject line, every variant
4. Review the lead list
5. Review the settings (schedule, daily limit, connected inbox)
6. Only after all of that, start the campaign

The skill's job ends at "campaign staged, ready for review." The skill **must not** call `start_campaign` automatically.

## Step 6: Write Sheet Status

Once the campaign is staged with the lead added, update the Sheet row so we know what campaign it's in:

```bash
scripts/sheets.sh update_by_email 'author@example.com' '{
  "email_status": "sent",
  "campaign_id": "THE_CAMPAIGN_ID",
  "smartlead_lead_id": "THE_LEAD_ID"
}'
```

Note: `email_status: "sent"` here means "staged in Smartlead for sending" not "already hit the inbox." The distinction matters — if you want a stricter status model, add `staged` as a separate email_status value and update the schema.

---

## Starting a Campaign (Separate, Deliberate Action)

**Only do this after** (a) the user has reviewed everything in Smartlead's UI and (b) you have an explicit, unambiguous instruction from the user to start this specific campaign.

```bash
scripts/smartlead.sh start_campaign $CAMPAIGN_ID --confirm
```

The `--confirm` flag is mandatory. Without it, the helper refuses. The helper also validates that:
- The campaign has at least one lead
- The campaign is not already `ACTIVE`

If either check fails, the start aborts with a clear error.

**Once started:** emails go out on the configured schedule. There's no un-sending. Smartlead's `pause_campaign <id>` can halt future sends, but anything already delivered is delivered.

---

## Monitoring

After the campaign is running, check in periodically:

```bash
# High-level analytics
scripts/smartlead.sh get_stats $CAMPAIGN_ID | jq .

# Full lead status
scripts/smartlead.sh list_leads $CAMPAIGN_ID | jq '.'
```

Update the Sheet when leads reply or bounce:

```bash
scripts/sheets.sh update_by_email 'author@example.com' '{"email_status":"replied"}'
scripts/sheets.sh update_by_email 'author@example.com' '{"email_status":"bounced"}'
```

## Error Handling

| Condition | What to do |
|---|---|
| `add_lead` reports campaign is ACTIVE | Pause the campaign (`smartlead.sh pause_campaign $id`), add the lead, then resume. Or create a new campaign for additional authors. |
| Smartlead returns email-invalid error | Mark the Sheet row as `email_status: "bounced"`, notify user |
| Campaign creation returns 401/403 | API key problem. Rerun `smartlead.sh health`. |
| Lead already exists in another campaign | Check `list_campaigns` + `list_leads` to find where. Don't double-add. |
| `start_campaign` refuses with "no leads" | Run `list_leads` to verify — a staging step may have failed silently |
| `start_campaign` refuses with "already active" | Verify campaign is what you expect. Don't force. |
