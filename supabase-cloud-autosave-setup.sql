-- MI-RETRIEVE-CODE: account-wide cloud autosave for working projects
-- Run this migration once in Supabase SQL Editor. Safe to run again.

create table if not exists public.mi_project_drafts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  draft jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.mi_project_drafts enable row level security;

revoke all on table public.mi_project_drafts from anon, authenticated;
grant select, insert, update on table public.mi_project_drafts to authenticated;

drop policy if exists "Users can read their own project draft" on public.mi_project_drafts;
create policy "Users can read their own project draft"
  on public.mi_project_drafts
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can create their own project draft" on public.mi_project_drafts;
create policy "Users can create their own project draft"
  on public.mi_project_drafts
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Users can update their own project draft" on public.mi_project_drafts;
create policy "Users can update their own project draft"
  on public.mi_project_drafts
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
