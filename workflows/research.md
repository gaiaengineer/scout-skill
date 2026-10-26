# Research Workflow — Author Prospecting

## Overview

This workflow takes a list of author emails (or names/URLs) and produces enriched author profiles stored in Google Sheets.

**Two entry modes:**

1. **Fresh research.** User gives names/emails/URLs. Skill does web research, appends a new row to the Sheet.
2. **Enrichment.** User says "fill in missing data for the authors I added." Skill reads rows from the Sheet where fields are empty (typically where `research_status = "discovered_by_user"`), researches the gaps, and updates the existing rows. See `workflows/enrich.md` for the full enrichment procedure.

In both modes, the research protocol below is the same. Only the write step differs (append vs. update).

## Step 1: Input Processing

Accept input in any of these formats:
- Email addresses (one per line or comma-separated)
- Names with optional context ("Jane Doe, romance author")
- URLs (Amazon author pages, personal websites, social profiles)
- A mix of the above

Parse and normalize into a working list: `[{email, name, url, raw_input}]`

## Step 2: Web Research

For each author, use `WebSearch` and `WebFetch` to find:

### Identity & Contact
- Full name and any pen names
- Email (if not already provided)
- Personal website / blog
- Social profiles: Twitter/X, Instagram, Facebook, LinkedIn, TikTok, Threads
- Newsletter (Substack, Beehiiv, ConvertKit landing page, etc.)

### Publishing Profile
- Books published (titles, genres, publication dates)
- Where they sell (Amazon, Barnes & Noble, Kobo, Smashwords, direct site)
- Amazon author page URL and author rank
- Goodreads profile and average ratings
- Number of reviews across platforms
- Whether they use KDP Select (exclusivity) or are wide
- Any audiobook presence (Audible, Findaway, etc.)

### Representation & Business
- Literary agent (name, agency) — check publisher acknowledgments, QueryTracker, Publishers Marketplace, author website "about" page, or interviews where they mention their agent
- Publisher(s) — current and past
- Whether they're agented but self-pub on the side, unagented, or previously agented
- Management or publicist if visible

### Audience & Engagement
- Social media follower counts
- Newsletter subscriber count (if publicly available)
- Engagement level (do they post regularly? do followers interact?)
- Any podcast appearances or interviews
- Speaking engagements or conference presence

### Pain Points & Signals
Look for signals that they'd be receptive to the product:
- Complaints about Amazon royalties or policies
- Posts about wanting more independence
- Discussion of author earnings or transparency
- Interest in direct-to-reader sales
- Frustration with traditional publishing
- Previous interest in blockchain/web3/NFTs (positive signal)
- Mentions of wanting reader analytics or engagement
- Posts about book piracy (if the product addresses it)

### Search Queries to Use
```
"{author_name}" author
"{author_name}" books
"{author_name}" Amazon author
"{author_name}" interview publishing
"{author_name}" newsletter
site:twitter.com OR site:x.com "{author_name}" author
site:instagram.com "{author_name}"
site:goodreads.com "{author_name}"
"{author_name}" podcast interview
"{author_name}" self-publishing OR indie author
"{author_name}" literary agent OR represented by
"{author_name}" site:publishersmarketplace.com OR site:querytracker.net
```

## Step 3: Write to Google Sheets

Use `scripts/sheets.sh` to persist the row. See the "Google Sheets Push" section lower in this file for exact commands.

### Google Sheets Schema

This is the single source of truth for the data the skill produces. Every column listed here must exist as a header in row 1 of the `Authors` tab. Columns can be in any order in the Sheet; the Apps Script matches by name.

104 columns total: 88 author-profile fields + 16 email/pipeline fields added when the skill drafts emails. Grouped into 11 sections below.

