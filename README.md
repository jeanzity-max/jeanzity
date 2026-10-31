# JEANZITY: free website + order system (GitHub Pages + Supabase)

GitHub Pages shows your website for free. Supabase (free plan) stores the orders.
Every order is saved with an order ID, date and time, customer details, payment details and a status.
You manage orders on your own private page: `your-website-address/admin.html`.

## Part 1: Put the website online (GitHub Pages)
1. At github.com click New repository. Name it `jeanzity`. Choose **Public** (free GitHub Pages needs Public; your orders are never stored in GitHub, so nothing private is exposed). Create it.
2. Click "uploading an existing file". Drag in ALL files from this folder: index.html, admin.html, config.js, schema.sql, README.md and .nojekyll. Click Commit changes.
3. Go to Settings > Pages. Under "Build and deployment" choose Source: **Deploy from a branch**, Branch: **main**, Folder: **/ (root)**. Save.
4. After 1-2 minutes your site is at `https://YOUR-GITHUB-NAME.github.io/jeanzity/`.

## Part 2: Create the order database (Supabase, free)
1. Sign up at supabase.com. New project: name `jeanzity`, choose a database password (save it), pick the region closest to Bangladesh (Singapore). Wait until it is ready.
2. Turn OFF public sign-ups: Authentication > Sign In / Providers > turn off "Allow new users to sign up". (Very important.)
3. Create YOUR login: Authentication > Users > Add user > Create new user. Use your email and a long password. Tick "Auto confirm user".
4. Open `schema.sql` in GitHub (pencil icon to edit). Replace `YOUR_EMAIL_HERE` in 2 places with that same email. Commit.
5. In Supabase open SQL Editor > New query. Paste the whole `schema.sql`. Press Run. You should see "Success".
6. In Supabase go to Project Settings > API. Copy the **Project URL** and the **anon public** key.
7. In GitHub open `config.js`, paste them between the quotes, commit. Never paste the "service_role" key anywhere.

## Part 3: Test it
1. Open your website, fill the order form with a test order, and press the order button. You should see an Order ID.
2. Open `.../admin.html`, log in with your email and password. Your test order should appear. Change its status and press Save.
3. Delete test orders in Supabase > Table Editor > orders.

## Daily use
Open admin.html. For each new order, check the TrxID and amount in your bKash/Nagad history, then set the status to "Paid (verified)". Download the CSV regularly as a backup.

## Prices and delivery
The real prices live in `schema.sql` (c_price and c_delivery). To change: edit them there, run the changed SQL again in Supabase, and also update priceBDT / deliveryChargeBDT in `index.html` so the page shows the same numbers.

## Know the limits of the free plan
- Supabase free projects pause after about 7 days with no activity. Orders would fail until you press "Restore" in Supabase. Visit your admin page at least weekly, or upgrade the plan if you want no pauses.
- There is no spam protection beyond the unique TrxID rule. If fake orders appear, tell me and we add protection.
- Customer names, phones and addresses are personal data. Keep your admin password private and write your privacy policy before launch.
- The system cannot check bKash/Nagad payments itself. An order is only "Paid" after YOU verify it.
