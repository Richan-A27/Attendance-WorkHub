package employee

import (
	"context"
	"gorm.io/gorm"
)

// Repository defines database operations for Employee management.
type Repository interface {
	FindAll(ctx context.Context) ([]Employee, error)
	FindByID(ctx context.Context, id uint64) (*Employee, error)
	Save(ctx context.Context, emp *Employee) error
	Delete(ctx context.Context, id uint64) error
	CountActive(ctx context.Context) (int64, error)
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAll(ctx context.Context) ([]Employee, error) {
	var employees []Employee
	err := r.db.WithContext(ctx).Order("id ASC").Find(&employees).Error
	return employees, err
}

func (r *repository) FindByID(ctx context.Context, id uint64) (*Employee, error) {
	var emp Employee
	err := r.db.WithContext(ctx).First(&emp, id).Error
	if err != nil {
		return nil, err
	}
	return &emp, nil
}

func (r *repository) Save(ctx context.Context, emp *Employee) error {
	return r.db.WithContext(ctx).Save(emp).Error
}

func (r *repository) Delete(ctx context.Context, id uint64) error {
	return r.db.WithContext(ctx).Delete(&Employee{}, id).Error
}

func (r *repository) CountActive(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&Employee{}).Where("active = ?", true).Count(&count).Error
	return count, err
}
