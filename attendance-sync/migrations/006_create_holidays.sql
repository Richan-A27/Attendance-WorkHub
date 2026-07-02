-- 006_create_holidays.sql
CREATE TABLE IF NOT EXISTS holidays (
  id SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  holiday_date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'uq_holidays_date'
  ) THEN
    CREATE UNIQUE INDEX uq_holidays_date ON holidays(holiday_date);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname = 'public' AND indexname = 'idx_holidays_date'
  ) THEN
    CREATE INDEX idx_holidays_date ON holidays(holiday_date);
  END IF;
END
$$;
