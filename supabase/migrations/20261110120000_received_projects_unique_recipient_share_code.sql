-- Ensure each recipient stores a shared project only once per share code.
-- The Edge Function uses upsert(..., onConflict: "recipient_id,share_code").
-- Keep the most recently received copy if legacy duplicates already exist.

with ranked as (
  select
    ctid,
    row_number() over (
      partition by recipient_id, upper(trim(share_code))
      order by received_at desc nulls last, ctid desc
    ) as row_num
  from public.mi_received_projects
)
delete from public.mi_received_projects as target
using ranked
where target.ctid = ranked.ctid
  and ranked.row_num > 1;

create unique index if not exists mi_received_projects_recipient_share_code_uidx
  on public.mi_received_projects (recipient_id, share_code);

