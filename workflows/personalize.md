# Personalization Workflow — Crafting Emails That Convert

## Overview

Takes enriched author profiles from the Google Sheet and produces personalized email drafts with A/B test variants. Drafts are written back to the same row.

## Step 1: Load Author Data from the Sheet

Read rows from the Google Sheet where research is complete and emails are not yet drafted:

```bash
scripts/sheets.sh read_by_status '{"research_status":"researched","email_status":"pending"}' | jq '.rows'
```

Each returned row is a JSON object with all the schema fields populated by research. See `README.md (Setup)` for how the Apps Script backend works.

For each author, you need at minimum:
- Name, email
- At least one book title or content reference
- Genre/niche
- Current platform(s)
- At least one identified pain point or angle

If any of these are missing, flag the author for additional research.

## Step 1.5: Determine Sender and CTA

Before writing the email, determine who sends it and what the CTA should be based on the segment. See the **Segmentation Strategy** section in `knowledge/email-templates.md` for the full mapping.

Quick reference:
- **Big names (100K+):** the founder, conversation CTA. **Read `knowledge/founder.md` before writing any email as the founder.**
- **Mid-tier (10K-100K):** Scout, "worth a 5-minute look?" CTA with link to {product_url}
- **Rising (1K-10K):** Scout, direct signup CTA
- **Author-preneurs / coaches:** The founder for large, scout for smaller, partnership CTA
- **Bookstagrammers / influencers:** Scout, partnership + referral CTA
- **Already a user:** Scout, referral or re-engagement CTA

## Step 2: Select the Angle

Based on the author's profile, choose the primary angle:

### Decision Tree

```
Is the author self-published?
├── Yes → Do they use KDP Select (exclusive)?
│   ├── Yes → Angle: "Diversify without leaving Amazon" (backlist play)
│   └── No → Angle: "Better economics for wide authors" (90% + resale)
│
├── Traditionally published?
│   ├── Have reverted rights? → Angle: "Give your backlist a second life"
│   └── No reverted rights → Angle: "For your next book / side project"
│
├── Content creator (no book yet)?
│   └── Angle: "Turn your content into a book"
│
└── Genre author with passionate fanbase?
    └── Angle: "Readers who collect + resale royalties"
```

### Lead USP Selection

