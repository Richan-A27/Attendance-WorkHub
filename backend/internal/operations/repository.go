package operations

import (
	"context"
	"gorm.io/gorm"
)

// Repository handles database queries for subprocess run sync_history records.
type Repository interface {
	FindRecent(ctx context.Context, limit int) ([]SyncHistory, error)
	FindLatest(ctx context.Context) (*SyncHistory, error)
	CountAll(ctx context.Context) (int64, error)
	CountSuccessful(ctx context.Context) (int64, error)
	CountFailed(ctx context.Context) (int64, error)
	Save(ctx context.Context, history *SyncHistory) error
	FindByID(ctx context.Context, id uint64) (*SyncHistory, error)
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindRecent(ctx context.Context, limit int) ([]SyncHistory, error) {
	var history []SyncHistory
	err := r.db.WithContext(ctx).
		Order("sync_start_time DESC").
		Limit(limit).
		Find(&history).Error
	return history, err
}

func (r *repository) FindLatest(ctx context.Context) (*SyncHistory, error) {
	var sh SyncHistory
	err := r.db.WithContext(ctx).
		Order("sync_start_time DESC").
		First(&sh).Error
	if err != nil {
		return nil, err
	}
	return &sh, nil
}

func (r *repository) CountAll(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&SyncHistory{}).Count(&count).Error
	return count, err
}

func (r *repository) CountSuccessful(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&SyncHistory{}).
		Where("status = 'SUCCESS'").
		Count(&count).Error
	return count, err
}

func (r *repository) CountFailed(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&SyncHistory{}).
		Where("status = 'FAILURE'").
		Count(&count).Error
	return count, err
}

func (r *repository) Save(ctx context.Context, history *SyncHistory) error {
	return r.db.WithContext(ctx).Save(history).Error
}

func (r *repository) FindByID(ctx context.Context, id uint64) (*SyncHistory, error) {
	var sh SyncHistory
	err := r.db.WithContext(ctx).
		Where("id = ?", id).
		First(&sh).Error
	if err != nil {
		return nil, err
	}
	return &sh, nil
}