| Column                        | Type    | Description                                                                                                                        |
| ----------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **Identity & Contact**        |         |                                                                                                                                    |
| email                         | string  | Primary contact email                                                                                                              |
| email_secondary               | string  | Secondary/personal email if found                                                                                                  |
| first_name                    | string  | First name                                                                                                                         |
| last_name                     | string  | Last name                                                                                                                          |
| pen_names                     | string  | Comma-separated pen names                                                                                                          |
| location                      | string  | City/state/country                                                                                                                 |
| **Online Presence**           |         |                                                                                                                                    |
| website                       | url     | Personal website                                                                                                                   |
| twitter                       | url     | Twitter/X profile                                                                                                                  |
| twitter_followers             | number  | Twitter/X follower count                                                                                                           |
| instagram                     | url     | Instagram profile                                                                                                                  |
| instagram_followers           | number  | Instagram follower count                                                                                                           |
| tiktok                        | url     | TikTok profile                                                                                                                     |
| tiktok_followers              | number  | TikTok follower count                                                                                                              |
| facebook                      | url     | Facebook page/profile                                                                                                              |
| facebook_followers            | number  | Facebook follower count                                                                                                            |
| bluesky                       | url     | Bluesky profile                                                                                                                    |
| mastodon                      | url     | Mastodon profile                                                                                                                   |
| linkedin                      | url     | LinkedIn profile                                                                                                                   |
| youtube                       | url     | YouTube channel                                                                                                                    |
| threads                       | url     | Threads profile                                                                                                                    |
| goodreads                     | url     | Goodreads author page                                                                                                              |
| goodreads_ratings             | number  | Total Goodreads ratings across all books                                                                                           |
| goodreads_avg                 | number  | Average Goodreads rating                                                                                                           |
| amazon_author                 | url     | Amazon author page                                                                                                                 |
| bookbub                       | url     | BookBub profile                                                                                                                    |
| patreon                       | url     | Patreon page                                                                                                                       |
| patreon_members               | number  | Patreon member/subscriber count                                                                                                    |
| **Newsletter**                |         |                                                                                                                                    |
| newsletter                    | boolean | Has a newsletter?                                                                                                                  |
| newsletter_platform           | string  | Mailchimp, Substack, ConvertKit, Beehiiv, etc.                                                                                     |
| newsletter_name               | string  | Name of the newsletter if branded                                                                                                  |
| newsletter_freebie            | string  | What do subscribers get? (free book, short story, etc.)                                                                            |
| **Publishing Profile**        |         |                                                                                                                                    |
| genre                         | string  | Primary genre(s)                                                                                                                   |
| sub_genres                    | string  | Specific sub-genres (dark romance, LitRPG, cozy mystery, etc.)                                                                     |
| num_books                     | number  | Number of published books                                                                                                          |
| top_book                      | string  | Best-known title                                                                                                                   |
| top_book_ratings              | number  | Goodreads ratings for top book                                                                                                     |
| series                        | string  | Key series names                                                                                                                   |
| platforms                     | string  | Where they currently sell (Amazon, Kobo, Smashwords, etc.)                                                                         |
| literary_agent                | string  | Agent name and agency                                                                                                              |
| agent_email                   | string  | Agent's contact email                                                                                                              |
| publisher                     | string  | Current/past publisher(s)                                                                                                          |
| own_imprint                   | string  | Name of their own imprint if they have one                                                                                         |
| kdp_exclusive                 | boolean | In KDP Select?                                                                                                                     |
| kdp_allstar                   | boolean | KDP Select All-Star?                                                                                                               |
| writes_18_plus                | boolean | Writes adult/erotic/18+ content?                                                                                                   |
| writes_fanfic                 | boolean | Writes or started in fanfiction?                                                                                                   |
| fanfic_platform               | string  | AO3, Wattpad, Royal Road, etc.                                                                                                     |
| audiobooks                    | boolean | Has audiobooks?                                                                                                                    |
| audiobook_platform            | string  | Audible, Findaway, etc.                                                                                                            |
| **Sales & Achievements**      |         |                                                                                                                                    |
| bestseller_lists              | string  | NYT, USA Today, WSJ, Amazon #1, etc.                                                                                               |
| awards                        | string  | Any awards won                                                                                                                     |
| estimated_sales               | string  | Estimated total sales if publicly known                                                                                            |
| price_range                   | string  | Typical book price range                                                                                                           |
| **Direct Sales**              |         |                                                                                                                                    |
| has_direct_store              | boolean | Sells via own website/Shopify/Payhip/Gumroad?                                                                                      |
| direct_store_url              | url     | URL of their direct store                                                                                                          |
| direct_store_type             | string  | Shopify, Payhip, Gumroad, BookFunnel, own site, etc.                                                                               |
| sells_merch                   | boolean | Sells merchandise (signed copies, candles, etc.)?                                                                                  |
| sells_signed_copies           | boolean | Sells signed/special editions?                                                                                                     |
| **Audience & Community**      |         |                                                                                                                                    |
| audience_size                 | string  | Estimated total audience: small (1K-10K) / medium (10K-100K) / large (100K+)                                                       |
| reader_community              | string  | Name of fan community if they have one (e.g., "Sassy Sparrows", "KMod Squad")                                                      |
| reader_community_platform     | string  | Where the community lives (Facebook group, Discord, etc.)                                                                          |
| reader_community_size         | number  | Size of the community if known                                                                                                     |
| engagement_level              | string  | How actively they engage: high / medium / low                                                                                      |
| **Professional Affiliations** |         |                                                                                                                                    |
| memberships                   | string  | ALLi, NINC, RWA, ITW, IBPA, etc.                                                                                                   |
| warm_community                | string  | 20BooksTo50K, Wide for the Win, etc.                                                                                               |
| **Outreach Strategy**         |         |                                                                                                                                    |
| author_type                   | string  | indie / trad-pub / hybrid / fanfic / fanfic+original / content-creator / author-preneur / serialized / bookstagrammer / influencer |
| best_angle                    | string  | Recommended primary outreach angle                                                                                                 |
| secondary_angle               | string  | Backup angle if primary doesn't land                                                                                               |
| template                      | string  | Which email template to use (Template 1-11)                                                                                        |
| sender                        | string  | Who sends the email: founder / scout                                                                                                |
| cta_type                      | string  | conversation / visit-landing-page / signup / partnership / referral                                                                |
| pain_points                   | string  | Identified pain points relevant to the product                                                                                         |
| intent_signals                | string  | Buying signals found, with links and dates                                                                                         |
| anti_blockchain               | boolean | Has expressed anti-crypto/blockchain views?                                                                                        |
| anti_ai                       | boolean | Has expressed anti-AI views?                                                                                                       |
| cautions                      | string  | Things to avoid or be careful about in outreach                                                                                    |
| **Pipeline Status**           |         |                                                                                                                                    |
| discovery_source              | string  | Where the prospect was found                                                                                                       |
| priority_score                | number  | 1-10 priority score                                                                                                                |
| priority_tier                 | string  | tier_1 / tier_2 / tier_3                                                                                                           |
| research_status               | string  | discovered_by_user / discovered_by_skill / researched / not_found / skipped                                                        |
| research_confidence           | string  | high / medium / low                                                                                                                |
| skip_reason                   | string  | Why skipped if applicable (no_audience_poor_fit, existing_user, etc.)                                                         |
| email_status                  | string  | pending / drafted / approved / sent / replied / bounced                                                                            |
| campaign_id                   | string  | Smartlead campaign ID                                                                                                              |
| smartlead_lead_id             | string  | Smartlead lead ID                                                                                                                  |
| existing_user            | string  | active / inactive / no                                                                                                             |
| notes                         | string  | Free-form research notes                                                                                                           |
| researched_at                 | date    | When research was completed                                                                                                        |
| **Email Drafts**              |         | Populated by the Personalize workflow, not by Research                                                                             |
| email_1_subject               | string  | Initial email subject                                                                                                              |
| email_1_body                  | text    | Initial email body                                                                                                                 |
| email_2_subject               | string  | Follow-up 1 (bump) subject                                                                                                         |
| email_2_body                  | text    | Follow-up 1 body                                                                                                                   |
| email_3_subject               | string  | Follow-up 2 (social proof) subject                                                                                                 |
| email_3_body                  | text    | Follow-up 2 body                                                                                                                   |
| email_4_subject               | string  | Follow-up 3 (feature spotlight) subject                                                                                            |
| email_4_body                  | text    | Follow-up 3 body                                                                                                                   |
| email_5_subject               | string  | Follow-up 4 (value-add) subject                                                                                                    |
| email_5_body                  | text    | Follow-up 4 body                                                                                                                   |
| email_6_subject               | string  | Follow-up 5 (different angle) subject                                                                                              |
| email_6_body                  | text    | Follow-up 5 body                                                                                                                   |
| email_7_subject               | string  | Follow-up 6 (breakup) subject                                                                                                      |
| email_7_body                  | text    | Follow-up 6 body                                                                                                                   |
| subject_variants              | text    | A/B/C subject line options for email 1 (and any others)                                                                            |
| drafted_at                    | date    | When the skill last drafted emails for this row                                                                                    |

