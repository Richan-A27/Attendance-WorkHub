package sync

import (
	"context"
	"gorm.io/gorm"
)

// Repository defines CRUD queries for the sync queue and dynamic tables.
type Repository interface {
	FindByStatus(ctx context.Context, status string) ([]SyncQueue, error)
	Save(ctx context.Context, task *SyncQueue) error
	FetchRow(ctx context.Context, tableName string, id string) (map[string]interface{}, error)
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindByStatus(ctx context.Context, status string) ([]SyncQueue, error) {
	var tasks []SyncQueue
	err := r.db.WithContext(ctx).
		Where("status = ?", status).
		Find(&tasks).Error
	return tasks, err
}

func (r *repository) Save(ctx context.Context, task *SyncQueue) error {
	return r.db.WithContext(ctx).Save(task).Error
}

func (r *repository) FetchRow(ctx context.Context, tableName string, id string) (map[string]interface{}, error) {
	var result map[string]interface{}
	err := r.db.WithContext(ctx).Table(tableName).Where("id = ?", id).Take(&result).Error
	return result, err
}
