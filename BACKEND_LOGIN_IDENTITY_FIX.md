# Backend fix: Login identity — same user, same row, same points

**Bug:** After logout/login, the app shows the user’s posts and points gone.

**Cause:** The same person may be getting a **different `users.id`** on each login (e.g. new row per login), or profile is not returning `points_balance` / `total_points_earned` from the DB.

**Goal:** Same email/provider always maps to the **same `users` row**; profile always returns that row’s `points_balance` and `total_points_earned`.

---

## 1. Log identity in login/signup

In the handlers that run after successful auth (login and signup/register):

- Resolve the authenticated user to a **single `users` row** (by email, or by provider + provider_user_id).
- **Log the resolved `users.id`** so you can confirm it’s stable across logins.

**Example (Node/Express):**

```js
// After you resolve the user (e.g. findOrCreateUser)
const user = await findOrCreateUser(email, provider, providerUserId);
console.log('[LOGIN] resolved users.id for', email, ':', user.id);
// Return this user (and token) to the client
```

**Example (signup):**

```js
// After creating or finding the user
const user = await findOrCreateUser(email, username, ...);
console.log('[SIGNUP] resolved users.id for', email, ':', user.id);
```

Use whatever your actual function/variable names are; the important part is logging the **DB `users.id`** that you attach to the token and return to the app.

---

## 2. Log identity in GET /auth/profile

In **GET /auth/profile** (or equivalent):

- **Log** the user id you take from the request (e.g. `req.user.id` or the id decoded from the token).
- **Log** the user row you load from the DB (at least `id`, `email`, `points_balance`, `total_points_earned`).

**Example (Node/Express):**

```js
// In GET /auth/profile handler
const tokenUserId = req.user?.id; // or decoded JWT sub
console.log('[PROFILE] req.user.id (or token userId):', tokenUserId);

const userRow = await db.query('SELECT id, email, username, points_balance, total_points_earned, ... FROM users WHERE id = $1', [tokenUserId]);
const row = userRow.rows[0];
console.log('[PROFILE] DB row:', row ? { id: row.id, email: row.email, points_balance: row.points_balance, total_points_earned: row.total_points_earned } : 'NOT FOUND');
```

**Check:** After login, call **GET /auth/profile** and confirm in logs:

- `tokenUserId` matches the `users.id` you logged in login/signup.
- The DB row is found and has the expected `points_balance` and `total_points_earned`.

If the token has a different id than the one you expect, or the row is missing, that explains “points/posts gone” after re-login.

---

## 3. Same email/provider → same users row

Ensure one real-world identity always maps to one `users` row:

- **Email-based auth:** One row per email. Use **UNIQUE(email)** and look up by email on login; do not create a new row per login.
- **OAuth:** One row per provider + provider user id. Use **UNIQUE(provider, provider_user_id)** (or a single composite unique), and look up by that pair; do not create a new row per login.

**Schema (if not already):**

```sql
-- Email-based: one row per email
ALTER TABLE public.users ADD CONSTRAINT users_email_unique UNIQUE (email);

-- OAuth: one row per (provider, provider_user_id)
-- ALTER TABLE public.users ADD CONSTRAINT users_provider_uid_unique UNIQUE (provider, provider_user_id);
```

**Logic:**

- **Login:** Find user by email (or provider + provider_user_id). If found, use that row and issue a token for that `users.id`. If not found and you allow auto-register, create **one** row then use it.
- **Signup/Register:** If a row with that email (or provider uid) already exists, **do not** create a second row. Either return an error (“email already registered”) or treat as login and return that existing row (UPSERT-style).
- **UPSERT example (email):** “INSERT INTO users (email, ...) VALUES ($1, ...) ON CONFLICT (email) DO UPDATE SET last_login_at = NOW() RETURNING *” so the same email always gets the same row.

Result: same email/provider → same `users.id` every time → same points and same `submitted_by` for “my content”.

---

## 4. Profile response must include points from DB

The app expects **GET /auth/profile** (and the login response’s `user` object) to include:

- **points_balance**
- **total_points_earned**

**Check:**

- Your SELECT in the profile handler (and in login/signup when you return the user) must include these columns.
- The JSON you send to the client must include them (snake_case: `points_balance`, `total_points_earned`).

**Example SELECT:**

```sql
SELECT id, email, username, points_balance, total_points_earned,
       current_streak, last_checkin, total_checkins,
       notification_time, notifications_enabled, is_admin, created_at
FROM public.users
WHERE id = $1;
```

If these are missing from the SELECT or from the serialized response, the app will show 0 or stale values after login.

---

## 5. Checklist

| # | Task | Done |
|---|------|------|
| 1 | In login endpoint: log the resolved **users.id** for the authenticated user. | |
| 2 | In signup endpoint: log the resolved **users.id** (after find or create). | |
| 3 | In GET /auth/profile: log **req.user.id** (or decoded token userId). | |
| 4 | In GET /auth/profile: log the **DB row** returned (id, email, points_balance, total_points_earned). | |
| 5 | Enforce **one row per identity**: UNIQUE(email) and/or UNIQUE(provider, provider_user_id). | |
| 6 | Use **UPSERT / find-then-return** so the same email/provider never gets a new row on login. | |
| 7 | Profile (and login user object) response includes **points_balance** and **total_points_earned** from DB. | |

After deploying, log in once and then logout and log in again. In backend logs you should see:

- The same **users.id** on both logins.
- The same **users.id** in profile.
- Profile DB row with the expected points.

If all that holds, the app will show the same points and the same “my content” (same `submitted_by` id) after re-login.
