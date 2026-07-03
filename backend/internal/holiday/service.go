package holiday

import (
	"context"
	"time"
)

// Service defines holiday operations and logic checks.
type Service interface {
	FindAll(ctx context.Context) ([]Holiday, error)
	FindByID(ctx context.Context, id uint64) (*Holiday, error)
	FindHolidayForDate(ctx context.Context, date string) (*Holiday, error)
	FindHolidaysInPeriod(ctx context.Context, startDate, endDate string) ([]Holiday, error)
	Create(ctx context.Context, h *Holiday) (*Holiday, error)
	Update(ctx context.Context, id uint64, h *Holiday) (*Holiday, error)
	Delete(ctx context.Context, id uint64) error
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) FindAll(ctx context.Context) ([]Holiday, error) {
	return s.repo.FindAll(ctx)
}

func (s *service) FindByID(ctx context.Context, id uint64) (*Holiday, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *service) FindHolidayForDate(ctx context.Context, date string) (*Holiday, error) {
	return s.repo.FindHolidayForDate(ctx, date)
}

func (s *service) FindHolidaysInPeriod(ctx context.Context, startDate, endDate string) ([]Holiday, error) {
	return s.repo.FindHolidaysInPeriod(ctx, startDate, endDate)
}

func (s *service) Create(ctx context.Context, h *Holiday) (*Holiday, error) {
	h.CreatedAt = time.Now()
	err := s.repo.Save(ctx, h)
	if err != nil {
		return nil, err
	}
	return h, nil
}

func (s *service) Update(ctx context.Context, id uint64, h *Holiday) (*Holiday, error) {
	existing, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	existing.Name = h.Name
	existing.HolidayDate = h.HolidayDate
	existing.IsRecurring = h.IsRecurring

	err = s.repo.Save(ctx, existing)
	if err != nil {
		return nil, err
	}
	return existing, nil
}

func (s *service) Delete(ctx context.Context, id uint64) error {
	return s.repo.Delete(ctx, id)
}
