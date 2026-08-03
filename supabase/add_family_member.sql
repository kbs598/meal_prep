-- Run this after inviting a relative in Authentication > Users.
-- Replace both values before running the query.

insert into public.family_members (family_id, user_id, role)
select
  'REPLACE-WITH-FAMILY-ID'::uuid,
  id,
  'member'
from auth.users
where lower(email) = lower('REPLACE-WITH-RELATIVE-EMAIL@example.com')
on conflict (family_id, user_id) do nothing;