Pick ONE primary USP to lead with (don't list all of them):

| Author Situation | Lead USP |
|-----------------|----------|
| Low royalties (Amazon 35%) | 90% earnings |
| Frustrated with platform control | No gatekeepers, full control |
| Has engaged readers | Direct reader relationships + analytics |
| Genre with collector culture | Resale royalties (40%) |
| Backlist sitting idle | Perpetual income stream via resales |
| Privacy/ownership concerns | True ownership, no delistings |
| Already wide (multi-platform) | Better economics, one more channel |
| Content creator, no book | Easy 15-minute publishing |
| Already sells direct (Shopify, Payhip) | Better tools, same philosophy |
| Has a newsletter / email list | Best place to send your readers |

## Step 3: Select Email Template

Read `knowledge/email-templates.md` and choose the template closest to the angle:

| Angle | Template |
|-------|----------|
| Indie / wide author | Template 1: The Indie Author |
| Backlist revival | Template 2: The Backlist Play |
| Trad-pub / reverted rights | Template 3: The Trad-Pub Author |
| Content creator | Template 4: The Content Creator |
| Genre fanbase | Template 5: The Genre Author |
| Already sells direct | Template 6: The Direct Seller |
| Author-preneur / writing coach | Template 7: The Author-Preneur |
| Serialized fiction | Template 8: The Serialized Fiction Author |
| Already a user (inactive) | Template 9: Re-Engagement |
| Already a user (active) | Template 10: Referral Ask |
| Bookstagrammer / influencer / community | Template 11: The Bookstagrammer |

## Step 4: Personalize the Email

**MANDATORY:** Before writing any email text, read `knowledge/writing-style.md`. Every email must pass the human-writing checks in that document. No em dashes, no AI buzzwords, no corporate speak.

Fill in all template variables with real data:

### Required Personalization
- `{first_name}` — always use first name, never full name
- `{book_title}` — their most notable or recent book
- `{genre}` — their primary genre
- `{specific_detail}` — THIS IS THE MOST IMPORTANT PART

### The Specific Detail

This is what separates a great cold email from spam. The specific detail must be:
- Something you can only know if you actually looked at their work
- Genuine — don't fake enthusiasm
- Concise — one clause, not a paragraph

Good examples:
- "the way you handle unreliable narrators in {book} is masterful"
- "your newsletter on {topic} consistently nails the {specific thing}"
- "the worldbuilding in {series} — especially {specific element} — is the kind of depth readers obsess over"
- "your thread about {topic} on X really resonated"

Bad examples (too generic):
- "I love your writing" (could be said to anyone)
- "your book looks great" (you clearly didn't read it)
- "you're a talented author" (empty flattery)

### Tone Guidelines
- Write like a knowledgeable peer, not a salesperson
- Conversational but respectful — no forced casualness
- No exclamation marks (they feel salesy in cold email)
- No "I hope this email finds you well" or similar filler
- The email should read like a recommendation from a friend, not a pitch

## Step 5: Generate Subject Line Variants

For each email, generate 2-3 subject line options:

1. One curiosity-based (e.g., `your {genre} backlist`)
2. One reference-based (e.g., `{book_title} readers`)
3. One question-based (e.g., `{first_name} — 90% vs 35%`)

All subject lines must follow the rules from `email-templates.md`:
- 3-6 words
- Lowercase
- No punctuation
- Personalized when possible

## Step 6: Generate Follow-Up Sequence

For each author, also prepare:
- Follow-up 1 (sent 3-4 days after initial)
- Follow-up 2 (sent 5-7 days after follow-up 1)
- Follow-up 3 / breakup (sent 7-10 days after follow-up 2)

Use the follow-up templates from `email-templates.md`, personalized with the same author details.

## Step 7: Quality Check

Before presenting to the user, verify each email:

- [ ] First line references something specific about the author
- [ ] Only ONE primary USP is highlighted (not a feature dump)
- [ ] Email is under 150 words
- [ ] No spam trigger words
- [ ] No links in the body (first email)
- [ ] CTA is low-friction (question, not command)
- [ ] Subject line is 3-6 words, lowercase, no punctuation
- [ ] Tone is peer-to-peer, not salesy
- [ ] All facts about the author are verified (no hallucinations)
- [ ] Zero em dashes (—) anywhere in the email
- [ ] No AI buzzwords (check against `writing-style.md` avoid list)
- [ ] All contractions used (you'd, it's, don't — not you would, it is, do not)
- [ ] No sentence starts with "This means" or "This ensures"
- [ ] Read aloud test: sounds like a person, not a language model
- [ ] Every sentence under 20 words
- [ ] Zero bullet points or numbered lists in the email body
- [ ] Doesn't follow the template structure robotically. Paragraphs vary in length, some personal asides are included, not every email ends with a question
- [ ] Read out loud: sounds like a person typed it in Gmail, not like a drip campaign generated it
- [ ] Across the full sequence: each email has different rhythm and length, no two emails feel structurally identical

## Step 8: Present for Approval

Show each email to the user in this format:

```
### Email for: {Author Name}
**Angle:** {angle used}
**Subject variants:**
  A: {subject_1}
  B: {subject_2}
  C: {subject_3}

**Body:**
{email_body}

**Follow-up sequence:** {count} follow-ups prepared
**Confidence:** {high/medium/low}
```

Wait for user approval on each email before proceeding to send.

## Step 9: Write Drafts Back to the Sheet

After the user approves the drafts (or if they want the drafts saved for review in the Sheet UI), push them to the row via `scripts/sheets.sh update_by_email`:

```bash
scripts/sheets.sh update_by_email 'author@example.com' '{
  "email_1_subject": "your direct sales setup",
  "email_1_body": "Hi {first_name},\n\nI noticed you are already selling signed copies...",
  "email_2_subject": "re: your direct sales setup",
  "email_2_body": "Hi {first_name},\n\nBumping this up...",
  "email_3_subject": "re: your direct sales setup",
  "email_3_body": "{first_name},\n\nQuick context on why I built {Product}...",
  "email_4_subject": "re: your direct sales setup",
  "email_4_body": "{first_name},\n\nOne specific thing...",
  "email_5_subject": "re: your direct sales setup",
  "email_5_body": "{first_name},\n\nNot a pitch this time...",
  "email_6_subject": "re: your direct sales setup",
  "email_6_body": "{first_name},\n\nDifferent angle on this...",
  "email_7_subject": "re: your direct sales setup",
  "email_7_body": "Hi {first_name},\n\nLast note from me...",
  "subject_variants": "Email 1 variants:\nA: your direct sales setup\nB: your shopify store\nC: {first_name}, the example community",
  "drafted_at": "2026-04-16",
  "email_status": "drafted"
}'
```

Notes on formatting:

- **Write bodies as plain text with `\n\n` between paragraphs.** That's what lands in the Sheet cell. The Send workflow converts `\n\n` → `</p><p>` and `\n` → `<br>` before posting to Smartlead (see `workflows/send.md` → "Formatting: convert bodies to HTML before uploading"). Don't put HTML tags in the Sheet — they'd double-encode.
- **Follow-up subjects (`email_2_subject` … `email_7_subject`) are passed through to Smartlead as empty strings**, which tells Smartlead to thread the reply under the email 1 subject as `Re: …`. The `re: your direct sales setup` placeholders above are only for human review in the Sheet; the Send workflow blanks them out. If you want a follow-up to start a fresh thread instead, say so explicitly at review time.
- Do not include the signature block in each email body if it's identical across the sequence (The founder's signature is always the same). Just include it once in the body or let the send phase append it.
- For authors sent by a scout rather than the founder, adjust the signature accordingly.
- Keep `subject_variants` as a single multi-line cell with all A/B options grouped clearly. The human reviewer will pick one before the Send phase fires.

After this call, the row's `email_status` is `"drafted"`. The human reviewer opens the Sheet, reviews the email columns, decides whether to approve, and changes `email_status` to `"approved"` manually. The Send workflow picks up approved rows from there.
