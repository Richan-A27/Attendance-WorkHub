CREATE TABLE IF NOT EXISTS attendance_breaks (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,
    break_number INT NOT NULL,
    break_start TIMESTAMP NOT NULL,
    break_end TIMESTAMP NOT NULL,
    duration_minutes INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
