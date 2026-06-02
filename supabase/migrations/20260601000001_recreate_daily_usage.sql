-- Re-introduce daily free-usage tracking, now enforced server-side.
--
-- Originally created in 20251227000000 and dropped in 20260510000002 as
-- unused scaffolding. The backend now reads/writes this from the narration
-- endpoint (service role, bypassing RLS) to enforce the free daily quota.
-- The per-day limit itself lives in application code, not here.
CREATE TABLE IF NOT EXISTS public.daily_usage (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  used_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date
  ON public.daily_usage(user_id, usage_date);

ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;

-- Defence-in-depth read policy; the backend uses the service role.
CREATE POLICY "Users can view their own usage"
  ON public.daily_usage
  FOR SELECT
  USING (auth.uid() = user_id);

-- Shared updated_at trigger helper.
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_daily_usage_updated_at ON public.daily_usage;
CREATE TRIGGER update_daily_usage_updated_at
  BEFORE UPDATE ON public.daily_usage
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Free usages consumed today (0 when no row yet).
CREATE OR REPLACE FUNCTION public.get_daily_used_count(p_user_id UUID)
RETURNS INTEGER AS $$
  SELECT COALESCE(
    (SELECT used_count FROM public.daily_usage
      WHERE user_id = p_user_id AND usage_date = CURRENT_DATE),
    0
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- Atomically increment today's usage and return the new count.
CREATE OR REPLACE FUNCTION public.consume_free_usage(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  INSERT INTO public.daily_usage (user_id, usage_date, used_count)
  VALUES (p_user_id, CURRENT_DATE, 0)
  ON CONFLICT (user_id, usage_date) DO NOTHING;

  UPDATE public.daily_usage
  SET used_count = used_count + 1
  WHERE user_id = p_user_id AND usage_date = CURRENT_DATE
  RETURNING used_count INTO v_new_count;

  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
