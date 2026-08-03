-- Run this after inviting a relative in Authentication > Users.
-- Replace both values before running the query.

insert into public.family_members (family_id, user_id, role)
select
  '3381218a-bd67-47d9-abcc-a51f8e32f23f'::uuid,
  id,
  'member'
from auth.users
where lower(email) = lower('judy.bagley@furman.edu')
on conflict (family_id, user_id) do nothing;
