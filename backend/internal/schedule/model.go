package schedule

import (
	"time"
	"github.com/lib/pq"
)

// WorkSchedule represents an employee work schedule.
type WorkSchedule struct {
	ID                   uint64         `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID           uint64         `gorm:"not null;column:employee_id" json:"employeeId"`
	StartTime            string         `gorm:"not null;column:start_time;type:time" json:"startTime"`
	EndTime              string         `gorm:"not null;column:end_time;type:time" json:"endTime"`
	LunchDurationMinutes int            `gorm:"column:lunch_duration_minutes;default:45" json:"lunchDurationMinutes"`
	GracePeriodMinutes   int            `gorm:"column:grace_period_minutes;default:10" json:"gracePeriodMinutes"`
	WorkDays             pq.StringArray `gorm:"column:work_days;type:varchar[]" json:"workDays"`
	Active               bool           `gorm:"column:active;default:true" json:"active"`
	CreatedAt            time.Time      `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt            time.Time      `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "work_schedules".
func (WorkSchedule) TableName() string {
	return "work_schedules"
}
