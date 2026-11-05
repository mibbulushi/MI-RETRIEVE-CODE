-- MI-RETRIEVE-CODE: general project file attachments
-- Self-contained migration; safe to run again.

-- Compatibility table: older deployments may not have run the image migration.
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
  on public.mi_saved_images(content_id);

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
      where c.id = mi_saved_images.content_id and c.user_id = auth.uid()
    )
  );

drop policy if exists "Owners can delete their project images" on public.mi_saved_images;
create policy "Owners can delete their project images"
  on public.mi_saved_images for delete to authenticated
  using (owner_id = auth.uid());

create table if not exists public.mi_saved_files (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.mi_saved_content(id) on delete cascade,
  owner_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  file_name text not null,
  mime_type text not null default 'application/octet-stream',
  size_bytes bigint not null check (size_bytes > 0),
  created_at timestamptz not null default now()
);

create index if not exists mi_saved_files_content_id_idx
  on public.mi_saved_files(content_id);

alter table public.mi_saved_files enable row level security;
revoke all on table public.mi_saved_files from anon, authenticated;
grant select, insert, delete on public.mi_saved_files to authenticated;

drop policy if exists "Owners read their project files" on public.mi_saved_files;
create policy "Owners read their project files"
  on public.mi_saved_files for select to authenticated
  using (owner_id = auth.uid());

drop policy if exists "Owners add files to their projects" on public.mi_saved_files;
create policy "Owners add files to their projects"
  on public.mi_saved_files for insert to authenticated
  with check (
    owner_id = auth.uid()
    and exists (
      select 1 from public.mi_saved_content c
      where c.id = mi_saved_files.content_id and c.user_id = auth.uid()
    )
  );

drop policy if exists "Owners delete their project files" on public.mi_saved_files;
create policy "Owners delete their project files"
  on public.mi_saved_files for delete to authenticated
  using (owner_id = auth.uid());

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('mi-project-files', 'mi-project-files', false, 26214400, null)
on conflict (id) do update
set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = null;

drop policy if exists "Owners upload project files" on storage.objects;
create policy "Owners upload project files"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'mi-project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners read their project files" on storage.objects;
create policy "Owners read their project files"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'mi-project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Owners delete their project files" on storage.objects;
create policy "Owners delete their project files"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'mi-project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create or replace function public.mi_can_view_shared_file(p_path text)
returns boolean
language sql stable security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.mi_saved_files f
    join public.mi_shared_access s on s.content_id = f.content_id
    where f.storage_path = p_path
      and s.is_active = true
      and (s.expires_at is null or s.expires_at > now())
  );
$$;
revoke all on function public.mi_can_view_shared_file(text) from public;
grant execute on function public.mi_can_view_shared_file(text) to anon, authenticated;

drop policy if exists "Shared viewers can read shared project files" on storage.objects;
create policy "Shared viewers can read shared project files"
  on storage.objects for select to anon, authenticated
  using (
    bucket_id = 'mi-project-files'
    and public.mi_can_view_shared_file(name)
  );

drop function if exists public.mi_get_shared_content(text);
create function public.mi_get_shared_content(p_code text)
returns table (
  title text,
  content text,
  created_at timestamptz,
  images jsonb,
  files jsonb
)
language sql stable security definer
set search_path = public, pg_temp
as $$
  select
    c.title,
    c.content,
    c.created_at,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'path', i.storage_path, 'file_name', i.file_name, 'mime_type', i.mime_type
      ) order by i.created_at)
      from public.mi_saved_images i where i.content_id = c.id
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'path', f.storage_path, 'file_name', f.file_name, 'mime_type', f.mime_type,
        'size_bytes', f.size_bytes
      ) order by f.created_at)
      from public.mi_saved_files f where f.content_id = c.id
    ), '[]'::jsonb)
  from public.mi_shared_access s
  join public.mi_saved_content c on c.id = s.content_id
  where upper(s.share_code) = upper(trim(p_code))
    and s.is_active = true
    and (s.expires_at is null or s.expires_at > now())
  limit 1;
$$;
revoke all on function public.mi_get_shared_content(text) from public;
grant execute on function public.mi_get_shared_content(text) to anon, authenticated;
