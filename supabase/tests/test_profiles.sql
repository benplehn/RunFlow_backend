SELECT plan(10);

-- Diags et vérif contextuelles (ne comptent pas dans le plan)
SELECT diag('Current user=' || current_user);
SELECT diag('Search path=' || current_setting('search_path'));
SELECT diag('Tables=' || (SELECT string_agg(table_name, ',') FROM information_schema.tables WHERE table_schema='public'));
SELECT diag('Table details=' || (SELECT string_agg(tableowner || ':' || schemaname, ',') FROM pg_tables WHERE tablename = 'profiles'));
SELECT diag('Columns=' || (SELECT string_agg(column_name || ':' || data_type, ',') FROM information_schema.columns WHERE table_schema='public' AND table_name='profiles'));

-- Les vrais tests (qui comptent dans le plan)
SELECT has_table('public', 'profiles');
SELECT has_column('public', 'profiles', 'id');
SELECT has_column('public', 'profiles', 'username');
SELECT has_column('public', 'profiles', 'avatar_url');
SELECT has_column('public', 'profiles', 'preferences');
SELECT has_column('public', 'profiles', 'created_at');
SELECT has_column('public', 'profiles', 'updated_at');
SELECT col_is_unique('public', 'profiles', 'username');
SELECT col_is_pk('public', 'profiles', 'id');
SELECT col_type_is('public', 'profiles', 'preferences', 'jsonb');
