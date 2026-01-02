-- Add DELETE policy for daily_usage to allow users to delete their own data
-- This is required for E2E tests to clean up data and for general user data management

CREATE POLICY "Users can delete their own usage"
  ON public.daily_usage
  FOR DELETE
  USING (auth.uid() = user_id);
