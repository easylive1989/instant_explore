-- Daily usage tracking table
-- Stores the number of free AI guides used per day
-- Note: daily_limit is managed in application code, not in database
CREATE TABLE IF NOT EXISTS public.daily_usage (
  id UUID NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  usage_date DATE NOT NULL DEFAULT CURRENT_DATE,
  used_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, usage_date)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_daily_usage_user_date ON public.daily_usage(user_id, usage_date);

-- Enable Row Level Security
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;

-- RLS Policies for daily_usage
CREATE POLICY "Users can view their own usage"
  ON public.daily_usage
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own usage"
  ON public.daily_usage
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own usage"
  ON public.daily_usage
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_daily_usage_updated_at ON public.daily_usage;
CREATE TRIGGER update_daily_usage_updated_at
  BEFORE UPDATE ON public.daily_usage
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- Function to get used count for today
-- Returns the number of free usages consumed today
CREATE OR REPLACE FUNCTION public.get_daily_used_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_used_count INTEGER;
BEGIN
  SELECT used_count INTO v_used_count
  FROM public.daily_usage
  WHERE user_id = p_user_id
    AND usage_date = CURRENT_DATE;

  RETURN COALESCE(v_used_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to consume free usage
-- Increments usage count and returns the new count
-- Application should check against daily limit
CREATE OR REPLACE FUNCTION public.consume_free_usage(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  -- Get or create today's usage record
  INSERT INTO public.daily_usage (user_id, usage_date, used_count)
  VALUES (p_user_id, CURRENT_DATE, 0)
  ON CONFLICT (user_id, usage_date) DO NOTHING;

  -- Increment usage and return new count
  UPDATE public.daily_usage
  SET used_count = used_count + 1
  WHERE user_id = p_user_id
    AND usage_date = CURRENT_DATE
  RETURNING used_count INTO v_new_count;

  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
