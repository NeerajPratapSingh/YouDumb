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
