# Supabase setup for Weeknight Five

You do not need npm, Node.js, a database password, a secret key, or a service-role key. The app already contains the Supabase browser library and its public connection settings.

## Part 1: Create the secure tables

1. Sign in at <https://supabase.com/dashboard>.
2. Open the **Family Meal Plan** organization.
3. Open the **weeknight-five** project.
4. In the narrow left sidebar, click **SQL Editor**. Its icon looks like `>_` inside a small square.
5. Click **New query**. If Supabase offers templates, choose **Blank query**.
6. On your computer, open `supabase/schema.sql` from this project folder.
7. Select all of that file's text and copy it.
8. Return to the blank Supabase query and paste the text into the large editor.
9. Click **Run** near the lower-right corner of the editor.
10. Wait for the green success message. The script can safely be run again if you are unsure whether it finished.
11. Click **Table Editor** in the left sidebar. Confirm that these four tables now appear: `families`, `family_members`, `family_recipes`, and `user_app_data`.

Do not continue if the SQL editor shows a red error. Copy the full error before changing anything.

## Part 2: Point Supabase email links to the app

1. In the Supabase left sidebar, click **Authentication**.
2. Open **URL Configuration**. Depending on the dashboard layout, it may be under **Configuration**.
3. In **Site URL**, enter exactly:

   `https://kbs598.github.io/meal_prep/`

4. Under **Redirect URLs**, click **Add URL**.
5. Enter the same address exactly, including the final slash:

   `https://kbs598.github.io/meal_prep/`

6. Click **Save**.
7. Under **Authentication > Providers > Email**, leave email/password sign-in enabled.
8. Recommended: turn off public self-sign-up if the screen offers **Allow new users to sign up**. Relatives will be invited by you instead.

## Part 3: Create your own owner account

Do this after the updated app has been pushed to GitHub Pages, so any email link can return to the working app.

1. Go to **Authentication > Users**.
2. Click **Add user**.
3. Choose **Create new user** if it is offered.
4. Enter your own email address.
5. Enter a new password with at least eight characters. Save it in your password manager.
6. Turn on **Auto Confirm User** if that choice appears.
7. Click **Create user**.
8. Confirm that your email now appears in the Users table.

If the dashboard only offers **Send invitation**, use that instead. Open the email, click its link, and set your password in the app.

## Part 4: Make your account the family owner

1. Return to **SQL Editor** and click **New query**.
2. Open `supabase/create_family_owner.sql` on your computer.
3. Copy all of its text into the query editor.
4. Find this exact placeholder:

   `REPLACE-WITH-YOUR-EMAIL@example.com`

5. Replace only the placeholder with the same email address you created in Part 3. Leave the single quote marks around it.
6. Optional: replace `Our Family` with your preferred family collection name. Leave its single quote marks in place.
7. Click **Run**.
8. A success result should appear. In the Messages area, Supabase also prints the new family ID.
9. Open **Table Editor > family_members**. You should see one row with role `owner`.
10. Open **Table Editor > families**. You should see one family row.

## Part 5: Sign in and move existing browser recipes

1. Open <https://kbs598.github.io/meal_prep/>.
2. Wait for the app to finish loading.
3. Open the **Settings** tab.
4. In **Family account**, enter the owner email and password from Part 3.
5. Press **Sign in**.
6. The thin cloud bar near the top should turn green and show **Family sync on**.
7. If the account card says this browser has recipes while the family collection is empty, press **Upload browser recipes** once.
8. Press **Sync now**.
9. Open **My Recipes** and confirm that your recipes are still listed.

## Part 6: Invite one relative

Repeat these steps separately for each person. Each person should use their own email address and password.

1. In Supabase, open **Authentication > Users**.
2. Click **Add user > Send invitation**.
3. Enter the relative's email address and send the invitation.
4. The invited user appears in the Users table immediately. Keep this page open.
5. Open **Table Editor > families** in another tab and copy the family's `id` value. It is a long UUID with dashes.
6. Return to **SQL Editor** and create a blank query.
7. Open `supabase/add_family_member.sql` on your computer and copy all of it into the query editor.
8. Replace `REPLACE-WITH-FAMILY-ID` with the copied family ID. Keep the single quote marks.
9. Replace `REPLACE-WITH-RELATIVE-EMAIL@example.com` with the exact invited email. Keep the single quote marks.
10. Click **Run** and wait for success.
11. Ask the relative to open the Supabase invitation email on their phone. If it is missing, check Spam or Junk.
12. They click the invitation link. It opens Weeknight Five in their browser.
13. In **Settings > Family account**, they enter and confirm a new password, then press **Save my password**.
14. If the app asks them to sign in, they use the invited email and the password they just chose.
15. They press **Sync now**. The family's shared recipes should appear under **My Recipes**.

Invitation emails expire. If a link reports that it expired, return to **Authentication > Users** and send a new invitation.

## What is shared

- Shared with family members: recipes entered or imported under **My Recipes**.
- Private to each signed-in person: pantry, household settings, meal history, ZIP/region, and ALDI/Publix deal entries.
- Also kept on each device: a browser backup, so the app remains usable while signed out or temporarily offline.

## Safety check

In **Database > Tables**, every public app table should show Row Level Security as enabled. Never paste an `sb_secret_...` key, a `service_role` key, or the database password into the app, GitHub, or a message.
