-- MI-RETRIEVE-CODE: student sharing + multiple image setup
-- Run this updated script in Supabase > SQL Editor.
-- Safe to run again. Existing private Retrieve Codes remain private.

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
revoke all on table public.mi_shared_access from anon, authenticated;
grant select, insert, update on public.mi_shared_access to authenticated;

drop policy if exists "Owners can view their share links" on public.mi_shared_access;
create policy "Owners can view their share links"
  on public.mi_shared_access for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists "Owners can create share links for their content" on public.mi_shared_access;
create policy "Owners can create share links for their content"
  on public.mi_shared_access for insert to authenticated
  with check (
    owner_id = auth.uid()
    and exists (
      select 1 from public.mi_saved_content c
      where c.id = mi_shared_access.content_id
        and c.user_id = auth.uid()
    )
  );

drop policy if exists "Owners can update their share links" on public.mi_shared_access;
create policy "Owners can update their share links"
  on public.mi_shared_access for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Metadata for images attached to saved projects.
create table if not exists public.mi_saved_images (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.mi_saved_content(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes > 0),
  created_at timestamptz not null default now()
);

create index if not exists mi_saved_images_content_id_idx
  on public.mi_saved_images (content_id);

alter table public.mi_saved_images enable row level security;
revoke all on table public.mi_saved_images from anon, authenticated;
grant select, insert, delete on table public.mi_saved_images to authenticated;

drop policy if exists "Owners can view their project images" on public.mi_saved_images;
create policy "Owners can view their project images"
  on public.mi_saved_images for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists "Owners can add images to their content" on public.mi_saved_images;
create policy "Owners can add images to their content"
  on public.mi_saved_images for insert to authenticated
  with check (
    owner_id = auth.uid()
    and exists (
      select 1 from public.mi_saved_content c
      where c.id = mi_saved_images.content_id
        and c.user_id = auth.uid()
    )
  );

drop policy if exists "Owners can delete their project images" on public.mi_saved_images;
create policy "Owners can delete their project images"
  on public.mi_saved_images for delete to authenticated
  using (owner_id = auth.uid());

-- Private bucket: image reads are allowed only for active, non-expired shared projects.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('mi-project-images', 'mi-project-images', false, 5242880,
        array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Storage RLS: owners upload/manage only inside their own user-id folder.
drop policy if exists "Owners upload project images" on storage.objects;
create policy "Owners upload project images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'mi-project-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners read their project images" on storage.objects;
create policy "Owners read their project images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'mi-project-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners delete their project images" on storage.objects;
create policy "Owners delete their project images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'mi-project-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Helper: allows anonymous signed-URL creation only for images belonging to an active share code.
create or replace function public.mi_can_view_shared_image(p_path text)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.mi_saved_images i
    join public.mi_shared_access s on s.content_id = i.content_id
    where i.storage_path = p_path
      and s.is_active = true
      and (s.expires_at is null or s.expires_at > now())
  );
$$;

revoke all on function public.mi_can_view_shared_image(text) from public;
grant execute on function public.mi_can_view_shared_image(text) to anon, authenticated;

drop policy if exists "Shared viewers can read shared project images" on storage.objects;
create policy "Shared viewers can read shared project images"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'mi-project-images'
    and public.mi_can_view_shared_image(name)
  );

-- Public-by-code RPC returns project text plus image metadata, never owner account details.
drop function if exists public.mi_get_shared_content(text);
create function public.mi_get_shared_content(p_code text)
returns table (
  title text,
  content text,
  created_at timestamptz,
  images jsonb
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    c.title,
    c.content,
    c.created_at,
    coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'path', i.storage_path,
          'file_name', i.file_name,
          'mime_type', i.mime_type
        ) order by i.created_at
      )
      from public.mi_saved_images i
      where i.content_id = c.id
    ), '[]'::jsonb) as images
  from public.mi_shared_access s
  join public.mi_saved_content c on c.id = s.content_id
  where upper(s.share_code) = upper(trim(p_code))
    and s.is_active = true
    and (s.expires_at is null or s.expires_at > now())
  limit 1;
$$;

revoke all on function public.mi_get_shared_content(text) from public;
grant execute on function public.mi_get_shared_content(text) to anon, authenticated;
