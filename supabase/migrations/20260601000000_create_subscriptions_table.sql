-- Subscriptions: server-side source of truth for premium entitlement.
--
-- Written ONLY by the backend (service role) from two sources:
--   1. RevenueCat webhooks (near-real-time updates)
--   2. a periodic reconcile job that re-reads the RevenueCat REST API to
--      heal any events the webhook missed.
--
-- user_id maps 1:1 to the RevenueCat "App User ID", which the app sets to
-- the Supabase auth user id via Purchases.logIn(). event_at lets us ignore
-- out-of-order webhook deliveries.
CREATE TABLE IF NOT EXISTS public.subscriptions (
  user_id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  product_id TEXT,
  entitlement TEXT,
  expires_at TIMESTAMPTZ,
  event_id TEXT,
  event_at TIMESTAMPTZ,
  raw_event JSONB,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security. The backend uses the service role and bypasses
-- RLS; the read policy below is defence-in-depth for any client access.
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own subscription"
  ON public.subscriptions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Apply a subscription event idempotently and in timestamp order.
-- A newer (or equal) event_at wins; older deliveries are ignored.
CREATE OR REPLACE FUNCTION public.apply_subscription_event(
  p_user_id UUID,
  p_is_active BOOLEAN,
  p_product_id TEXT,
  p_entitlement TEXT,
  p_expires_at TIMESTAMPTZ,
  p_event_id TEXT,
  p_event_at TIMESTAMPTZ,
  p_raw_event JSONB
) RETURNS VOID AS $$
BEGIN
  INSERT INTO public.subscriptions AS s (
    user_id, is_active, product_id, entitlement, expires_at,
    event_id, event_at, raw_event, updated_at
  ) VALUES (
    p_user_id, p_is_active, p_product_id, p_entitlement, p_expires_at,
    p_event_id, p_event_at, p_raw_event, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    is_active = EXCLUDED.is_active,
    product_id = EXCLUDED.product_id,
    entitlement = EXCLUDED.entitlement,
    expires_at = EXCLUDED.expires_at,
    event_id = EXCLUDED.event_id,
    event_at = EXCLUDED.event_at,
    raw_event = EXCLUDED.raw_event,
    updated_at = NOW()
  WHERE s.event_at IS NULL
     OR EXCLUDED.event_at IS NULL
     OR EXCLUDED.event_at >= s.event_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- True when the user currently holds an active, unexpired entitlement.
CREATE OR REPLACE FUNCTION public.is_user_subscribed(p_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT is_active AND (expires_at IS NULL OR expires_at > NOW())
       FROM public.subscriptions
      WHERE user_id = p_user_id),
    FALSE
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER;
