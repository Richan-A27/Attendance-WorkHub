package sync

import (
	"time"
)

// SyncQueue represents local database records queued for cloud sync.
type SyncQueue struct {
	ID           uint64    `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	SyncTable    string    `gorm:"not null;column:table_name" json:"tableName"`
	RecordID     string    `gorm:"not null;column:record_id" json:"recordId"`
	Action       string    `gorm:"not null;column:action" json:"action"`
	Status       string    `gorm:"not null;column:status;default:'PENDING'" json:"status"`
	ErrorMessage string    `gorm:"column:error_message" json:"errorMessage"`
	CreatedAt    time.Time `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt    time.Time `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "sync_queue".
func (SyncQueue) TableName() string {
	return "sync_queue"
}
