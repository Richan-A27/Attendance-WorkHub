package holiday

import (
	"time"
)

// Holiday represents a holiday mapping to the "holidays" table.
type Holiday struct {
	ID          uint64    `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	Name        string    `gorm:"not null;column:name" json:"name"`
	HolidayDate string    `gorm:"not null;column:holiday_date;type:date" json:"holidayDate"`
	IsRecurring bool      `gorm:"column:is_recurring;default:false" json:"isRecurring"`
	CreatedAt   time.Time `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
}

// TableName overrides GORM's default naming behavior to "holidays".
func (Holiday) TableName() string {
	return "holidays"
}
