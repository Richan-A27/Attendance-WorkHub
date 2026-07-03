package employee

import (
	"context"
	"time"
)

// Service defines employee operations and business logic calculations.
type Service interface {
	FindAll(ctx context.Context) ([]Employee, error)
	FindByID(ctx context.Context, id uint64) (*Employee, error)
	Create(ctx context.Context, emp *Employee) (*Employee, error)
	Update(ctx context.Context, id uint64, emp *Employee) (*Employee, error)
	Delete(ctx context.Context, id uint64) error
	PatchHourlyRate(ctx context.Context, id uint64, rate float64) (*Employee, error)
	PatchStatus(ctx context.Context, id uint64, active bool) (*Employee, error)
	CountActive(ctx context.Context) (int64, error)
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) FindAll(ctx context.Context) ([]Employee, error) {
	return s.repo.FindAll(ctx)
}

func (s *service) FindByID(ctx context.Context, id uint64) (*Employee, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *service) Create(ctx context.Context, emp *Employee) (*Employee, error) {
	emp.CreatedAt = time.Now()
	err := s.repo.Save(ctx, emp)
	if err != nil {
		return nil, err
	}
	return emp, nil
}

func (s *service) Update(ctx context.Context, id uint64, emp *Employee) (*Employee, error) {
	existing, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	existing.Name = emp.Name
	existing.HourlyRate = emp.HourlyRate
	existing.Active = emp.Active
	existing.Department = emp.Department
	existing.Designation = emp.Designation
	existing.EmploymentType = emp.EmploymentType

	now := time.Now()
	existing.UpdatedAt = &now

	err = s.repo.Save(ctx, existing)
	if err != nil {
		return nil, err
	}
	return existing, nil
}

func (s *service) Delete(ctx context.Context, id uint64) error {
	return s.repo.Delete(ctx, id)
}

func (s *service) PatchHourlyRate(ctx context.Context, id uint64, rate float64) (*Employee, error) {
	emp, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	emp.HourlyRate = rate
	now := time.Now()
	emp.UpdatedAt = &now

	err = s.repo.Save(ctx, emp)
	if err != nil {
		return nil, err
	}
	return emp, nil
}

func (s *service) PatchStatus(ctx context.Context, id uint64, active bool) (*Employee, error) {
	emp, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	emp.Active = active
	now := time.Now()
	emp.UpdatedAt = &now

	err = s.repo.Save(ctx, emp)
	if err != nil {
		return nil, err
	}
	return emp, nil
}

func (s *service) CountActive(ctx context.Context) (int64, error) {
	return s.repo.CountActive(ctx)
}
