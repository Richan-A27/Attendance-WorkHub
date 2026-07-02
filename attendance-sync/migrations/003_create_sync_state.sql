-- 003_create_sync_state.sql
CREATE TABLE IF NOT EXISTS sync_state (
  id INTEGER PRIMARY KEY,
  last_sync_time TIMESTAMP WITHOUT TIME ZONE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'sync_state_pk'
  ) THEN
    -- primary key already created by the table definition above
    NULL;
  END IF;
END
$$;
