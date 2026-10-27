# Turning on sign-up and the global leaderboard

Takes about 15 minutes. Everything here is free.

1. **Create the project.** Go to supabase.com and choose New project. Pick a region near India (Mumbai) and save the database password somewhere safe.
2. **Create the tables.** In the dashboard, open SQL Editor and choose New query. Paste the whole of `supabase/schema.sql` and click Run.
3. **Set your site address.** Go to Authentication, then URL Configuration.
   - Site URL: your domain, for example `https://youdumb.com`.
   - Redirect URLs: add your domain with a trailing slash, plus the `https://<project>.pages.dev/` address.
4. **Email links.** These are on by default under Authentication, then Providers, then Email.
   - Supabase's built-in mailer only sends a few emails an hour.
   - For real launches, add your own SMTP under Authentication, then Emails, then SMTP settings. Resend's free tier works.
5. **Google sign-in.**
   1. In Google Cloud Console, go to APIs & Services, then Credentials. Create an OAuth client ID of type Web application.
   2. Under Authorized redirect URI, enter `https://<project>.supabase.co/auth/v1/callback`.
   3. Copy the Client ID and Client Secret into Supabase under Authentication, then Providers, then Google, and turn it on.
6. **Connect the site.** Go to Project Settings, then API, and copy the **Project URL** and the **anon public** key.
   - Paste them into `const SUPA = {url: '', key: ''}` in the page, or send them to Claude.
   - The anon key is meant to be public, so sharing it is safe.
   - Never share the `service_role` key.

Until step 6 is done, the site works exactly as before: there's no sign-up gate and the leaderboard section stays hidden.

## Daily battle (Humans vs AI)

1. **Update the database.** Run the latest `supabase/schema.sql` again in the SQL Editor. It is safe to re-run, and it adds the battle, rating and fronts tables and functions.
2. **Add repository secrets.** In GitHub, open the repo's Settings, then Secrets and variables, then Actions, and add:
   - `OPENROUTER_API_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`, found under Project Settings, then API. It must stay secret. Never put it in the website.
3. **Optional: choose the models.** Under the Variables tab:
   - `BATTLE_MODELS` sets which models make up the AI army, as a comma-separated list of OpenRouter model IDs.
   - `BATTLE_WRITER` sets the model that writes the questions.
4. **Run it once.** Go to Actions, open Daily battle, and click Run workflow. After that it runs by itself every day at 05:37 IST. It costs a few rupees a day, and players never trigger an AI call.

Until this is set up, the site runs a practice battle with simulated AI answers. Practice-battle ratings are kept on each player's own device.
