# NFC Digital Card System — Build Guide

A multi-user NFC business card platform: people sign up, fill in their profile,
CV, and social links, pick a card design, and get a public URL you write to an
NFC tag. Each card has its own AI assistant tab that answers visitor questions
using that person's profile data.

## Why this needs a backend (not just static HTML)

Your original card was a single static HTML file — great for one person, but
this version needs to support many users signing up with their own data, so it
needs three things a static page can't provide on its own:

1. **Auth** — so people can create an account and only edit their own card.
2. **A database** — to store each person's profile (name, bio, CV link, theme, socials).
3. **A private place to hold your Anthropic API key** — it must never sit in
   frontend code, or anyone can read it from the page source and run up your bill.

**Supabase** covers all three for free (generous free tier, no credit card to start),
and everything else stays as plain HTML/JS, so it still deploys to GitHub Pages
the way your last project did.

## Architecture

```
                     ┌─────────────────────┐
   Visitor's phone   │   card.html?u=edy    │  (public, no login)
   (NFC tap) ───────▶│  reads profile from  │
                      │  Supabase, renders   │
                      │  chosen theme + AI   │
                      └──────────┬───────────┘
                                 │ chat message
                                 ▼
                      ┌──────────────────────┐
                      │ Supabase Edge Function│  ← holds ANTHROPIC_API_KEY
                      │   "ai-assistant"      │     (never exposed to browser)
                      └──────────┬───────────┘
                                 ▼
                          Anthropic API

   You (owner) ───▶ auth.html ───▶ dashboard.html ───▶ writes to
                  (sign up/in)   (edit profile,        Supabase DB + Storage
                                  upload CV, pick
                                  theme, add socials) and phone contact and pofile picture

```

## Files in this project

| File | Purpose |
|---|---|
| `schema.sql` | Database tables + security rules + storage buckets |
| `config.js` | Your Supabase connection details (fill in once) |
| `index.html` | Landing page |
| `auth.html` | Sign up / log in |
| `dashboard.html` | Profile editor — details, CV upload, theme picker, socials |
| `card.html` | The public card the NFC tag points to |
| `styles/themes.css` | Three selectable card designs (Obsidian, Ledger, Terminal) |
| `edge-function/ai-assistant/index.ts` | Serverless function that talks to Claude |

## Step-by-step setup

### 1. Create your Supabase project
- Go to supabase.com → New Project → pick a name, password, region.
- Once it's ready, go to **Project Settings → API** and copy your **Project URL**
  and **anon public key**.
- Paste both into `config.js` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";https://kqgtzxfavhgtcmoiatei.supabase.co
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY"sb_publishable_1c6_7ilYBop20uIyDvTx2Q_rut9PHsE
const SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
### 2. Set up the database
- In the Supabase dashboard, open **SQL Editor → New Query**.
- Paste in the entire contents of `schema.sql` and run it.
- This creates the `profiles` table, locks it down so people can only edit
  their own row, and creates the `cvs` and `avatars` storage buckets.

### 3. Turn on email auth
- **Authentication → Providers** → make sure **Email** is enabled.
- For testing, you can turn off "Confirm email" under **Authentication → Settings**
  so you don't need to click a confirmation link every time you test sign-up.

### 4. Deploy the AI assistant function
You'll need the Supabase CLI (`npm install -g supabase`) and an Anthropic API key
from console.anthropic.com.

```bash
npx supabase functions depoly ai-chat
npx supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase login
supabase link --project-ref YOUR-PROJECT-REF
kqgtzxfavhgtcmoiatei
supabase secrets set ANTHROPIC_API_KEY=sk-ant-your-key-here
sb_publishable_1c6_7ilYBop20uIyDvTx2Q_rut9PHsE
supabase functions deploy ai-assistant --no-verify-jwt
```

`--no-verify-jwt` is needed because visitors tapping the card aren't logged in —
the AI tab is public, like the rest of the card.

After deploying, your function URL is:
`https://YOUR-PROJECT-REF.supabase.co/functions/v1/ai-assistant`
— this is already wired up automatically in `config.js` from `SUPABASE_URL`.

### 5. Test locally
Open `index.html` in a browser (or run a local server: `python3 -m http.server`
from the project folder — opening via `file://` can break some browser APIs).
- Click through to **Sign up**, create a test account.
- You'll land on **dashboard.html** — fill in your details, upload a CV, pick a theme,
  add a couple of social links, hit **Save card**.
- Copy the card link it shows you and open it — that's your public card.
- Try the AI Assistant tab and ask it something about yourself.

### 6. Deploy the frontend
Push this folder to a GitHub repo and enable **GitHub Pages** (Settings → Pages →
deploy from branch), same as your last project. Netlify or Vercel also work —
just drag-and-drop the folder.

### 7. Get your public card link
Once deployed, your card lives at:
`https://yourusername.github.io/your-repo/card.html?u=your-username`

### 8. Write it to your NFC tag
- Buy blank NTAG213/215/216 tags (cheap, widely available).
- Install **NFC Tools** (Android: Play Store / iPhone: App Store).
- Open the app → **Write** → **Add a record** → **URL/URI** → paste your card link.
- Tap **Write** and hold your phone against the NFC tag/sticker/card.
- Test by tapping the tag with another phone — it should open the card directly.

### 9. (Optional) Custom domain
Point a domain you own at your GitHub Pages/Netlify deployment so the link
reads `card.yourdomain.com?u=edy` instead of the default subdomain — nicer on
a physical card, and you can update the destination anytime without re-writing
the tag, since the URL itself never changes.

## Extending it later
- **QR code fallback**: generate a QR code of the same card URL (e.g. with the
  `qrcode` npm package or any free QR generator) for people without NFC phones.
- **Analytics**: add a `visits` count that increments via an edge function each
  time `card.html` loads, so you can see tap activity.
- **More themes**: add a new `[data-theme="..."]` block in `styles/themes.css`
  and an entry in the `theme-grid` in `dashboard.html`.
- **Avatar photos**: the `avatars` bucket is already set up in `schema.sql` —
  add a file input in `dashboard.html` the same way the CV upload works.
