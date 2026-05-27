// Contract test: every column the App embeds via
// `daily_story_places!left(...)` in SupabaseDailyStoryRepository MUST also
// be granted SELECT to anon/authenticated by a Supabase migration.
//
// This is the test that would have caught the PostgrestException 42501
// regression on the history-story screen, where the repository embed
// referenced columns on a table that had no client-side SELECT grant.
//
// The test reads the repository source and the migration SQL files
// directly, so it has no Flutter, no Supabase, and no network dependency.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _repoSourcePath =
    'lib/features/daily_story/data/supabase_daily_story_repository.dart';
const _migrationsDir = '../supabase/migrations';

void main() {
  group('daily_story_places client access contract', () {
    test(
      'given the repository embeds daily_story_places columns, '
      'when checking Supabase grants, '
      'then every embedded column is granted SELECT to anon/authenticated',
      () {
        final embeddedColumns = _extractEmbeddedColumns(
          File(_repoSourcePath).readAsStringSync(),
        );
        expect(
          embeddedColumns,
          isNotEmpty,
          reason:
              'Failed to parse `daily_story_places!left(...)` in '
              '$_repoSourcePath — has the embed syntax changed?',
        );

        final grantedColumns = _extractGrantedColumns(_collectMigrationSql());
        expect(
          grantedColumns,
          isNotEmpty,
          reason:
              'No `grant select (...) on table public.daily_story_places '
              'to anon, authenticated` found in supabase/migrations/.',
        );

        final ungranted = embeddedColumns.difference(grantedColumns);
        expect(
          ungranted,
          isEmpty,
          reason:
              'Columns embedded by the repository but NOT granted to '
              'anon/authenticated: $ungranted. PostgREST will reject the '
              'join with 42501. Either add the columns to the GRANT or '
              'remove them from the embed.',
        );
      },
    );
  });
}

/// Extracts the comma-separated column list from an embed like
/// `daily_story_places!left(col1, col2, col3)` in the given Dart source.
Set<String> _extractEmbeddedColumns(String source) {
  final match = RegExp(
    r'daily_story_places!left\(([^)]*)\)',
  ).firstMatch(source);
  if (match == null) return <String>{};
  return match
      .group(1)!
      .split(',')
      .map((c) => c.trim())
      .where((c) => c.isNotEmpty)
      .toSet();
}

/// Walks `supabase/migrations/` and collects every `grant select (...)
/// on table public.daily_story_places to ... anon ... authenticated ...`
/// column list. Tolerates either order of anon/authenticated and
/// either single- or multi-line GRANT statements.
Set<String> _extractGrantedColumns(String allMigrationSql) {
  final grants = RegExp(
    r'grant\s+select\s*\(([^)]+)\)\s+on\s+table\s+public\.daily_story_places'
    r'\s+to\s+([^;]+);',
    caseSensitive: false,
  ).allMatches(allMigrationSql);

  final granted = <String>{};
  for (final match in grants) {
    final roles = match
        .group(2)!
        .split(',')
        .map((r) => r.trim().toLowerCase())
        .toSet();
    final coversAnon = roles.contains('anon');
    final coversAuth = roles.contains('authenticated');
    if (!coversAnon || !coversAuth) continue;
    granted.addAll(
      match
          .group(1)!
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty),
    );
  }
  return granted;
}

String _collectMigrationSql() {
  final dir = Directory(_migrationsDir);
  if (!dir.existsSync()) {
    fail('Migrations directory not found at $_migrationsDir');
  }
  final buffer = StringBuffer();
  for (final entity in dir.listSync()) {
    if (entity is File && entity.path.endsWith('.sql')) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}
