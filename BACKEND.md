# Backend & PostgreSQL Guide for MoodLift iOS

This document describes what the iOS app expects from your API and what PostgreSQL schema/SQL you need so everything works (points, feed, unlock, content submission reward).

---

## 1. API Base

- **Base URL:** `https://moodlift.suntzutechnologies.com/api` (or your own)
- All endpoints below are relative to this base (e.g. `/auth/profile` → `GET {base}/auth/profile`).

---

## 2. Points System (Critical)

The app shows **one** “Points” value everywhere (Profile, Home, Content detail). These bugs are fixed only if the backend uses a **single spendable balance** and records all point changes.

### 2.1 Single spendable balance

- The app reads **`points_balance`** (and `points`) from **`GET /auth/profile`** and **`GET /users/stats`**.
- **Unlock** must **check and deduct** the **same** field (e.g. `points_balance`). Do not use one column for display and another for unlock.
- **Unlock cost:** **5 points** per locked content item. Your `POST /content/:id/unlock` should deduct 5 from the user’s spendable balance.

### 2.2 Check-in reward

- When **`POST /checkin`** runs, add the check-in reward (e.g. 1 point) to the user’s **spendable balance** (e.g. `points_balance`) and to `total_points_earned`.
- Return in the check-in response: `total_points` = new balance after the reward, so the app can show it immediately.
- **Record the transaction** (see Section 4) so it appears in “Recent activity”.

### 2.3 Content submission reward

- When **`POST /content/submit`** succeeds, **award 1 point** to the submitting user (add to `points_balance` and optionally `total_points_earned`).
- **Record the transaction** (see Section 4) with a description like `"Content submission"` so it appears in “Recent activity”.

---

## 3. Content vs feed (two separate tables)

Use **two tables** so admin content and user submissions stay separate:

| Table | Purpose | Who writes | Used by |
|-------|---------|------------|---------|
| **`content`** | Curated, unlockable content (daily Encouragement, Jokes, Fun Facts, etc.) | **Admin only** | Daily content API, unlock flow |
| **`feed_posts`** (or `user_content`) | User-submitted posts for the community feed | **Users** via submit | **Feed API only** |

- **Do not** insert user submissions into `content`. User submissions go only into the **feed** table.
- **Do not** use the feed table for daily/unlock content. The app’s category screens (Encouragement, Jokes, etc.) and unlock use the **content** table (admin data).
- **Feed** = read only from the user-submissions table. User-submitted content always shows in the feed (no mixing with admin content).

---

## 4. Feed table and API (user submissions only)

Create a dedicated table for user submissions and use it **only** for the feed.

### 4.1 Create the feed table (PostgreSQL)

Run this in PostgreSQL:

```sql
-- User-submitted content for the Feeds tab only. Not used for daily/unlock content.
CREATE TABLE IF NOT EXISTS feed_posts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_text      TEXT,
  question          TEXT,
  answer            TEXT,
  option_a          TEXT,
  option_b          TEXT,
  option_c          TEXT,
  option_d          TEXT,
  correct_option    VARCHAR(1),
  author            TEXT,
  category          VARCHAR(50) NOT NULL,
  content_type      VARCHAR(20) NOT NULL,
  submitted_by      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  submitter_username VARCHAR(255),
  status            VARCHAR(20) NOT NULL DEFAULT 'visible',
  upvotes           INT NOT NULL DEFAULT 0,
  downvotes         INT NOT NULL DEFAULT 0,
  report_count      INT NOT NULL DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feed_posts_created_at ON feed_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_posts_submitted_by ON feed_posts(submitted_by);
```

- **POST /content/submit** (or your submit endpoint): **INSERT into `feed_posts`** only. Do not insert into `content`.
- **GET /content/feed**: **SELECT from `feed_posts`** only (newest first). Return the same JSON shape as below so the app can display feed cards.

### 4.2 Response shape for feed (same as app expects)

