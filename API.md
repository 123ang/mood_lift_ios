# MoodLift API Documentation

**Production base URL:** `https://moodlift.suntzutechnologies.com/api`

For deployment (Nginx, PM2, PostgreSQL), see your backend repo’s deployment docs.

---

## Authentication

Most endpoints require a JWT. Send it in the request header:

```
Authorization: Bearer <your_jwt_token>
```

You get a token from **Register** or **Login**. Use it for all subsequent requests that require auth.

---

## Rate limits

| Path | Limit |
|------|--------|
| `/api/auth/*` (login, register) | 20 requests per 15 minutes |
| All other `/api/*` | 100 requests per 15 minutes |

When exceeded, the API returns `429` with: `{ "error": "Too many requests, please try again later." }`.

---

## Points system (summary)

MoodLift uses a single spendable balance (`points_balance`) shown everywhere in the app. All changes are recorded in `points_transactions` for history and “Recent activity”.

| Action | Points | Notes |
|--------|--------|--------|
| **Submit content** | **+1** | Every time the user submits a post. |
| **Daily check-in** | **+1** | Once per calendar day. |
| **Every 5th check-in day** | **+6** | Days 5, 10, 15, 20, … get 1 base + 5 bonus. |
| **Unlock content** | **−5** | Cost per locked item. Max **1 unlock per category per day** (4 categories → max **4 content unlocks per day**). |
| **Unlock theme** | **−50** | Cost per theme. One-time unlock per theme. |
| **Welcome / signup** | **+5** | Optional one-time bonus. |

**Check-in rule:** Normal day → **1** point. If the check-in is the user’s 5th, 10th, 15th, … day → **6** points.  
**GET /checkin/info** returns `next_points`: **1** or **6** (6 when the next check-in would be a 5th/10th/15th/… day).

---

## Endpoints

### Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/health` | No | Server health check |

**Response:** `200`

```json
{
  "status": "ok",
  "timestamp": "2025-02-13T12:00:00.000Z"
}
```

---

### Auth (`/api/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | No | Register a new user |
| POST | `/api/auth/login` | No | Log in |
| GET | `/api/auth/profile` | Yes | Get current user profile |
| PUT | `/api/auth/profile` | Yes | Update profile |
| POST | `/api/auth/change-password` | Yes | Change password |

#### POST `/api/auth/register`

**Body:**

```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "securePassword123"
}
```

| Field | Type | Required | Description |
|-------|------|-----------|-------------|
| email | string | Yes | Unique email |
| username | string | Yes | Unique username |
| password | string | Yes | Plain password |

**Success:** `201`

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "username": "johndoe",
    "points": 5,
    "points_balance": 5,
    "current_streak": 0,
    "last_checkin": null,
    "total_checkins": 0,
    "total_points_earned": 5,
    "notification_time": "08:00:00",
    "notifications_enabled": true,
    "is_admin": false,
    "created_at": "2025-02-13T12:00:00.000Z"
  }
}
```

**Errors:** `400` – missing fields; `409` – email or username already exists.

---

#### POST `/api/auth/login`

**Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Success:** `200` – same shape as register (`token`, `user`; `user` does not include `password_hash`).

**Errors:** `400` – missing fields; `401` – invalid credentials.

---

#### GET `/api/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Success:** `200`

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "johndoe",
  "points": 15,
  "points_balance": 15,
  "current_streak": 3,
  "last_checkin": "2025-02-13T00:00:00.000Z",
  "total_checkins": 10,
  "total_points_earned": 50,
  "notification_time": "08:00:00",
  "notifications_enabled": true,
  "is_admin": false,
  "created_at": "2025-01-01T00:00:00.000Z"
}
```

**Errors:** `401` – no/invalid token; `404` – user not found.

---

#### PUT `/api/auth/profile`

**Headers:** `Authorization: Bearer <token>`

**Body:** All fields optional; only send what you want to change.

```json
{
  "username": "newname",
  "notification_time": "09:00:00",
  "notifications_enabled": false
}
```

**Success:** `200` – full profile object (same shape as GET profile).

---

#### POST `/api/auth/change-password`

**Headers:** `Authorization: Bearer <token>`

**Body:**

```json
{
  "currentPassword": "oldPassword",
  "newPassword": "newSecurePassword"
}
```

**Success:** `200` – `{ "message": "Password updated successfully" }`

**Errors:** `400` – missing fields; `401` – current password incorrect.

---

### Content (`/api/content`)

Content categories: `encouragement` | `inspiration` | `jokes` | `facts`  
Content types: `text` | `quiz` | `qa`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/content/:category` | Optional | List content by category (paginated) |
| GET | `/api/content/:category/daily` | Yes | Get or create today’s daily content for user |
| POST | `/api/content/submit` | Yes | Submit new content |
| POST | `/api/content/:id/vote` | Yes | Upvote or downvote |
| POST | `/api/content/:id/report` | Yes | Report content |
| POST | `/api/content/:id/unlock` | Yes | Unlock content with points |

