-- 010_create_sync_queue.sql

-- 1. Create the sync queue table
CREATE TABLE IF NOT EXISTS sync_queue (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR NOT NULL,
    record_id VARCHAR NOT NULL,
    action VARCHAR NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    status VARCHAR DEFAULT 'PENDING', -- 'PENDING', 'PROCESSING', 'SYNCED', 'FAILED'
    error_message TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- 2. Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. Create generic enqueue_sync_event trigger function
CREATE OR REPLACE FUNCTION enqueue_sync_event()
RETURNS TRIGGER AS $$
DECLARE
    record_id_val VARCHAR;
BEGIN
    IF (TG_OP = 'DELETE') THEN
        record_id_val := OLD.id::VARCHAR;
    ELSE
        record_id_val := NEW.id::VARCHAR;
    END IF;

    INSERT INTO sync_queue (table_name, record_id, action, status, created_at, updated_at)
    VALUES (TG_TABLE_NAME, record_id_val, TG_OP, 'PENDING', now(), now());

    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. Add updated_at to all necessary tables if not exists
DO $$ 
DECLARE
    t_name text;
BEGIN
    FOR t_name IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('employees', 'attendance_logs', 'attendance_sessions', 'daily_attendance', 'payroll_records', 'work_schedules', 'holidays', 'attendance_adjustments', 'users')
    LOOP
        EXECUTE format('ALTER TABLE %I ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now();', t_name);
        
        -- Drop trigger if exists to recreate it cleanly
        EXECUTE format('DROP TRIGGER IF EXISTS set_updated_at ON %I;', t_name);
        EXECUTE format('CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();', t_name);
        
        -- Drop sync trigger if exists
        EXECUTE format('DROP TRIGGER IF EXISTS trg_enqueue_sync ON %I;', t_name);
        EXECUTE format('CREATE TRIGGER trg_enqueue_sync AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION enqueue_sync_event();', t_name);
    END LOOP;
END $$;
