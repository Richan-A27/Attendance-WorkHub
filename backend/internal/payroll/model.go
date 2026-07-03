package payroll

import (
	"time"
)

// PayrollRecord represents monthly payroll information for an employee.
type PayrollRecord struct {
	ID                 uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID         uint64     `gorm:"not null;column:employee_id" json:"employeeId"`
	Month              int        `gorm:"not null;column:month" json:"month"`
	Year               int        `gorm:"not null;column:year" json:"year"`
	RegularHours       float64    `gorm:"column:regular_hours;default:0" json:"regularHours"`
	OvertimeHours      float64    `gorm:"column:overtime_hours;default:0" json:"overtimeHours"`
	HourlyRate         float64    `gorm:"not null;column:hourly_rate" json:"hourlyRate"`
	OvertimeMultiplier float64    `gorm:"column:overtime_multiplier;default:1.50" json:"overtimeMultiplier"`
	GrossPay           float64    `gorm:"column:gross_pay;default:0" json:"grossPay"`
	Deductions         float64    `gorm:"column:deductions;default:0" json:"deductions"`
	Bonuses            float64    `gorm:"column:bonuses;default:0" json:"bonuses"`
	NetPay             float64    `gorm:"column:net_pay;default:0" json:"netPay"`
	Status             string     `gorm:"column:status;default:'PENDING'" json:"status"`
	ProcessedDate      *time.Time `gorm:"column:processed_date" json:"processedDate"`
	CreatedAt          time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt          time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "payroll_records".
func (PayrollRecord) TableName() string {
	return "payroll_records"
}

// PayrollSummary aggregates payroll calculations for a month.
type PayrollSummary struct {
	Month              int     `json:"month"`
	Year               int     `json:"year"`
	TotalEmployees     int     `json:"totalEmployees"`
	TotalGrossPay      float64 `json:"totalGrossPay"`
	TotalNetPay        float64 `json:"totalNetPay"`
	TotalDeductions    float64 `json:"totalDeductions"`
	TotalOvertimeHours float64 `json:"totalOvertimeHours"`
}
