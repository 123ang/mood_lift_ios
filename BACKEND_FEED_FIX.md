# Backend fix: GET /content/feed — return rows from public.content

**Problem:** GET /content/feed returns empty data; GET /content/encouragement returns 16 rows from `public.content`.  
**DB truth:** `SELECT COUNT(*) FROM public.content WHERE status='active' AND submitted_by IS NOT NULL` returns > 0.  
**Cause:** Feed endpoint SQL/filter or DB connection is wrong.

---

## Task list

1. Find the **GET /content/feed** route handler in the backend.
2. Print/log which **DB client/pool** it uses (must be the **same** as `/content/encouragement`).
3. Replace its SQL with the queries below.
4. Ensure **NO** filter by current user id.
5. Add debug logs: SQL string, params `[limit, offset]`, `rows.length`.
6. Restart backend and re-test: `GET /content/feed?page=1&limit=5`.
7. Return JSON: `{ data, total, page, total_pages }`.

---

## 1. Locate GET /content/feed

In your backend codebase, find the handler for:

- **Path:** `GET /content/feed` (or `GET /api/content/feed`)
- **Typical places:** `routes/content.js`, `controllers/contentController.js`, `app.get('/content/feed', ...)`, or similar.

---

## 2. Log which DB client/pool the feed uses

Ensure the feed route uses the **same** DB client/pool as the route that serves **GET /content/encouragement** (so both hit `public.content`).

```js
// Example: log which client/pool the feed handler uses
console.log('[FEED] DB client/pool:', typeof db); // or pool, client, knex, etc.
// Compare with the handler for GET /content/encouragement — they must be the same.
```

---

## 3. Replace feed SQL with this

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

**Params:**

- `$1` = **limit** (from query param `limit`, e.g. 5 or 20; default 20)
- `$2` = **offset** = `(page - 1) * limit` (from query param `page`, default 1)

**Count query (for `total` and `total_pages`):**

```sql
SELECT COUNT(*) FROM public.content
WHERE status = 'active' AND submitted_by IS NOT NULL;
```

Use the count result as `total`. Then: `total_pages = Math.ceil(total / limit)` (or equivalent).

---

## 4. No filter by current user

- **Do not** add `WHERE submitted_by = $current_user_id` (or any filter by `req.user.id` / token user).
- The feed must return **all** rows that match `status = 'active' AND submitted_by IS NOT NULL`.

---

## 5. Debug logs to add

Before/after running the query, log:

```js
// Before query
const limit = parseInt(req.query.limit, 10) || 20;
const page = Math.max(1, parseInt(req.query.page, 10) || 1);
const offset = (page - 1) * limit;
console.log('[FEED] SQL string:', feedDataQuery); // the SELECT above
console.log('[FEED] params [limit, offset]:', [limit, offset]);

// After query (result.rows or your ORM equivalent)
const rows = result.rows;
console.log('[FEED] rows.length:', rows.length);
```

Optional: log a sample of `submitted_by` to confirm multiple users:

```js
console.log('[FEED] sample submitted_by:', rows.slice(0, 5).map(r => r.submitted_by));
```

---

## 6. Response shape

Return JSON in this exact shape:

```json
{
  "data": [ /* array of content rows from the SELECT */ ],
  "total": 123,
  "page": 1,
  "total_pages": 7
}
```

- **data** — array of rows from the data query.
- **total** — single number from the count query.
- **page** — request `page` (default 1).
- **total_pages** — `ceil(total / limit)`.

---

## 7. After changing

1. Restart the backend.
2. Re-test: `GET /content/feed?page=1&limit=5`.
3. Check logs for: SQL string, params `[limit, offset]`, `rows.length` (should be > 0 if DB has rows).
4. Response should have `data.length > 0` and `total > 0` when there is content in `public.content` with `status='active'` and `submitted_by IS NOT NULL`.

---

## Quick checklist

| # | Task |
|---|------|
| 1 | Find GET /content/feed route handler. |
| 2 | Log which DB client/pool it uses (same as /content/encouragement). |
| 3 | Replace SQL with the SELECT above (`WHERE status='active' AND submitted_by IS NOT NULL`). |
| 4 | Use the count SQL for `total`; set `total_pages` = ceil(total / limit). |
| 5 | Ensure NO filter by current user id. |
| 6 | Add debug logs: SQL string, params [limit, offset], rows.length. |
| 7 | Restart backend; re-test GET /content/feed?page=1&limit=5; return { data, total, page, total_pages }. |