```json
{
  "data": [
    {
      "id": "uuid",
      "content_text": "...",
      "question": null,
      "answer": null,
      "option_a": null,
      "option_b": null,
      "option_c": null,
      "option_d": null,
      "correct_option": null,
      "author": null,
      "category": "encouragement",
      "content_type": "text",
      "submitted_by": "user-uuid",
      "submitter_username": "kev",
      "status": "approved",
      "upvotes": 0,
      "downvotes": 0,
      "report_count": 0,
      "user_vote": null,
      "is_unlocked": null,
      "created_at": "2026-02-17T12:00:00.000Z"
    }
  ],
  "total": 42,
  "page": 1,
  "total_pages": 3
}
```

### 4.3 Feed query (read from `feed_posts` only)

The app calls **`GET /content/feed?page=1&limit=20&sort=newest`**. Query **only** `feed_posts`:

```sql
SELECT
  id,
  content_text,
  question,
  answer,
  option_a, option_b, option_c, option_d,
  correct_option,
  author,
  category,
  content_type,
  submitted_by,
  submitter_username,
  status,
  upvotes,
  downvotes,
  report_count,
  created_at
FROM feed_posts
ORDER BY created_at DESC
LIMIT :limit
OFFSET :offset;
```

- User submissions always show in the feed (no approval step required unless you add one; then filter by `status`).
- For **vote** (like/dislike) on a feed post: update `upvotes`/`downvotes` on the row in **`feed_posts`** (and optionally a `content_votes` table). Do not use the `content` table for feed votes.

### 4.4 When using the `content` table for feed and My Content

If you use the **single `content` table** (no `feed_posts`), apply these rules:

- **Feed (GET /content/feed) — everyone’s content:**  
  Return **all** rows where **`submitted_by IS NOT NULL`** (i.e. every user who has posted). Everyone can post, and everyone sees everyone else’s posts in the feed. When the app refreshes the feed, return the **latest** posts from **all users**, ordered by `created_at DESC`. Do **not** filter by the current user — the feed is shared by everyone.
- **My Content (GET /content/mine):**  
  Return only rows where **`submitted_by` = current user’s id`** (from the auth token). So "my content" is only that user’s own posts.

**Example feed query (content table) — everyone’s posts, latest first:**

```sql
-- Returns all users' submissions (everyone can see everyone's posts). No filter by current user.
SELECT id, content_text, question, answer, option_a, option_b, option_c, option_d,
       correct_option, author, category, content_type, submitted_by, submitter_username,
       status, upvotes, downvotes, report_count, created_at
FROM content
WHERE submitted_by IS NOT NULL
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```

When the app calls **GET /content/feed** (e.g. on refresh), use this query so the feed shows the latest posts from **everyone**.

**Example my-content query (content table):**

```sql
SELECT id, content_text, question, answer, option_a, option_b, option_c, option_d,
       correct_option, author, category, content_type, submitted_by, submitter_username,
       status, upvotes, downvotes, report_count, created_at
FROM content
WHERE submitted_by = :current_user_id
ORDER BY created_at DESC
LIMIT :limit OFFSET :offset;
```

Replace `:current_user_id` with the authenticated user’s id from the token.

---

## 5. Points transactions (record every change)

“Record down” means: every time you add or subtract points (check-in, submission reward, unlock), insert a row so the app’s **Recent activity** (and points history) is correct.

### 5.1 Table (create if you don’t have it)

Run this in PostgreSQL:

```sql
-- Points transactions (earned + spent) for history / Recent activity
CREATE TABLE IF NOT EXISTS points_transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  transaction_type  VARCHAR(20) NOT NULL CHECK (transaction_type IN ('earned', 'spent')),
  points_amount     INT NOT NULL CHECK (points_amount > 0),
  description       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_points_transactions_user_created
  ON points_transactions(user_id, created_at DESC);