---

#### GET `/api/content/:category`

**Path:** `:category` = `encouragement` | `inspiration` | `jokes` | `facts`

**Query:**

| Param | Type | Default | Description |
|-------|------|---------|-------------|
| page | number | 1 | Page number |
| limit | number | 20 | Items per page |
| sort | string | `newest` | `newest` or `top_rated` |

**Headers:** `Authorization: Bearer <token>` optional. If sent, each content item includes `user_vote`: `"up"` | `"down"` | `null`, and `is_unlocked`: `true` | `false`.

**Success:** `200`

```json
{
  "data": [
    {
      "id": "uuid",
      "content_text": "Optional text",
      "question": "Optional",
      "answer": "Optional",
      "option_a": "Optional",
      "option_b": "Optional",
      "option_c": "Optional",
      "option_d": "Optional",
      "correct_option": "a",
      "author": "Author name",
      "category": "encouragement",
      "content_type": "text",
      "submitted_by": "uuid",
      "submitter_username": "johndoe",
      "status": "active",
      "upvotes": 10,
      "downvotes": 1,
      "report_count": 0,
      "user_vote": "up",
      "is_unlocked": true,
      "created_at": "2025-02-13T12:00:00.000Z"
    }
  ],
  "total": 100,
  "page": 1,
  "total_pages": 5
}
```

---

#### GET `/api/content/:category/daily`

Returns today’s daily content for the authenticated user. If none exist, new assignments are created (up to 10 items).

**Success:** `200`

```json
[
  {
    "id": "uuid",
    "content_id": "uuid",
    "category": "encouragement",
    "position_in_day": 1,
    "is_unlocked": false,
    "content": {
      "id": "uuid",
      "content_text": "...",
      "question": "...",
      "answer": "...",
      "option_a": "...",
      "option_b": "...",
      "option_c": "...",
      "option_d": "...",
      "correct_option": "a",
      "author": "...",
      "category": "encouragement",
      "content_type": "quiz",
      "submitted_by": "uuid",
      "submitter_username": "johndoe",
      "status": "active",
      "upvotes": 0,
      "downvotes": 0,
      "report_count": 0,
      "user_vote": null,
      "is_unlocked": false,
      "created_at": "2025-02-13T12:00:00.000Z"
    }
  }
]
```

---

#### POST `/api/content/submit`

**Body:** At least `category` required. Other fields depend on `content_type`.

```json
{
  "category": "encouragement",
  "content_type": "text",
  "content_text": "You've got this!",
  "author": "Anonymous",
  "question": null,
  "answer": null,
  "option_a": null,
  "option_b": null,
  "option_c": null,
  "option_d": null,
  "correct_option": null
}
```

For quiz/qa, set `question`, `answer`, and options as needed. `content_type` defaults to `text`.

**Success:** `201` – full content object as stored.

**Errors:** `400` – category missing.

---

#### POST `/api/content/:id/vote`

**Body:**

```json
{
  "vote_type": "up"
}
```

`vote_type`: `"up"` | `"down"`. Re-voting updates the vote.

**Success:** `200` – returns the full updated content item:

```json
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
  "author": "...",
  "category": "encouragement",
  "content_type": "text",
  "submitted_by": "uuid",
  "submitter_username": "johndoe",
  "status": "active",
  "upvotes": 11,
  "downvotes": 1,
  "report_count": 0,
  "user_vote": "up",
  "is_unlocked": true,
  "created_at": "2025-02-13T12:00:00.000Z"
}
```

**Errors:** `400` – `vote_type` missing or not `"up"`/`"down"`.

---

#### POST `/api/content/:id/report`

**Body:**

```json
{
  "reason": "Spam or inappropriate content"
}
```

**Success:** `200` – `{ "message": "Report submitted" }`. One report per user per content (duplicate is no-op).

**Errors:** `400` – reason missing.

---

#### POST `/api/content/:id/unlock`

Unlocks **content** for the user. Each unlock costs **5 points** (deducted from `points_balance`).

**Limit:** The user may unlock at most **1 content per category per day** (categories: `encouragement`, `inspiration`, `jokes`, `facts`). So at most **4 content unlocks per day** in total.

**Success:** `200`

```json
{
  "message": "Content unlocked",
  "points_spent": 5,
  "remaining_balance": 10
}
```

**Errors:**  
- `400` – already unlocked for this user.  
- `400` – daily limit reached for this category: `{ "error": "Daily unlock limit reached for this category", "category": "encouragement" }`.  
- `400` – not enough points: `{ "error": "Not enough points", "required": 5, "balance": 2 }`.

---

### Check-in (`/api/checkin`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/checkin/info` | Yes | Check-in status and next points |
| POST | `/api/checkin` | Yes | Perform daily check-in |

---

#### GET `/api/checkin/info`

**Success:** `200`

```json
{
  "current_streak": 3,
  "last_checkin": "2025-02-12T00:00:00.000Z",
  "total_checkins": 10,
  "can_checkin": true,
  "next_points": 1
}
```

Points: **1** point on a normal day; **6** points (1 + 5 bonus) on every 5th check-in day (5, 10, 15, 20, …). Return `next_points`: 1 or 6 (6 when `total_checkins + 1` is divisible by 5).

---

#### POST `/api/checkin`

**Success:** `200`

```json
{
  "message": "Check-in successful",
  "points_earned": 1,
  "new_streak": 4,
  "total_points": 17
}
```

`points_earned` is **1** on normal days, **6** on every 5th day (5, 10, 15, …).

**Errors:** `400` – already checked in today.

---

### Saved (`/api/saved`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/saved` | Yes | List saved items |
| POST | `/api/saved/:contentId` | Yes | Save content |
| DELETE | `/api/saved/:contentId` | Yes | Remove saved item |

---

#### GET `/api/saved`

**Query:** `category` (optional) – filter by content category.

**Success:** `200` – array of saved items with joined content fields:

```json
[
  {
    "id": "uuid",
    "saved_at": "2025-02-13T12:00:00.000Z",
    "content_id": "uuid",
    "category": "encouragement",
    "content_text": "...",
    "question": null,
    "answer": null,
    "option_a": null,
    "option_b": null,
    "option_c": null,
    "option_d": null,
    "correct_option": null,
    "author": "...",
    "content_type": "text"
  }
]
```

---

#### POST `/api/saved/:contentId`

**Success:** `201` – `{ "message": "Content saved" }`. Duplicate save is no-op.

---

#### DELETE `/api/saved/:contentId`

**Success:** `200` – `{ "message": "Saved item removed" }`

---

### Users (`/api/users`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/users/points-history` | Yes | Points transaction history |
| GET | `/api/users/stats` | Yes | User stats summary |

---

#### GET `/api/users/points-history`

**Query:** `page` (default 1), `limit` (default 50).

**Success:** `200`

```json
{
  "data": [
    {
      "id": "uuid",
      "transaction_type": "earned",
      "points_amount": 5,
      "description": "Daily check-in day 7",
      "created_at": "2025-02-13T12:00:00.000Z"
    }
  ],
  "total": 20,
  "page": 1,
  "total_pages": 1
}
```

`transaction_type`: `earned` | `spent`. `points_amount` is positive for earned, negative for spent.

