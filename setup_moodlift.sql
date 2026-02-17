-- ============================================================
-- MoodLift: paste this into QuerySQL (PostgreSQL)
-- Run in order. Safe to re-run (IF NOT EXISTS / IF NOT EXISTS).
-- ============================================================

-- 1. Users: ensure points columns exist (single spendable balance)
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS points_balance INT NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_points_earned INT NOT NULL DEFAULT 0;

-- 2. Points transactions (for Recent activity / points history)
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

-- 3. Feed posts (user submissions for Feeds tab only; do NOT use for admin content)
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

-- Done. Next steps in your backend:
-- - POST /content/submit  → INSERT into feed_posts, then add 1 to user points_balance + insert into points_transactions
-- - GET /content/feed     → SELECT from feed_posts ORDER BY created_at DESC
