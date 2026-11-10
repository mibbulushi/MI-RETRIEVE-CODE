-- Add the uniqueness required by the received-project upsert.
-- This script does NOT delete or modify existing project records.
do $$
begin
  if exists (
    select 1
    from public.mi_received_projects
    group by recipient_id, share_code
    having count(*) > 1
  ) then
    raise exception 'Duplicate recipient/share-code records exist. No records were changed. Please review duplicates before adding the unique index.';
  end if;
end
$$;

create unique index if not exists mi_received_projects_recipient_share_code_uidx
  on public.mi_received_projects (recipient_id, share_code);
