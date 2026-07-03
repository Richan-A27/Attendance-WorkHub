package employee

import (
	"time"
)

// Employee represents the employee model mapping to the "employees" table.
type Employee struct {
	ID             uint64     `gorm:"primaryKey;column:id" json:"id"`
	Name           string     `gorm:"not null;column:name" json:"name"`
	HourlyRate     float64    `gorm:"column:hourly_rate" json:"hourlyRate"`
	Department     string     `gorm:"column:department" json:"department"`
	Designation    string     `gorm:"column:designation" json:"designation"`
	EmploymentType string     `gorm:"column:employment_type" json:"employmentType"`
	Active         bool       `gorm:"column:active" json:"active"`
	LastSynced     *time.Time `gorm:"column:last_synced" json:"lastSynced"`
	CreatedAt      time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt      *time.Time `gorm:"column:updated_at" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "employees".
func (Employee) TableName() string {
	return "employees"
}
