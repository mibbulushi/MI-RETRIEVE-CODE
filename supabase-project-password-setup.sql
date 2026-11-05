-- MI Project Password Protection: database migration
-- Apply only after deploying the matching share-access Edge Function and updating the website.
-- Existing unprotected share codes remain accessible through the Edge Function without a password.

create extension if not exists pgcrypto with schema extensions;

alter table public.mi_shared_access
  add column if not exists password_hash text;

create table if not exists public.mi_share_access_attempts (
  code_key text not null,
  ip_hash text not null,
  window_started_at timestamptz not null default now(),
  failed_attempts integer not null default 0,
  blocked_until timestamptz,
  primary key (code_key, ip_hash)
);

alter table public.mi_share_access_attempts enable row level security;
revoke all on public.mi_share_access_attempts from anon, authenticated, public;

create or replace function public.mi_set_share_password(
  p_code text,
  p_password text
)
returns boolean
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Sign in required';
  end if;

  if p_password is not null and length(p_password) < 8 then
    raise exception 'Password must contain at least 8 characters';
  end if;

  update public.mi_shared_access
     set password_hash = case
       when p_password is null or p_password = '' then null
       else extensions.crypt(p_password, extensions.gen_salt('bf', 12))
     end
   where upper(share_code) = upper(trim(p_code))
     and owner_id = v_user_id;

  return found;
end;
$$;

revoke all on function public.mi_set_share_password(text, text) from public, anon;
grant execute on function public.mi_set_share_password(text, text) to authenticated;

-- Remove the old public-by-code RPC. All public retrieval must go through the Edge Function.
drop function if exists public.mi_get_shared_content(text);

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
  from public.mi_saved_content c
  where c.id = v_share.content_id;
end;
$$;

revoke all on function public.mi_get_shared_content_secure(text, text, text) from public, anon, authenticated;
grant execute on function public.mi_get_shared_content_secure(text, text, text) to service_role;

-- A password-protected share must never be readable directly from Storage.
drop policy if exists "Shared viewers can read shared project images" on storage.objects;
drop policy if exists "Shared viewers can read shared project files" on storage.objects;

-- Public execution of the old attachment-check helpers is no longer needed.
revoke all on function public.mi_can_view_shared_file(text) from public, anon, authenticated;