**Important:** Fill in every field you can find data for. Empty fields are fine, but don't skip research just because a field seems minor. The more data in the Sheet, the better the personalization. Follower counts, community names, direct store URLs, and specific pain points are what turn a generic email into one that gets a reply.

### URL Field Rules (apply to every URL-type field)

Every field typed as URL in the schema MUST contain a full URL starting with `https://` (or `http://` only if HTTPS isn't available). Never push just a handle, username, or partial path.

| Field | Wrong (handle) | Right (full URL) |
|---|---|---|
| twitter | `@authorname` | `https://twitter.com/authorname` or `https://x.com/authorname` |
| instagram | `@authorname` | `https://www.instagram.com/authorname/` |
| tiktok | `@authorname` | `https://www.tiktok.com/@authorname` |
| threads | `@authorname` | `https://www.threads.net/@authorname` |
| bluesky | `@author.bsky.social` | `https://bsky.app/profile/author.bsky.social` |
| mastodon | `@author@server.social` | `https://server.social/@author` |
| facebook | `authorname` | `https://www.facebook.com/authorname/` |
| linkedin | `in/authorname` | `https://www.linkedin.com/in/authorname/` |
| youtube | `@authorname` | `https://www.youtube.com/@authorname` |

Why it matters: Google Sheets renders URLs as clickable links, and downstream automations (Make scenarios, CSV exports, Smartlead imports) all expect fully qualified URLs. Handles break all of that. Every push to the Sheet must pass the URL check.

Standard URL formats to use:
- Twitter/X: `https://twitter.com/{handle}` or `https://x.com/{handle}`
- Instagram: `https://www.instagram.com/{handle}/`
- TikTok: `https://www.tiktok.com/@{handle}`
- Threads: `https://www.threads.net/@{handle}`
- Bluesky: `https://bsky.app/profile/{full.bsky.social}`
- Mastodon: `https://{instance.server}/@{handle}`
- Facebook: `https://www.facebook.com/{page_or_handle}/`
- YouTube: `https://www.youtube.com/@{handle}` or `/c/{name}`
- Goodreads: `https://www.goodreads.com/author/show/{id}.{Name}`
- Amazon: `https://www.amazon.com/stores/author/{asin}` or `https://www.amazon.com/{Name}/e/{asin}`
- BookBub: `https://www.bookbub.com/authors/{name-slug}`

### Google Sheets Read/Write

The skill reads from and writes to the Sheet via `scripts/sheets.sh`, which wraps the Apps Script web app. Full architecture and setup in `README.md (Setup)`.

**Append a new row** (fresh research mode):

```bash
scripts/sheets.sh append '{
  "email": "author@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "genre": "Romance",
  "research_status": "researched",
  "research_confidence": "high",
  "email_status": "pending",
  "researched_at": "2026-04-16"
}'
```

The JSON can include any subset of the 104 schema columns. Fields matching header names are written; unknown fields are silently ignored by the Apps Script.

**Update an existing row** (enrichment mode, or later-phase updates):

```bash
scripts/sheets.sh update_by_email 'author@example.com' '{
  "instagram_followers": 54000,
  "goodreads_ratings": 1323,
  "research_status": "researched",
  "research_confidence": "high",
  "researched_at": "2026-04-16"
}'
```

The Apps Script finds the row by email (case-insensitive) and updates only the fields provided.

**Read rows for the enrichment workflow** (user-added rows that need research):

```bash
scripts/sheets.sh read_by_status '{"research_status":"discovered_by_user"}' | jq '.rows'
```

Or find rows where specific fields are empty:

```bash
scripts/sheets.sh read_missing_data '["instagram_followers","goodreads_ratings","genre"]' '{"research_status":"discovered_by_user"}' | jq '.rows'
```

**Handling rows the user manually added:**

When the user types an author into the Sheet directly (typically with just `first_name`, `last_name`, `email`, and `website`), they should also set `research_status = "discovered_by_user"`. The skill's enrichment workflow (`workflows/enrich.md`) picks up those rows, researches the missing fields, updates the row, and flips `research_status` to `researched`.

**Error handling:**

- `{"ok":false,"error":"unauthorized"}` — $SHEETS_SECRET doesn't match the Apps Script constant
- `{"ok":false,"error":"row not found"}` — no row with that email exists (maybe misspelled, or the user hasn't added it yet)
- Non-JSON HTML response — the Apps Script isn't deployed correctly; see `README.md (Setup)` troubleshooting

**No Clay, no Make, no SCOUT_INBOX:** The skill reads and writes directly. No intermediate storage.

## Step 4: Profile Summary

After researching each author, compile a summary that covers every major section of the schema. This is both the user-facing review AND the data that goes into the Sheet. If a field is empty, say "not found" rather than omitting it.

```
### {Author Name}

**Identity & Contact**
- Email: {email} or not found
- Website: {website}
- Location: {location} or unknown

**Social Profiles**
- Instagram: {handle} ({count} followers)
- TikTok: {handle} ({count} followers)
- Facebook: {handle} ({count} followers)
- Twitter/X: {handle} ({count} followers) or locked/inactive
- Bluesky / Mastodon / Threads: {if present}
- Goodreads: {url} ({total_ratings} ratings, {avg} avg)
- Patreon: {url} ({members} members) or none
- BookBub: {url} or none

**Newsletter**
- Has newsletter: yes/no
- Platform: {Mailchimp/Substack/etc.}
- Subscriber freebie: {what they offer}

**Publishing Profile**
- Books: {num_books} published
- Genre: {primary} ({sub_genres})
- Top book: {title} ({ratings} Goodreads ratings)
- Key series: {series names}
- Platforms: {where they sell}
- KDP Exclusive: yes/no (KDP All-Star: yes/no)
- Agent: {name, agency} or Unagented
- Publisher: {publisher(s)} or Self-published
- Own imprint: {name} or none
- Audiobooks: yes/no ({platform})
- 18+ content: yes/no
- Fanfiction background: yes/no ({platform})

**Sales & Achievements**
- Bestseller lists: {NYT, USA Today, etc.} or none
- Awards: {list} or none
- Estimated sales: {if publicly known}
- Price range: {range}

**Direct Sales**
- Sells direct: yes/no
- Store URL: {url}
- Store type: {Shopify/Payhip/etc.}
- Sells signed copies / merch: yes/no

**Audience & Community**
- Audience size: {small/medium/large} (estimated {number})
- Fan community: {name} on {platform} ({size})
- Engagement level: {high/medium/low}

**Professional Affiliations**
- Memberships: {ALLi, NINC, etc.}
- Warm communities: {20BooksTo50K, Wide for the Win, etc.}

**Outreach Strategy**
- Author type: {indie/hybrid/trad-pub/etc.}
- Best angle: {primary angle}
- Secondary angle: {backup}
- Template: Template {N}
- Sender: {founder/scout}
- CTA: {conversation/visit-landing-page/signup/partnership/referral}
- Pain points: {specific to this author}
- Intent signals: {with links and dates}
- Cautions: {anti-AI, anti-blockchain, has agent, under contract, etc.}

**Priority Score: {N}/10 (Tier {1/2/3})**
- {bullet point justifications}
- Confidence: {high/medium/low}
```

Present all summaries to the user for review before proceeding to personalization. After approval, push all data to the Sheet via `scripts/sheets.sh append` (new row) or `scripts/sheets.sh update_by_email` (enrichment). Every field in the summary should map to a Sheet column.

## Step 5: Handle Edge Cases

- **Can't find the author:** Set `research_status = "not_found"` in the Sheet, populate `notes` with what was searched. Ask the user if they have additional context.
- **Author is already a user:** Set `research_status = "skipped"` with `skip_reason = "existing_user_active"` (or `..._inactive`). Notify the user.
- **Author has publicly opted out of cold email:** Set `research_status = "skipped"` with reason. Respect their wishes.
- **Insufficient data for personalization:** Set `research_confidence = "low"` and flag for user review. Don't send generic emails.
- **Author expects platform to promote them:** If research reveals the author has no audience, no social media activity, no newsletter, or a history of complaining about "lack of promotion" from platforms, set `research_status = "skipped"` with `skip_reason = "no_audience_poor_fit"`. The product works like Patreon/Gumroad: authors bring readers, the product provides tools. Authors who expect discovery from the platform have never worked out.