---

#### GET `/api/users/stats`

**Success:** `200`

```json
{
  "points_balance": 25,
  "current_streak": 5,
  "total_checkins": 30,
  "total_points_earned": 80,
  "total_content_submitted": 2,
  "total_saved": 5,
  "member_since": "2025-01-01T00:00:00.000Z"
}
```

---

### Admin (`/api/admin`)

All admin routes require **Bearer token** and **admin user** (`is_admin: true`). Non-admin gets `403`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin/stats` | Dashboard counts |
| GET | `/api/admin/reported` | Reported content with report details |
| DELETE | `/api/admin/content/:id` | Soft-delete content (status → deleted) |

---

#### GET `/api/admin/stats`

**Success:** `200`

```json
{
  "total_users": 100,
  "total_content": 50,
  "total_reports": 5,
  "active_content": 48
}
```

---

#### GET `/api/admin/reported`

**Success:** `200` – array of content items that have reports, each with a `reports` array (id, user_id, reason, created_at) and `submitted_by_username`.

---

#### DELETE `/api/admin/content/:id`

**Success:** `200` – `{ "message": "Content deleted", "id": "uuid" }`

**Errors:** `404` – content not found.

---

### Themes (`/api/themes`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/themes` | Yes | List available themes (locked / unlocked for user) |
| POST | `/api/themes/:id/unlock` | Yes | Unlock a theme for 50 points |

---

#### GET `/api/themes`

**Success:** `200` – list of themes, each with at least `id`, `name`, `is_unlocked` (boolean for current user), and optionally `preview_url` or display info.

```json
[
  { "id": "uuid", "name": "Ocean", "is_unlocked": false },
  { "id": "uuid", "name": "Sunset", "is_unlocked": true }
]
```

---

#### POST `/api/themes/:id/unlock`

Unlocks a **theme** for the user. Costs **50 points** (one-time per theme).

**Success:** `200`

```json
{
  "message": "Theme unlocked",
  "points_spent": 50,
  "remaining_balance": 20
}
```

**Errors:**  
- `400` – theme already unlocked for this user.  
- `400` – not enough points: `{ "error": "Not enough points", "required": 50, "balance": 30 }`.  
- `404` – theme not found.

---

## Common error responses

| Status | Meaning |
|--------|--------|
| 400 | Bad request – missing/invalid body or params |
| 401 | Unauthorized – no token, invalid token, or token expired |
| 403 | Forbidden – e.g. admin required |
| 404 | Resource not found |
| 409 | Conflict – e.g. email/username already exists |
| 429 | Too many requests (rate limit) |
| 500 | Server error |

Error body shape: `{ "error": "Message" }`. Some endpoints add fields (e.g. `required`, `balance` for unlock).

---

## Auth error messages

- `No token provided` – missing or wrong `Authorization` format (use `Bearer <token>`).
- `Invalid token` – malformed or wrong secret.
- `Token expired` – JWT expired; user must log in again.
- `User not found` – token valid but user was deleted.

---

# Backend implementation guide

This section describes what the iOS app expects from your API and what PostgreSQL schema/SQL you need so everything works (points, feed, unlock, content submission, check-in, login identity).

---

## 1. Points system (critical)

The app shows **one** “Points” value everywhere. Use a **single spendable balance** (`points_balance`) and record all changes in `points_transactions`.

**Points rules:**

| Event | Points |
|-------|--------|
| **Submit content** | **1** per submission |
| **Daily check-in** | **1** per day |
| **Every 5th check-in day** (5, 10, 15, 20, …) | **1 + 5 = 6** that day |
| **Unlock content** | **−5** per unlock; max **1 per category per day** (4 categories → max 4 content unlocks/day) |
| **Unlock theme** | **−50** per theme (one-time per theme) |
| **Welcome/signup** | **5** (optional) |

