package attendance

import (
	"time"
)

// AttendanceLog represents a raw biometric scan punch log.
type AttendanceLog struct {
	ID         uint64    `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID uint64    `gorm:"not null;column:employee_id" json:"employeeId"`
	PunchTime  time.Time `gorm:"not null;column:punch_time" json:"punchTime"`
	VerifyMode int       `gorm:"column:verify_mode" json:"verifyMode"`
	Status     int       `gorm:"column:status" json:"status"`
	CreatedAt  time.Time `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
}

// TableName overrides GORM's default naming behavior to "attendance_logs".
func (AttendanceLog) TableName() string {
	return "attendance_logs"
}

// AttendanceAdjustment represents administrative manual edits of punch records.
type AttendanceAdjustment struct {
	ID             uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID     uint64     `gorm:"not null;column:employee_id" json:"employeeId"`
	AttendanceDate string     `gorm:"not null;column:attendance_date;type:date" json:"attendanceDate"`
	AdjustmentType string     `gorm:"not null;column:adjustment_type" json:"adjustmentType"`
	OldValue       string     `gorm:"column:old_value;type:text" json:"oldValue"`
	NewValue       string     `gorm:"column:new_value;type:text" json:"newValue"`
	Reason         string     `gorm:"not null;column:reason;type:text" json:"reason"`
	Status         string     `gorm:"not null;column:status;default:'PENDING'" json:"status"`
	CreatedBy      uint64     `gorm:"not null;column:created_by" json:"createdBy"`
	ApprovedBy     *uint64    `gorm:"column:approved_by" json:"approvedBy"`
	ApprovedAt     *time.Time `gorm:"column:approved_at" json:"approvedAt"`
	CreatedAt      time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt      time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "attendance_adjustments".
func (AttendanceAdjustment) TableName() string {
	return "attendance_adjustments"
}
