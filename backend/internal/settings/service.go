package settings

import (
	"context"
	"errors"
	"gorm.io/gorm"
)

// Service defines settings management operations.
type Service interface {
	GetProfile(ctx context.Context) (*CompanyProfile, error)
	SaveProfile(ctx context.Context, profile *CompanyProfile) (*CompanyProfile, error)
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetProfile(ctx context.Context) (*CompanyProfile, error) {
	p, err := s.repo.FindFirst(ctx)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &CompanyProfile{
				CompanyName: "WorkHub",
				DayBoundary: "06:00:00",
			}, nil
		}
		return nil, err
	}
	return p, nil
}

func (s *service) SaveProfile(ctx context.Context, profile *CompanyProfile) (*CompanyProfile, error) {
	existing, err := s.repo.FindFirst(ctx)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			existing = &CompanyProfile{}
		} else {
			return nil, err
		}
	}

	existing.CompanyName = profile.CompanyName
	existing.Address = profile.Address
	existing.ContactEmail = profile.ContactEmail
	existing.ContactPhone = profile.ContactPhone
	existing.TaxID = profile.TaxID

	if profile.DayBoundary != "" {
		existing.DayBoundary = profile.DayBoundary
	} else if existing.DayBoundary == "" {
		existing.DayBoundary = "06:00:00"
	}

	err = s.repo.Save(ctx, existing)
	if err != nil {
		return nil, err
	}
	return existing, nil
}