- **GET /auth/profile** and **GET /users/stats** must return `points_balance` and `total_points_earned`.
- **POST /content/:id/unlock** must check balance ≥ 5, enforce **1 unlock per category per day** (per user), deduct 5, and record transaction.
- **POST /themes/:id/unlock** must check balance ≥ 50, deduct 50, and record transaction (one-time per theme per user).
- **GET /checkin/info** must return `next_points`: **1** normally, **6** when `(total_checkins + 1) % 5 == 0`.
- **POST /checkin** must award 1 or 6, update balance, and insert an `earned` transaction.
- **POST /content/submit** must award 1, update balance, and insert an `earned` transaction.

---

## 2. Content vs feed (tables)

**Option A – Two tables**

| Table | Purpose | Who writes |
|-------|---------|------------|
| **`content`** | Curated, unlockable content (daily, categories) | Admin only |
| **`feed_posts`** | User submissions for the feed | Users via submit |

- User submit → INSERT into **`feed_posts`** only.
- **GET /content/feed** → SELECT from **`feed_posts`** only.

**Option B – Single `content` table**

- **Feed:** return rows where **`submitted_by IS NOT NULL`** (everyone’s posts). Do **not** filter by current user.
- **My Content (GET /content/mine):** return rows where **`submitted_by` = current user id**.

---

## 3. Feed table and API (if using feed_posts)

Create the feed table:

```sql
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

**GET /content/feed** must return `{ "data": [...], "total", "page", "total_pages" }`. If you use the **`content`** table for feed instead, use the query in the next section.

---

## 4. GET /content/feed fix (single content table)

If **GET /content/feed** returns empty but **GET /content/:category** returns rows, the feed handler is likely using the wrong query or DB.

**Data query (use exactly this):**

```sql
SELECT id, content_text, question, answer,
       option_a, option_b, option_c, option_d, correct_option,
       author, category, content_type,
       submitted_by, submitter_username,
       status, upvotes, downvotes, report_count,
       created_at
FROM public.content
WHERE status = 'active' AND submitted_by IS NOT NULL
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;
```

Params: `$1` = limit (e.g. 20), `$2` = (page − 1) × limit.

**Count query:**

```sql
SELECT COUNT(*) FROM public.content
WHERE status = 'active' AND submitted_by IS NOT NULL;
```

- **Do not** filter by current user id. Feed = everyone’s posts.
- Response: `{ "data": [...], "total": N, "page": 1, "total_pages": ceil(total/limit) }`.

---

## 5. Login identity (same user, same row)

**Bug:** After logout/login, points or “my content” disappear.

**Cause:** Same person gets a different `users.id` per login, or profile does not return `points_balance` / `total_points_earned`.

**Fix:**

- One row per identity: **UNIQUE(email)** and/or **UNIQUE(provider, provider_user_id)**. On login/signup, find by email (or provider+uid); do not create a new row each time (use UPSERT or find-then-return).
- **GET /auth/profile** (and login response `user`) must include **points_balance** and **total_points_earned** from the DB.
- Log the resolved `users.id` in login, signup, and profile so you can confirm it is stable.

**Profile SELECT example:**

```sql
SELECT id, email, username, points_balance, total_points_earned,
       current_streak, last_checkin, total_checkins,
       notification_time, notifications_enabled, is_admin, created_at
FROM public.users
WHERE id = $1;
```

---

## 6. Points transactions table

Create and use this so “Recent activity” and points history are correct:

```sql
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

**When to insert:**

| Event | transaction_type | points_amount | description (example) |
|-------|------------------|---------------|------------------------|
| Check-in | `earned` | 1 or 6 | `Daily check-in day N` |
| Content submission | `earned` | 1 | `Content submission` |
| Unlock content | `spent` | 5 | `Unlocked content` |
| Unlock theme | `spent` | 50 | `Unlocked theme: <name>` (or theme id) |
| Welcome/signup | `earned` | 5 | `Welcome bonus` |

Earned: add to `points_balance` (and optionally `total_points_earned`), then insert. Spent: subtract from `points_balance`, then insert.

---

## 7. Users table (balance columns)

```sql
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS points_balance INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_points_earned INT NOT NULL DEFAULT 0;
```

Use **points_balance** in profile, stats, unlock, check-in, and submit.

---

## 8. Award 1 point on every content submit

On **every** successful **POST /content/submit** (after inserting the content/feed row):

