-- 009_create_payroll_records.sql
CREATE TABLE IF NOT EXISTS payroll_records (
  id BIGSERIAL PRIMARY KEY,
  employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  month INTEGER NOT NULL,
  year INTEGER NOT NULL,
  regular_hours NUMERIC(10,2) DEFAULT 0.00,
  overtime_hours NUMERIC(10,2) DEFAULT 0.00,
  hourly_rate NUMERIC(10,2) NOT NULL,
  overtime_multiplier NUMERIC(5,2) DEFAULT 1.50,
  gross_pay NUMERIC(12,2) DEFAULT 0.00,
  deductions NUMERIC(12,2) DEFAULT 0.00,
  bonuses NUMERIC(12,2) DEFAULT 0.00,
  net_pay NUMERIC(12,2) DEFAULT 0.00,
  status VARCHAR DEFAULT 'PENDING',
  processed_date TIMESTAMP WITHOUT TIME ZONE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'uq_payroll_employee_month_year'
  ) THEN
    CREATE UNIQUE INDEX uq_payroll_employee_month_year ON payroll_records(employee_id, month, year);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_payroll_month_year'
  ) THEN
    CREATE INDEX idx_payroll_month_year ON payroll_records(month, year);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_payroll_status'
  ) THEN
    CREATE INDEX idx_payroll_status ON payroll_records(status);
  END IF;
END
$$;
