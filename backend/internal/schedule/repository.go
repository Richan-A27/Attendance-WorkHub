package schedule

import (
	"context"
	"gorm.io/gorm"
)

// Repository defines database operations for WorkSchedule management.
type Repository interface {
	FindAllActive(ctx context.Context) ([]WorkSchedule, error)
	FindByID(ctx context.Context, id uint64) (*WorkSchedule, error)
	FindActiveByEmployeeID(ctx context.Context, employeeID uint64) (*WorkSchedule, error)
	Save(ctx context.Context, schedule *WorkSchedule) error
	Delete(ctx context.Context, id uint64) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAllActive(ctx context.Context) ([]WorkSchedule, error) {
	var schedules []WorkSchedule
	err := r.db.WithContext(ctx).Where("active = ?", true).Find(&schedules).Error
	return schedules, err
}

func (r *repository) FindByID(ctx context.Context, id uint64) (*WorkSchedule, error) {
	var ws WorkSchedule
	err := r.db.WithContext(ctx).First(&ws, id).Error
	if err != nil {
		return nil, err
	}
	return &ws, nil
}

func (r *repository) FindActiveByEmployeeID(ctx context.Context, employeeID uint64) (*WorkSchedule, error) {
	var ws WorkSchedule
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND active = ?", employeeID, true).
		Order("updated_at DESC").
		First(&ws).Error
	if err != nil {
		return nil, err
	}
	return &ws, nil
}

func (r *repository) Save(ctx context.Context, ws *WorkSchedule) error {
	return r.db.WithContext(ctx).Save(ws).Error
}

func (r *repository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&WorkSchedule{}, id).Error
}
