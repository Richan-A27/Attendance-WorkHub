package payroll

import (
	"time"
)

// PayrollRecord represents payroll information for an employee for a given pay period.
type PayrollRecord struct {
	ID                 uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID         uint64     `gorm:"not null;column:employee_id" json:"employeeId"`
	PayPeriodID        *uint64    `gorm:"column:pay_period_id" json:"payPeriodId"`
	Month              int        `gorm:"not null;column:month" json:"month"`
	Year               int        `gorm:"not null;column:year" json:"year"`
	RegularHours       float64    `gorm:"column:regular_hours;default:0" json:"regularHours"`
	OvertimeHours      float64    `gorm:"column:overtime_hours;default:0" json:"overtimeHours"`
	PaidHours          float64    `gorm:"column:paid_hours;default:0" json:"paidHours"`
	BreakHours         float64    `gorm:"column:break_hours;default:0" json:"breakHours"`
	HourlyRate         float64    `gorm:"not null;column:hourly_rate" json:"hourlyRate"`
	OvertimeMultiplier float64    `gorm:"column:overtime_multiplier;default:1.50" json:"overtimeMultiplier"`
	GrossPay           float64    `gorm:"column:gross_pay;default:0" json:"grossPay"`
	Deductions         float64    `gorm:"column:deductions;default:0" json:"deductions"`
	Bonuses            float64    `gorm:"column:bonuses;default:0" json:"bonuses"`
	NetPay             float64    `gorm:"column:net_pay;default:0" json:"netPay"`
	// Status is simplified to PENDING or PAID.
	Status        string     `gorm:"column:status;default:'PENDING'" json:"status"`
	ProcessedDate *time.Time `gorm:"column:processed_date" json:"processedDate"`
	CreatedAt     time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt     time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "payroll_records".
func (PayrollRecord) TableName() string {
	return "payroll_records"
}

// PayrollSummary aggregates payroll calculations for a month or pay period.
type PayrollSummary struct {
	Month              int     `json:"month,omitempty"`
	Year               int     `json:"year,omitempty"`
	PayPeriodID        *uint64 `json:"payPeriodId,omitempty"`
	TotalEmployees     int     `json:"totalEmployees"`
	TotalGrossPay      float64 `json:"totalGrossPay"`
	TotalNetPay        float64 `json:"totalNetPay"`
	TotalDeductions    float64 `json:"totalDeductions"`
	TotalOvertimeHours float64 `json:"totalOvertimeHours"`
	TotalPaidHours     float64 `json:"totalPaidHours"`
}

// GeneratePayrollRequest is the request body for generating payroll for a pay period.
// CalculationMode applies globally; Overrides allow per-employee exceptions.
type GeneratePayrollRequest struct {
	PayPeriodID     uint64                 `json:"payPeriodId" binding:"required"`
	CalculationMode string                 `json:"calculationMode"` // INCLUDE_BREAKS | EXCLUDE_BREAKS
	Overrides       []EmployeeModeOverride `json:"overrides"`
}

// EmployeeModeOverride allows specifying a different calculation mode for a specific employee.
type EmployeeModeOverride struct {
	EmployeeID      uint64 `json:"employeeId"`
	CalculationMode string `json:"calculationMode"` // INCLUDE_BREAKS | EXCLUDE_BREAKS
}

// PayrollPreview contains the computed payroll preview for both modes for a single employee.
// This is a read-only structure — no DB writes occur during preview.
type PayrollPreview struct {
	EmployeeID    uint64  `json:"employeeId"`
	EmployeeName  string  `json:"employeeName"`
	HourlyRate    float64 `json:"hourlyRate"`
	TotalHours    float64 `json:"totalHours"`    // from total_minutes (first–last punch span)
	WorkingHours  float64 `json:"workingHours"`  // from total_working_minutes (session durations)
	BreakHours    float64 `json:"breakHours"`
	OvertimeHours float64 `json:"overtimeHours"`
	// Mode A — INCLUDE_BREAKS: Paid Hours = Total Hours
	PaidHoursA float64 `json:"paidHoursA"`
	GrossPayA  float64 `json:"grossPayA"`
	// Mode B — EXCLUDE_BREAKS: Paid Hours = Working Hours
	PaidHoursB float64 `json:"paidHoursB"`
	GrossPayB  float64 `json:"grossPayB"`
	// Difference between Mode A and Mode B gross pay
	Difference float64 `json:"difference"`
}

const (
	ModeIncludeBreaks = "INCLUDE_BREAKS"
	ModeExcludeBreaks = "EXCLUDE_BREAKS"

	StatusPending = "PENDING"
	StatusPaid    = "PAID"
)
