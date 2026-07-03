package payperiod

import (
	"context"
	"gorm.io/gorm"
)

// Repository handles CRUD for PayPeriod records.
type Repository interface {
	FindAll(ctx context.Context) ([]PayPeriod, error)
	FindByID(ctx context.Context, id uint64) (*PayPeriod, error)
	FindByStatus(ctx context.Context, status string) ([]PayPeriod, error)
	FindOpen(ctx context.Context) ([]PayPeriod, error)
	Save(ctx context.Context, period *PayPeriod) error
	UpdateStatus(ctx context.Context, id uint64, status string) error
	Delete(ctx context.Context, id uint64) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAll(ctx context.Context) ([]PayPeriod, error) {
	var periods []PayPeriod
	err := r.db.WithContext(ctx).Order("start_date DESC").Find(&periods).Error
	return periods, err
}

func (r *repository) FindByID(ctx context.Context, id uint64) (*PayPeriod, error) {
	var period PayPeriod
	err := r.db.WithContext(ctx).First(&period, id).Error
	if err != nil {
		return nil, err
	}
	return &period, nil
}

func (r *repository) FindByStatus(ctx context.Context, status string) ([]PayPeriod, error) {
	var periods []PayPeriod
	err := r.db.WithContext(ctx).Where("status = ?", status).Order("start_date DESC").Find(&periods).Error
	return periods, err
}

func (r *repository) FindOpen(ctx context.Context) ([]PayPeriod, error) {
	var periods []PayPeriod
	err := r.db.WithContext(ctx).
		Where("status IN ('OPEN','PROCESSING')").
		Order("start_date DESC").
		Find(&periods).Error
	return periods, err
}

func (r *repository) Save(ctx context.Context, period *PayPeriod) error {
	return r.db.WithContext(ctx).Save(period).Error
}

func (r *repository) UpdateStatus(ctx context.Context, id uint64, status string) error {
	return r.db.WithContext(ctx).Model(&PayPeriod{}).Where("id = ?", id).Update("status", status).Error
}

func (r *repository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&PayPeriod{}, id).Error
}
