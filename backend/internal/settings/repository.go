package settings

import (
	"context"
	"gorm.io/gorm"
)

// Repository defines database queries for Settings/Company Profile.
type Repository interface {
	FindFirst(ctx context.Context) (*CompanyProfile, error)
	Save(ctx context.Context, profile *CompanyProfile) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindFirst(ctx context.Context) (*CompanyProfile, error) {
	var profile CompanyProfile
	err := r.db.WithContext(ctx).First(&profile).Error
	if err != nil {
		return nil, err
	}
	return &profile, nil
}

func (r *repository) Save(ctx context.Context, profile *CompanyProfile) error {
	return r.db.WithContext(ctx).Save(profile).Error
}
