# Discovery Workflow — Finding New Authors to Prospect

## Overview

This workflow finds new authors who match the ideal profile (see `knowledge/ideal-author-profile.md`). Unlike the research workflow which enriches known contacts, discovery starts from scratch: scanning platforms, bestseller lists, social media, and communities to build a prospect list.

## When to Use

- "Find me authors to reach out to"
- "Scout new prospects in romance"
- "Who's trending in fantasy right now?"
- "Find authors complaining about Amazon"
- "Search for fanfic writers ready to go original"

## Step 1: Define the Search

Ask the user (or use defaults from the ideal profile):

- **Genre(s)** to focus on (default: romance, romantasy, thriller, fantasy)
- **Audience size range** (default: 1,000+ readers)
- **Platform focus** (default: all)
- **How many prospects** to find (default: 20-30 per batch)
- **Any specific angle** (e.g., "find authors going wide", "find fanfic writers with original work")

## Step 2: Platform Scanning

### Amazon KDP Bestseller Lists

Search Amazon bestseller and hot new release lists by genre subcategory.

```
Search queries:
site:amazon.com/gp/bestsellers/digital-text "{genre}"
site:amazon.com "Best Sellers in {genre}" Kindle
```

For each bestseller list:
- Note authors ranking in the top 100 for their subcategory
- Check if they're indie (look for publisher name = author name or known indie imprints)
- Check if they're in KDP Select (look for "Kindle Unlimited" badge)
- Follow "also bought" chains to find related authors
- Visit author pages to assess catalog size and activity

### Wattpad

```
Search queries:
site:wattpad.com/story "{genre}" completed
site:wattpad.com/user popular "{genre}"
"Wattys" winner OR finalist {year} {genre}
wattpad paid stories "{genre}" author
```

Look for:
- Authors in the Paid Stories program (already monetizing)
- Wattys award winners and finalists
- Stories with 100K+ reads and high engagement
- Authors whose profiles link to original published work

### Tapas / Radish / Royal Road / Kindle Vella

```
site:tapas.io popular "{genre}"
site:radishfiction.com "{genre}"
site:royalroad.com/fiction best-rated "{genre}"
"Kindle Vella" popular author "{genre}"
```

Look for:
- Top-ranked serialized fiction authors
- Authors with completed series (more likely to want to publish as books)
- Authors with Patreon or other monetization alongside the platform

### Kobo / Barnes & Noble / Draft2Digital

Authors on these platforms are already "wide" (not Amazon-exclusive). This is a very strong signal.

```
site:kobo.com/ebook "{genre}" bestseller
site:barnesandnoble.com/w "{genre}" nook
site:draft2digital.com/catalog "{genre}"
```

### Direct Sales Platforms

Authors selling through their own stores are Tier 1 prospects.

```
"{genre} author" site:payhip.com
"{genre}" ebook site:gumroad.com
"{genre} author" bookfunnel OR "direct sales"
"{genre} author" shopify ebook store
```

## Step 3: Social Media Scanning

### Twitter/X — Intent Signals and Active Authors

Search for authors posting buying signals (see `ideal-author-profile.md` for full signal list):

```
"leaving KDP Select" OR "going wide"
"Amazon royalties" frustrated OR unfair OR low
"direct to reader" author OR writer
#goingwide OR #wideauthor
"KDP Select not worth" OR "not renewing KDP"
```

Search for active authors in target genres:

```
#WritingCommunity #Romance "my book" OR "new release"
#IndieAuthor #Fantasy published OR "out now"
#AmWriting {genre} "newsletter" OR "sign up"
#SelfPub {genre} "available on" OR "buy direct"
```

### BookTok (TikTok)

Can't search directly via API, but use web search:

```
site:tiktok.com "@" {genre} author "my book"
"BookTok" {genre} author "self-published" OR "indie"
"BookTok author" {genre} viral OR trending
```

Look for authors (not reviewers) who promote their own work and have 10K+ followers.

### Instagram (Bookstagram)

```
site:instagram.com "{genre} author" OR "{genre} writer"
"bookstagram" "{genre}" author "link in bio" published
```

### Reddit

```
site:reddit.com/r/selfpublish "{genre}" author
site:reddit.com/r/eroticauthors "going wide" OR "leaving KU"
site:reddit.com/r/litrpg author "my book"
site:reddit.com/r/romancebooks author AMA OR "I wrote"
site:reddit.com/r/FanFiction "original work" OR "publishing" OR "transitioning"
site:reddit.com/r/indieauthors "readership" OR "making money" OR "monetize"
site:reddit.com/r/fantasywriters "publishing" OR "marketing" OR "self-publish"
site:reddit.com/r/romancewriters "royalties" OR "marketing" OR "KDP"
site:reddit.com/r/YAwriters "publishing" OR "market" OR "self-publish"
site:reddit.com/r/HFY "published" OR "my book" OR "available on"
```

See `knowledge/reddit-communities.md` for full Reddit engagement strategy per subreddit.

## Step 4: Community Scanning

### 20BooksTo50K (Priority Community)

```
"20BooksTo50K" speaker OR panelist {year}
"20Books" conference "{genre}" author
site:facebook.com "20BooksTo50K" going wide OR direct sales
"20Books Vegas" author {genre}
```

### Wide for the Win (Priority Community)

```
"Wide for the Win" author OR member
"wide for the win" podcast guest
#WideForTheWin author
```

