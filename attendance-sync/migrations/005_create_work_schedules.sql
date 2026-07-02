-- 005_create_work_schedules.sql
CREATE TABLE IF NOT EXISTS work_schedules (
  id SERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  lunch_duration_minutes INTEGER DEFAULT 45,
  grace_period_minutes INTEGER DEFAULT 10,
  work_days VARCHAR[] DEFAULT ARRAY['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY'],
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_work_schedules_employee_id'
  ) THEN
    CREATE INDEX idx_work_schedules_employee_id ON work_schedules(employee_id);
  END IF;
END
$$;
