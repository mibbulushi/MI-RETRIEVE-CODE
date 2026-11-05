-- MI-RETRIEVE-CODE: student sharing setup
-- Run this script once in Supabase > SQL Editor.
-- This creates a separate, explicit share code. Existing private retrieve codes stay private.

create table if not exists public.mi_shared_access (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null unique references public.mi_saved_content(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  share_code text not null unique,
  is_active boolean not null default true,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists mi_shared_access_share_code_idx
  on public.mi_shared_access (share_code);

alter table public.mi_shared_access enable row level security;

-- The share table itself is never publicly readable.
revoke all on table public.mi_shared_access from anon, authenticated;
grant select, insert, update on table public.mi_shared_access to authenticated;

drop policy if exists "Owners can view their share links" on public.mi_shared_access;
create policy "Owners can view their share links"
  on public.mi_shared_access
  for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists "Owners can create share links for their content" on public.mi_shared_access;
create policy "Owners can create share links for their content"
  on public.mi_shared_access
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and exists (
      select 1
      from public.mi_saved_content c
      where c.id = content_id
        and c.user_id = auth.uid()
    )
  );

drop policy if exists "Owners can update their share links" on public.mi_shared_access;
create policy "Owners can update their share links"
  on public.mi_shared_access
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Public retrieval is available only when the exact active share code is supplied.
-- This function returns the content, not the private owner account details or share table.
create or replace function public.mi_get_shared_content(p_code text)
returns table (
  title text,
  content text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select c.title, c.content, c.created_at
  from public.mi_shared_access s
  join public.mi_saved_content c on c.id = s.content_id
  where upper(s.share_code) = upper(trim(p_code))
    and s.is_active = true
    and (s.expires_at is null or s.expires_at > now())
  limit 1;
$$;

revoke all on function public.mi_get_shared_content(text) from public;
grant execute on function public.mi_get_shared_content(text) to anon, authenticated;