```

### 5.2 When to insert

| Event              | transaction_type | points_amount | description (example)   |
|--------------------|------------------|---------------|--------------------------|
| Check-in           | `earned`         | 1 (or your rule) | `Daily check-in day N`   |
| Content submission | `earned`         | 1             | `Content submission`     |
| Unlock content     | `spent`          | 5             | `Unlocked content`       |
| Welcome/signup     | `earned`         | 5             | `Welcome bonus`          |

- **Earned:** add `points_amount` to the user’s `points_balance` (and optionally `total_points_earned`), then insert a row.
- **Spent:** subtract `points_amount` from `points_balance`, then insert a row.

---

## 6. PostgreSQL: users table (balance columns)

Ensure your `users` table has a single spendable balance used everywhere (profile, stats, unlock, check-in, submit). Example:

```sql
-- Example columns (names can match your app’s CodingKeys)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS points_balance INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_points_earned INT NOT NULL DEFAULT 0;

-- Optional: keep in sync if you still use points for something
-- UPDATE users SET points_balance = points WHERE points_balance = 0 AND points > 0;
```

- Use **`points_balance`** as the single source for “current points” in:
  - `GET /auth/profile`
  - `GET /users/stats`
  - `POST /content/:id/unlock` (check and deduct)
  - `POST /checkin` (add reward)
  - `POST /content/submit` (add 1 point reward)

---

## 7. Admin content table (for daily / unlock only)

- The **`content`** table holds **admin-only** curated content (daily Encouragement, Jokes, Fun Facts, Inspiration).
- **Daily content** API (e.g. `GET /content/:category/daily`) reads from **`content`**.
- **Unlock** (`POST /content/:id/unlock`) applies to rows in **`content`** (admin content), not to `feed_posts`.
- Only admins (or your admin tooling) should **INSERT/UPDATE** `content`. User submit flow must not write to this table.

---

## 8. Content feed query – legacy (if you had used content for feed)

If you previously used `content` for the feed, stop. Use **`feed_posts`** for the feed (see Section 4). Below is kept only for reference of the **content** table shape.

Use your existing **content** table (or equivalent). Example:

```sql
-- Feed: newest first, optional include_pending
-- :include_pending = 1 when app sends include_pending=1
SELECT
  id,
  content_text,
  question,
  answer,
  option_a, option_b, option_c, option_d,
  correct_option,
  author,
  category,
  content_type,
  submitted_by,
  submitter_username,
  status,
  upvotes,
  downvotes,
  report_count,
  created_at
FROM content
WHERE status IN ('approved', 'pending')   -- or only 'approved' if not using include_pending
  AND (:include_pending = 0 OR status IN ('approved', 'pending'))
ORDER BY created_at DESC
LIMIT :limit
OFFSET :offset;
```

Total count for pagination:

```sql
SELECT COUNT(*) AS total
FROM content
WHERE status IN ('approved', 'pending');
```

---

## 9. Award 1 point on content submit (backend logic + SQL)

**Important:** You must do **both** (1) and (2). If you only insert the transaction row, "Recent activity" will show "+1" but the **Points** balance will not increase. The app uses `points_balance` from the profile; that only changes if you run the `UPDATE users` below.

After you insert the row into **`feed_posts`** (user feed table; see Section 4) and before returning the created post to the app:

1. **Update the user’s balance:** Add 1 to the submitting user’s `points_balance` (and optionally `total_points_earned`).
2. **Record the transaction:** Insert a row into `points_transactions` so it appears in Recent activity.

**In your backend code (Node, Python, etc.):** Use parameterized queries and pass the authenticated user’s id. The placeholders below (`:submitting_user_id` or `$1`) are replaced by your app—**do not run them as raw SQL** in pgAdmin/DBeaver/psql or you’ll get `syntax error at or near ":"`.

```sql
-- 1. Award 1 point to the user who submitted (use the authenticated user id from your app)
UPDATE users
SET points_balance = points_balance + 1,
    total_points_earned = total_points_earned + 1