### Podcasts — Guest Authors

Authors who appear as guests on indie publishing podcasts are active, business-minded, and reachable.

```
"Self Publishing Formula" podcast guest {genre}
"Creative Penn" podcast guest {genre}
"Sell More Books Show" guest {genre}
"Six Figure Authors" podcast guest
"Indie Author Podcast" guest {genre}
"Kobo Writing Life" podcast guest
```

### Conference Speaker Lists

```
"NINC" {year} speaker OR panelist
"RWA" conference {year} speaker
"ThrillerFest" {year} panelist
"20Books Vegas" {year} schedule OR speakers
"Superstars Writing Seminars" {year}
```

## Step 5: Fanfiction Discovery

### AO3 (Archive of Our Own)

AO3 can't be searched via API easily, but use web search to find top authors:

```
site:archiveofourown.org/users "{fandom}" works kudos
"AO3" author "original work" OR "published" OR "debut novel"
"archive of our own" writer "now available on Amazon" OR "my novel"
```

Target fandoms with large overlap to commercial genres:
- Fantasy fandoms (ACOTAR, Tolkien, HP) → Fantasy/Romantasy authors
- Romance fandoms (K-drama, Bridgerton) → Romance authors
- Sci-fi fandoms (Star Wars, Mass Effect) → Sci-fi authors

### Wattpad to Published Pipeline

Many successful authors started on Wattpad. Search for those who made the jump:

```
"started on Wattpad" published author {genre}
"Wattpad" "now available" OR "published" {genre}
"from Wattpad to" published OR Amazon OR "my book"
```

### Fanfic Writers with Patreon/Ko-fi

Already monetizing their writing = strong signal:

```
"{fandom}" writer OR author site:patreon.com
"{genre}" "original fiction" site:patreon.com
"AO3" OR "fanfiction" author site:ko-fi.com
```

## Step 6: Qualify and Score

For each discovered author, quickly assess against the must-have criteria from `ideal-author-profile.md`:

1. Writes in English? (skip if not)
2. Audience of 1,000+? (estimate from followers, reviews, read counts)
3. Sellable genre? (check against genre priority list)
4. Active online? (posted in the last 3 months)

Then score using the priority tiers:
- Check for newsletter (priority signal — these authors can bring readers on day one)
- Check for direct sales presence (Tier 1 signal — they already understand "bring your audience")
- Check for active social media promotion of their own work (required — the product rewards authors who already have an audience)
- Check for intent signals (Tier 1 signal)
- Check publication history (3+ books for indie, 1+ for trad-pub, N/A for fanfic)
- Note if they're from a warm community (20BooksTo50K, Wide for the Win)
- **Disqualify** if they have no audience, no social presence, and no way to bring readers. The product is not a discovery platform.

## Step 7: Check for Existing Accounts

Before adding to the prospect list:

```
site:{product_domain} "{author_name}"
"{author_name}" {product_domain}
```

If found, flag as `existing_user` and route to the re-engagement or referral flow instead (see `ideal-author-profile.md`).

## Step 8: Append to Google Sheets

For each qualified prospect, find their contact information before adding to the Sheet. **An author without at least an email or a website is not actionable.** Don't add prospects you can't reach.

Contact info to find:
- **Email** (required if possible) — check their website contact/about page, newsletter signup, Amazon author page, social media bios, BookFunnel/StoryOrigin profiles
- **Website/blog URL** — personal site, landing page, Linktree
- **Social media profiles** — Twitter/X, Instagram, TikTok, Facebook, LinkedIn, YouTube
- **Newsletter** — Substack, Beehiiv, ConvertKit landing page, or "join my list" link

Search queries for contact info:
```
"{author_name}" contact OR email site:{their_website}
"{author_name}" author email
"{author_name}" "sign up" OR "subscribe" OR "newsletter"
"{author_name}" site:linktr.ee OR site:beacons.ai
```

Append a row to the Google Sheet using `scripts/sheets.sh append '<json>'`. Set `research_status: "discovered_by_skill"` so the Enrichment workflow knows this is a discovery-phase row that still needs full research before outreach. Include:
- All discoverable contact and profile info (emails, website, every social profile found)
- `research_status: "discovered_by_skill"` (not yet fully researched — Enrichment workflow will complete it)
- `discovery_source:` where you found them (e.g., "Amazon Romance Top 100", "Twitter #goingwide", "AO3 kudos leader")
- `priority_score:` from the scoring in Step 6
- `intent_signals:` any buying signals found, with links and dates
- `warm_community:` if they belong to 20BooksTo50K, Wide for the Win, etc.
- `author_type:` one of `indie`, `trad-pub`, `hybrid`, `fanfic`, `fanfic+original`, `content-creator`, `author-preneur`, `serialized`

## Step 9: Present Results

Show the user a summary grouped by priority:

```
### Discovery Results: {genre} — {date}

**Tier 1 (High Priority) — {count} authors**
1. {Name} — {genre}, {audience_size}, {key_signal}
2. ...

**Tier 2 (Good Prospects) — {count} authors**
1. ...

**Tier 3 (Long Game) — {count} authors**
1. ...

**Skipped — {count}**
- {Name}: already a user
- {Name}: non-English
- ...

**Total qualified: {count}**
Ready to proceed to full research on any or all of these?
```

The user can then approve which authors to move to the full research workflow (`workflows/research.md`).
