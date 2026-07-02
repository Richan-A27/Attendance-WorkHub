-- 007_create_attendance_sessions.sql
CREATE TABLE IF NOT EXISTS attendance_sessions (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  session_number INTEGER NOT NULL,
  punch_in TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  punch_out TIMESTAMP WITHOUT TIME ZONE,
  duration_minutes INTEGER,
  is_lunch_break BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_attendance_sessions_employee_date'
  ) THEN
    CREATE INDEX idx_attendance_sessions_employee_date ON attendance_sessions(employee_id, session_date);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_attendance_sessions_date'
  ) THEN
    CREATE INDEX idx_attendance_sessions_date ON attendance_sessions(session_date);
  END IF;
END
$$;
