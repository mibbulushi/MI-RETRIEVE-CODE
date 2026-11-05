# Deploy MI Project Password Protection

The database migration and Edge Function source are committed, but password protection is not active yet. The website interface update is intentionally pending so the existing Share Code retrieval does not break before the backend is deployed.

## Important order

1. Deploy the Edge Function named `share-access` from `supabase/functions/share-access/index.ts`.
2. Apply `supabase-project-password-setup.sql` once in the Supabase SQL Editor.
3. Open the website and test both a protected and an unprotected Share Code.

Do not share or paste the Supabase service-role key into GitHub, the website, or a chat. Supabase provides the Edge Function environment variables `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`; keep the service-role key server-side only.

## Deploy the Edge Function in the Supabase Dashboard

1. Open the MI-RETRIEVE-CODE Supabase project.
2. Open **Edge Functions**.
3. Create a function named `share-access`.
4. Replace its editor content with the complete contents of `supabase/functions/share-access/index.ts`.
5. Deploy the function.

## Apply the database migration

1. Open **SQL Editor** in the same Supabase project.
2. Open the GitHub file `supabase-project-password-setup.sql`.
3. Copy the complete SQL file into a new SQL query.
4. Run it once and check for a successful result.

The migration adds a bcrypt password hash, an owner-only password-setting RPC, a server-only verification RPC with per-IP attempt limiting, removes the old public content RPC, and removes direct public attachment-read policies.

## Website integration (pending)

After the Edge Function and database migration are deployed and verified, the website interface must be updated to show the optional owner password controls and the recipient password field. That frontend update has not yet been applied to the live website.

## Intended website behavior after full integration

- New projects may have an optional Share Code password.
- Recipients enter the Share Code and, when needed, the project password.
- Owners can set/change or remove a password for an existing Share Code.
- The Edge Function verifies access and creates short-lived attachment links.
- Existing Share Codes without passwords remain usable.

## Before calling it complete

Test:
- An unprotected Share Code.
- A protected Share Code with the correct password.
- The same code with a wrong password.
- An attached image and an attached file.
- Password changes and removal by the owner.
- Password changes attempted by a different account.

Do not describe the feature as active until these checks pass.
