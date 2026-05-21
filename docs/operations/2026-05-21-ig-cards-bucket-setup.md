# Create the `ig-cards` Supabase Storage bucket (Phase 3)

The Phase 3 publisher uploads each rendered IG card PNG to a public Supabase
Storage bucket named `ig-cards`. Meta's Graph API fetches that public URL
when publishing the IG post, so the bucket must be readable anonymously.

This step is **one-time per environment** (local dev + prod). Re-run only
if the bucket is deleted.

## 1. Create the bucket in Supabase Dashboard

1. Open https://supabase.com/dashboard and pick the project.
2. In the left nav choose **Storage**.
3. Click **New bucket**.
4. Fill in:
   - **Name**: `ig-cards`
   - **Public bucket**: ✅ **enabled** (Meta servers fetch anonymously)
   - **File size limit**: `5 MB`
   - **Allowed MIME types**: `image/png`
5. Click **Create bucket**.

## 2. Verify the bucket is public

1. Click into the new `ig-cards` bucket.
2. Open the **Configuration** tab and confirm `Public` is on.
3. Upload any small placeholder PNG via the dashboard, click it, choose
   **Get URL**, and open the URL in an incognito browser. It must load
   without authentication. Delete the placeholder afterwards.

## 3. (Optional) Restrict writes to the service role

By default, Supabase Storage buckets allow inserts by service_role only,
so no policy changes are strictly required. If you want to make this
explicit, add a policy under **Policies → ig-cards**:

```sql
create policy "service_role can manage ig-cards"
on storage.objects for all
to service_role
using (bucket_id = 'ig-cards')
with check (bucket_id = 'ig-cards');
```

## 4. Smoke-test from the backend

After Phase 3 deploys, the first 21:00 publisher run for a row whose
zh-TW + place fields are populated will create
`ig-cards/<publish_date>/<zh_row_id>.png`. Confirm via:

```bash
supabase db psql -c "select id, ig_post_id, publish_error \
  from public.daily_stories \
  where publish_date = '<YYYY-MM-DD>' and language = 'en' and review_state = 'published';"
```

A successful card publish has `ig_post_id` set and `publish_error` null.
A row where the publisher gracefully skipped IG (Phase 2 backfill
incomplete) has `ig_post_id` null and
`publish_error = 'ig_skipped_missing_card_content'`.
