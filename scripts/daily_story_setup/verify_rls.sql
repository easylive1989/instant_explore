-- Verify RLS on daily_story_places + daily_stories
-- Run with: psql <CONN_STR> -v ON_ERROR_STOP=1 -f verify_rls.sql

\echo '=== Setup: insert one place + two daily_stories rows ==='

-- service role can write
insert into public.daily_story_places (id, name, wikipedia_title_en, country)
values ('11111111-1111-1111-1111-111111111111', 'Test Place', 'Test_Place', 'Testland')
on conflict (id) do nothing;

insert into public.daily_stories
  (publish_date, language, place_id, place_name, place_location, era,
   story, wikipedia_url)
values
  -- past story: should be visible to anon
  (current_date - 1, 'en',
   '11111111-1111-1111-1111-111111111111',
   'Test', 'Testland', '1000 BCE',
   'Test story past',
   'https://en.wikipedia.org/wiki/Test_Place'),
  -- future story: should NOT be visible to anon
  (current_date + 1, 'en',
   '11111111-1111-1111-1111-111111111111',
   'Test future', 'Testland', '2000 CE',
   'Test story future',
   'https://en.wikipedia.org/wiki/Test_Place')
on conflict (publish_date, language) do nothing;

\echo '=== Test 1: anon should see ONLY published (past) stories ==='
set role anon;
select count(*) as visible_to_anon from public.daily_stories;
-- Expected: 1 (only the past story)

\echo '=== Test 2: anon CANNOT insert into daily_stories ==='
do $$
begin
  begin
    insert into public.daily_stories
      (publish_date, language, place_id, place_name, place_location, era,
       story, wikipedia_url)
    values (current_date, 'en',
            '11111111-1111-1111-1111-111111111111',
            'X', 'X', 'X', 'X',
            'https://example.com');
    raise exception 'FAIL: anon insert should have been blocked';
  exception
    when insufficient_privilege or others then
      raise notice 'PASS: anon insert blocked';
  end;
end $$;

\echo '=== Test 3: anon CANNOT read daily_story_places ==='
select count(*) as places_visible_to_anon from public.daily_story_places;
-- Expected: 0 (no policy = denied)

\echo '=== Cleanup ==='
reset role;
delete from public.daily_stories
  where place_id = '11111111-1111-1111-1111-111111111111';
delete from public.daily_story_places
  where id = '11111111-1111-1111-1111-111111111111';

\echo '=== ALL CHECKS DONE ==='
