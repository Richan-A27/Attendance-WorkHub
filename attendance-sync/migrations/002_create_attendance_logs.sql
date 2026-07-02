-- 002_create_attendance_logs.sql
CREATE TABLE IF NOT EXISTS attendance_logs (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL,
  punch_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  verify_mode VARCHAR,
  status VARCHAR,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'uq_attendance_log'
  ) THEN
    CREATE UNIQUE INDEX uq_attendance_log ON attendance_logs(employee_id, punch_time);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_attendance_punch_time'
  ) THEN
    CREATE INDEX idx_attendance_punch_time ON attendance_logs(punch_time);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_attendance_employee_id'
  ) THEN
    CREATE INDEX idx_attendance_employee_id ON attendance_logs(employee_id);
  END IF;
END
$$;
