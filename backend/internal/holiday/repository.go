package holiday

import (
	"context"
	"gorm.io/gorm"
)

// Repository defines database operations for Holiday management.
type Repository interface {
	FindAll(ctx context.Context) ([]Holiday, error)
	FindByID(ctx context.Context, id uint64) (*Holiday, error)
	FindHolidayForDate(ctx context.Context, date string) (*Holiday, error)
	FindHolidaysInPeriod(ctx context.Context, startDate, endDate string) ([]Holiday, error)
	Save(ctx context.Context, h *Holiday) error
	Delete(ctx context.Context, id uint64) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAll(ctx context.Context) ([]Holiday, error) {
	var holidays []Holiday
	err := r.db.WithContext(ctx).Order("holiday_date ASC").Find(&holidays).Error
	return holidays, err
}

func (r *repository) FindByID(ctx context.Context, id uint64) (*Holiday, error) {
	var h Holiday
	err := r.db.WithContext(ctx).First(&h, id).Error
	if err != nil {
		return nil, err
	}
	return &h, nil
}

func (r *repository) FindHolidayForDate(ctx context.Context, date string) (*Holiday, error) {
	var h Holiday
	err := r.db.WithContext(ctx).
		Where("holiday_date = ? OR (is_recurring = true AND EXTRACT(MONTH FROM holiday_date) = EXTRACT(MONTH FROM ?::date) AND EXTRACT(DAY FROM holiday_date) = EXTRACT(DAY FROM ?::date))", date, date, date).
		First(&h).Error
	if err != nil {
		return nil, err
	}
	return &h, nil
}

func (r *repository) FindHolidaysInPeriod(ctx context.Context, startDate, endDate string) ([]Holiday, error) {
	var holidays []Holiday
	err := r.db.WithContext(ctx).
		Where("holiday_date >= ? AND holiday_date <= ?", startDate, endDate).
		Order("holiday_date ASC").
		Find(&holidays).Error
	return holidays, err
}

func (r *repository) Save(ctx context.Context, h *Holiday) error {
	return r.db.WithContext(ctx).Save(h).Error
}

func (r *repository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&Holiday{}, id).Error
}
