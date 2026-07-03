package device

import (
	"context"
	"gorm.io/gorm"
)

// Repository handles CRUD queries for device sync status.
type Repository interface {
	FindFirstByOrderByLastSyncDesc(ctx context.Context) (*DeviceSyncStatus, error)
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindFirstByOrderByLastSyncDesc(ctx context.Context) (*DeviceSyncStatus, error) {
	var status DeviceSyncStatus
	err := r.db.WithContext(ctx).
		Order("last_sync DESC").
		First(&status).Error
	if err != nil {
		return nil, err
	}
	return &status, nil
}
