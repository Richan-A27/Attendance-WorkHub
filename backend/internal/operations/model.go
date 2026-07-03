package operations

import (
	"time"
)

// SyncHistory represents a run of the biometric synchronization subprocess.
type SyncHistory struct {
	ID               uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	SyncStartTime    time.Time  `gorm:"not null;column:sync_start_time" json:"syncStartTime"`
	SyncEndTime      *time.Time `gorm:"column:sync_end_time" json:"syncEndTime"`
	Status           string     `gorm:"not null;column:status" json:"status"` // SUCCESS, FAILURE, IN_PROGRESS
	RecordsProcessed int        `gorm:"column:records_processed;default:0" json:"recordsProcessed"`
	ErrorMessage     string     `gorm:"column:error_message" json:"errorMessage"`
	CreatedAt        time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
}

// TableName overrides GORM's default naming behavior to "sync_history".
func (SyncHistory) TableName() string {
	return "sync_history"
}