1. **UPDATE users**  
   `SET points_balance = points_balance + 1, total_points_earned = total_points_earned + 1 WHERE id = :user_id`
2. **INSERT into points_transactions**  
   `(user_id, transaction_type, points_amount, description) VALUES (:user_id, 'earned', 1, 'Content submission')`

Use the authenticated submitter’s id for both. Do this every time (no “first time only” logic).

**Parameterized SQL example:**

```sql
UPDATE users
SET points_balance = points_balance + 1,
    total_points_earned = total_points_earned + 1
WHERE id = $1;

INSERT INTO points_transactions (user_id, transaction_type, points_amount, description)
VALUES ($1, 'earned', 1, 'Content submission');
```

---

## 9. Content unlock: 5 points, 1 per category per day

When **POST /content/:id/unlock** runs:

1. Check the content’s **category** (encouragement, inspiration, jokes, facts). Enforce **max 1 unlock per category per user per calendar day** (e.g. count unlocks in `content_unlocks` or equivalent for today + this category + this user). If limit already reached, return `400` with `{ "error": "Daily unlock limit reached for this category", "category": "…" }`.
2. Check `points_balance >= 5`.
3. `UPDATE users SET points_balance = points_balance - 5 WHERE id = :user_id`.
4. `INSERT INTO points_transactions (user_id, transaction_type, points_amount, description) VALUES (:user_id, 'spent', 5, 'Unlocked content');`
5. Mark content as unlocked for that user (and record the category + date for the daily limit).

**Result:** User can unlock at most **4 content items per day** (one per category).

---

## 9b. Theme unlock: 50 points per theme

When **POST /themes/:id/unlock** runs:

1. Check the user has not already unlocked this theme (one-time per theme per user).
2. Check `points_balance >= 50`.
3. `UPDATE users SET points_balance = points_balance - 50 WHERE id = :user_id`.
4. `INSERT INTO points_transactions (user_id, transaction_type, points_amount, description) VALUES (:user_id, 'spent', 50, 'Unlocked theme');` (optionally include theme name in description).
5. Record that this theme is unlocked for this user (e.g. `user_themes` or a `themes_unlocked` table).

---

## 10. Check-in: add reward and record

When **POST /checkin** runs:

1. **Reward:** normal day = **1**; every 5th day (5, 10, 15, …) = **6**.  
   Example: `reward = (new_streak_or_day % 5 == 0) ? 6 : 1`.
2. `UPDATE users SET points_balance = points_balance + :reward, total_points_earned = total_points_earned + :reward, ... WHERE id = :user_id`.
3. `INSERT INTO points_transactions (..., points_amount, description) VALUES (..., :reward, 'Daily check-in day ' || :day);`
4. Return **points_earned** (1 or 6), **total_points**, **new_streak**.

**GET /checkin/info:** Return **next_points** = 1 or 6 (6 when `(total_checkins + 1) % 5 == 0`).

---

## 11. Points history

**GET /users/points-history** must return paginated rows from **points_transactions** for the authenticated user, descending by `created_at`. Response shape is documented in the Endpoints section above.

---

## 12. Summary checklist

| Item | Action |
|------|--------|
| Single balance | Use `points_balance` for profile, stats, unlock, check-in, submit. |
| Submit | **POST /content/submit** → award 1 point + insert `earned` transaction every time. |
| Check-in | 1 pt normal; 6 pts every 5th day. Return `points_earned`, `total_points`. **GET /checkin/info** return `next_points` (1 or 6). |
| Content unlock | 5 pts each; max 1 per category per day (4/day total). Deduct 5; insert `spent` transaction. |
| Theme unlock | 50 pts per theme (one-time). Deduct 50; insert `spent` transaction. |
| Feed | **GET /content/feed** returns all users’ submissions (no filter by current user). Use `content` with `submitted_by IS NOT NULL` or a dedicated `feed_posts` table. |
| Login identity | Same email/provider → same `users.id`; profile includes `points_balance` and `total_points_earned`. |
| Transactions | Insert a row in `points_transactions` on every earn/spend. |
