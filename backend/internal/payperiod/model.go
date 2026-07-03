package payperiod

import "time"

// PayPeriod represents a configurable payroll period (e.g. a week or custom date range).
type PayPeriod struct {
	ID        uint64    `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	Name      string    `gorm:"not null;column:name" json:"name"`
	StartDate string    `gorm:"not null;column:start_date;type:date" json:"startDate"`
	EndDate   string    `gorm:"not null;column:end_date;type:date" json:"endDate"`
	Status    string    `gorm:"column:status;default:'OPEN'" json:"status"`
	CreatedAt time.Time `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt time.Time `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "pay_periods".
func (PayPeriod) TableName() string {
	return "pay_periods"
}

// Valid status transitions: OPEN → PROCESSING → FINALIZED → PAID
const (
	StatusOpen       = "OPEN"
	StatusProcessing = "PROCESSING"
	StatusFinalized  = "FINALIZED"
	StatusPaid       = "PAID"
)
