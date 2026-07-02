-- Attendance Adjustments Table
-- Records all attendance correction requests with approval workflow

CREATE TABLE IF NOT EXISTS attendance_adjustments (
    id SERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id),
    attendance_date DATE NOT NULL,
    adjustment_type VARCHAR(50) NOT NULL CHECK (adjustment_type IN ('ADD_MISSING_PUNCH', 'EDIT_PUNCH', 'DELETE_PUNCH')),
    old_value TEXT,
    new_value TEXT,
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_by INTEGER NOT NULL REFERENCES users(id),
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for querying
CREATE INDEX IF NOT EXISTS idx_attendance_adjustments_employee ON attendance_adjustments(employee_id);
CREATE INDEX IF NOT EXISTS idx_attendance_adjustments_date ON attendance_adjustments(attendance_date);
CREATE INDEX IF NOT EXISTS idx_attendance_adjustments_status ON attendance_adjustments(status);
CREATE INDEX IF NOT EXISTS idx_attendance_adjustments_created_by ON attendance_adjustments(created_by);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_attendance_adjustments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER attendance_adjustments_updated_at_trigger
    BEFORE UPDATE ON attendance_adjustments
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_adjustments_updated_at();

-- Comment
COMMENT ON TABLE attendance_adjustments IS 'Records all attendance correction requests with approval workflow';
