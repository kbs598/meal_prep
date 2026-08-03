-- Run this only after the owner has an account in Authentication > Users.
-- Replace the email and family name, then run the whole query once.

do $$
declare
  owner_email text := 'REPLACE-WITH-YOUR-EMAIL@example.com';
  new_family_name text := 'Our Family';
  owner_id uuid;
  new_family_id uuid;
begin
  select id into owner_id from auth.users where lower(email) = lower(owner_email);
  if owner_id is null then
    raise exception 'No Supabase user found for %. Create or invite that user first.', owner_email;
  end if;

  select family_id into new_family_id
  from public.family_members
  where user_id = owner_id
  limit 1;

  if new_family_id is null then
    insert into public.families (name, created_by)
    values (new_family_name, owner_id)
    returning id into new_family_id;

    insert into public.family_members (family_id, user_id, role)
    values (new_family_id, owner_id, 'owner');
  end if;

  raise notice 'Family id: %', new_family_id;
end $$;