WHERE id = $1;   -- or :submitting_user_id in Node/pg, (?) in some drivers

-- 2. Record the transaction
INSERT INTO points_transactions (user_id, transaction_type, points_amount, description)
VALUES ($1, 'earned', 1, 'Content submission');
```

Use the same user id you use for the content row (e.g. `submitted_by`). In Node (pg) you’d run: `client.query('UPDATE users SET ... WHERE id = $1', [userId])` and the same for the INSERT.

**If you need to run something once in PostgreSQL (e.g. to test or fix one user):** Replace the placeholder with a real UUID in single quotes:

```sql
-- Replace 'YOUR-USER-UUID-HERE' with the actual user id (e.g. from SELECT id FROM users WHERE email = 'kevinsoon01@yahoo.com')
UPDATE users
SET points_balance = points_balance + 1,
    total_points_earned = total_points_earned + 1
WHERE id = 'YOUR-USER-UUID-HERE';

INSERT INTO points_transactions (user_id, transaction_type, points_amount, description)
VALUES ('YOUR-USER-UUID-HERE', 'earned', 1, 'Content submission');
```

---

## 10. Unlock: deduct 5 points and record

When **`POST /content/:id/unlock`** runs:

1. Check `points_balance >= 5`.
2. Deduct 5: `UPDATE users SET points_balance = points_balance - 5 WHERE id = :user_id`.
3. Insert: `INSERT INTO points_transactions (user_id, transaction_type, points_amount, description) VALUES (:user_id, 'spent', 5, 'Unlocked content');`
4. Mark the content as unlocked for that user (your existing unlock logic).

---

## 11. Check-in: add reward and record

When **`POST /checkin`** runs:

1. Compute reward (e.g. 1 point for day 1).
2. `UPDATE users SET points_balance = points_balance + :reward, total_points_earned = total_points_earned + :reward, ... WHERE id = :user_id`.
3. `INSERT INTO points_transactions (user_id, transaction_type, points_amount, description) VALUES (:user_id, 'earned', :reward, 'Daily check-in day ' || :day);`
4. Return in the response the new **total_points** (e.g. new `points_balance`) so the app can show it immediately.

---

## 12. Points history API (app already calls this)

**`GET /users/points-history?page=1&limit=50`** should return paginated transactions from **points_transactions** for the authenticated user, in descending order of `created_at`. Response shape (snake_case):

```json
{
  "data": [
    {
      "id": "uuid",
      "transaction_type": "earned",
      "points_amount": 1,
      "description": "Content submission",
      "created_at": "2026-02-17T12:00:00.000Z"
    }
  ],
  "total": 10,
  "page": 1,
  "total_pages": 1
}
```

---

## 13. Summary checklist

| Item | Action |
|------|--------|
| Two tables | **`content`** = admin-only (daily/unlock). **`feed_posts`** = user submissions for the feed only. |
| **Single `content` table** | **Feed:** only rows where **`submitted_by IS NOT NULL`** (everyone’s posts). **My Content:** only rows where **`submitted_by` = current user id**. |
| Feed = everyone | **GET /content/feed** returns **all users’** submissions (no filter by current user). Refresh shows latest from everyone. |
| Submit | **POST /content/submit** inserts into **`feed_posts`** (or `content` with `submitted_by` set). Award 1 point and record transaction. |
| Single spendable balance | Use `points_balance` (or one column) for profile, stats, unlock, check-in, and submit. |
| Unlock cost | Deduct **5** points per unlock on **`content`** rows; record a `spent` transaction. |
| Check-in | Add reward to `points_balance`, return new total in response, insert `earned` transaction. |
| Transactions table | Create **points_transactions** if missing; insert a row on every earn/spend. |

Running the SQL in Sections 4, 5, 6 (and the logic in 7–13, adjusted to your schema) will align the backend with the app and fix the points and feed behavior described in this doc.
