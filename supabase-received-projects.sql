-- MI-RETRIEVE-CODE: account-based received projects
-- Run this once in Supabase SQL Editor. Existing saved projects and share codes are not changed.

create table if not exists public.mi_received_projects (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  share_code text not null,
  project_title text not null,
  project_data jsonb not null,
  project_created_at timestamptz,
  received_at timestamptz not null default now(),
  unique (recipient_id, share_code)
);

create index if not exists mi_received_projects_recipient_idx
  on public.mi_received_projects (recipient_id, received_at desc);

alter table public.mi_received_projects enable row level security;
revoke all on table public.mi_received_projects from anon, authenticated;
grant select, delete on table public.mi_received_projects to authenticated;

drop policy if exists "Recipients can view their received projects" on public.mi_received_projects;
create policy "Recipients can view their received projects"
  on public.mi_received_projects
  for select to authenticated
  using (recipient_id = auth.uid());

drop policy if exists "Recipients can remove projects from their received list" on public.mi_received_projects;
create policy "Recipients can remove projects from their received list"
  on public.mi_received_projects
  for delete to authenticated
  using (recipient_id = auth.uid());
