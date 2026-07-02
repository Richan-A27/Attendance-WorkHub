-- 008_create_daily_attendance.sql
CREATE TABLE IF NOT EXISTS daily_attendance (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  attendance_date DATE NOT NULL,
  first_punch TIMESTAMP WITHOUT TIME ZONE,
  last_punch TIMESTAMP WITHOUT TIME ZONE,
  total_working_minutes INTEGER DEFAULT 0,
  break_duration_minutes INTEGER DEFAULT 0,
  lunch_duration_minutes INTEGER DEFAULT 0,
  status VARCHAR DEFAULT 'ABSENT',
  is_late BOOLEAN DEFAULT FALSE,
  late_minutes INTEGER DEFAULT 0,
  is_early_departure BOOLEAN DEFAULT FALSE,
  early_departure_minutes INTEGER DEFAULT 0,
  overtime_minutes INTEGER DEFAULT 0,
  scheduled_work_minutes INTEGER DEFAULT 0,
  work_schedule_id INTEGER REFERENCES work_schedules(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'uq_daily_attendance_employee_date'
  ) THEN
    CREATE UNIQUE INDEX uq_daily_attendance_employee_date ON daily_attendance(employee_id, attendance_date);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_daily_attendance_date'
  ) THEN
    CREATE INDEX idx_daily_attendance_date ON daily_attendance(attendance_date);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_daily_attendance_status'
  ) THEN
    CREATE INDEX idx_daily_attendance_status ON daily_attendance(status);
  END IF;
END
$$;
