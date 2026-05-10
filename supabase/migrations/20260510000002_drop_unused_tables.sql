-- Drop unused tables, RPCs, and trigger helper.
--
-- passport_entries: legacy "knowledge passport" feature, superseded by the
-- journey feature. No production code reads or writes this table; the only
-- caller was an integration-test cleanup helper, removed in the same change.
--
-- daily_usage + consume_free_usage / get_daily_used_count: subscription
-- usage-tracking scaffolding that was never wired up from the frontend or
-- backend. Dropping keeps the schema honest. If subscription limits return,
-- we re-introduce these deliberately.
--
-- update_updated_at_column: only consumer was daily_usage's updated_at
-- trigger, which is removed by the CASCADE below.

-- passport_entries: CASCADE removes the table's RLS policies.
drop table if exists public.passport_entries cascade;

-- daily_usage helpers must be dropped before / alongside the table.
drop function if exists public.consume_free_usage(uuid);
drop function if exists public.get_daily_used_count(uuid);

-- daily_usage: CASCADE removes the updated_at trigger and RLS policies.
drop table if exists public.daily_usage cascade;

-- Now-orphan trigger helper.
drop function if exists public.update_updated_at_column();
