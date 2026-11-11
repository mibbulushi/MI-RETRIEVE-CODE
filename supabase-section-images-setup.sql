-- MI-RETRIEVE-CODE: section-aware image captions and explanations.
-- Run once in Supabase SQL Editor after deploying the matching website update.

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

alter table public.mi_saved_images
  add column if not exists section_index integer not null default 0,
  add column if not exists section_title text not null default '',
  add column if not exists caption text not null default '',
  add column if not exists description text not null default '',
  add column if not exists sort_order integer not null default 0;

create index if not exists mi_saved_images_content_section_idx
  on public.mi_saved_images(content_id, section_index, sort_order);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('mi-project-images', 'mi-project-images', false, 5242880,
        array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Keep the existing password verification and rate-limit protections.
-- The added JSON properties let the signed-in recipient see the image in its section.
create or replace function public.mi_get_shared_content_secure(
  p_code text,
  p_password text,
  p_ip_hash text
)
returns table (
  title text,
  content text,
  created_at timestamptz,
  images jsonb,
  files jsonb
)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_share public.mi_shared_access%rowtype;
  v_now timestamptz := now();
  v_attempts public.mi_share_access_attempts%rowtype;
begin
  if p_code is null or p_ip_hash is null or length(p_ip_hash) > 128 then
    return;
  end if;

  select * into v_share
    from public.mi_shared_access s
   where upper(s.share_code) = upper(trim(p_code))
     and s.is_active = true
     and (s.expires_at is null or s.expires_at > v_now)
   limit 1;

  if not found then
    return;
  end if;

  insert into public.mi_share_access_attempts(code_key, ip_hash)
  values (upper(trim(p_code)), p_ip_hash)
  on conflict (code_key, ip_hash) do nothing;

  select * into v_attempts
    from public.mi_share_access_attempts a
   where a.code_key = upper(trim(p_code))
     and a.ip_hash = p_ip_hash
   for update;

  if v_attempts.blocked_until is not null and v_attempts.blocked_until > v_now then
    return;
  end if;

  if v_attempts.window_started_at < v_now - interval '15 minutes' then
    update public.mi_share_access_attempts
       set window_started_at = v_now, failed_attempts = 0, blocked_until = null
     where code_key = upper(trim(p_code)) and ip_hash = p_ip_hash;
  end if;

  if v_share.password_hash is not null then
    if p_password is null or extensions.crypt(p_password, v_share.password_hash) <> v_share.password_hash then
      update public.mi_share_access_attempts
         set failed_attempts = failed_attempts + 1,
             blocked_until = case when failed_attempts + 1 >= 8 then v_now + interval '15 minutes' else blocked_until end
       where code_key = upper(trim(p_code)) and ip_hash = p_ip_hash;
      return;
    end if;
  end if;

  delete from public.mi_share_access_attempts
   where code_key = upper(trim(p_code)) and ip_hash = p_ip_hash;

  return query
  select
    c.title,
    c.content,
    c.created_at,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'path', i.storage_path,
        'file_name', i.file_name,
        'mime_type', i.mime_type,
        'section_index', i.section_index,
        'section_title', i.section_title,
        'caption', i.caption,
        'description', i.description,
        'sort_order', i.sort_order
      ) order by i.section_index, i.sort_order, i.created_at)
      from public.mi_saved_images i where i.content_id = c.id
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'path', f.storage_path, 'file_name', f.file_name, 'mime_type', f.mime_type,
        'size_bytes', f.size_bytes
      ) order by f.created_at)
      from public.mi_saved_files f where f.content_id = c.id
    ), '[]'::jsonb)
  from public.mi_saved_content c
  where c.id = v_share.content_id;
end;
$$;

revoke all on function public.mi_get_shared_content_secure(text, text, text) from public, anon, authenticated;
grant execute on function public.mi_get_shared_content_secure(text, text, text) to service_role;
