package schedule

import (
	"context"
	"time"
)

// Service defines work schedule calculations and operations.
type Service interface {
	FindAllActive(ctx context.Context) ([]WorkSchedule, error)
	FindByID(ctx context.Context, id uint64) (*WorkSchedule, error)
	FindActiveByEmployeeID(ctx context.Context, employeeID uint64) (*WorkSchedule, error)
	Create(ctx context.Context, ws *WorkSchedule) (*WorkSchedule, error)
	Update(ctx context.Context, id uint64, ws *WorkSchedule) (*WorkSchedule, error)
	Delete(ctx context.Context, id uint64) error
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) FindAllActive(ctx context.Context) ([]WorkSchedule, error) {
	return s.repo.FindAllActive(ctx)
}

func (s *service) FindByID(ctx context.Context, id uint64) (*WorkSchedule, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *service) FindActiveByEmployeeID(ctx context.Context, employeeID uint64) (*WorkSchedule, error) {
	return s.repo.FindActiveByEmployeeID(ctx, employeeID)
}

func (s *service) Create(ctx context.Context, ws *WorkSchedule) (*WorkSchedule, error) {
	ws.CreatedAt = time.Now()
	ws.UpdatedAt = time.Now()
	err := s.repo.Save(ctx, ws)
	if err != nil {
		return nil, err
	}
	return ws, nil
}

func (s *service) Update(ctx context.Context, id uint64, ws *WorkSchedule) (*WorkSchedule, error) {
	existing, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	existing.EmployeeID = ws.EmployeeID
	existing.StartTime = ws.StartTime
	existing.EndTime = ws.EndTime
	existing.LunchDurationMinutes = ws.LunchDurationMinutes
	existing.GracePeriodMinutes = ws.GracePeriodMinutes
	existing.WorkDays = ws.WorkDays
	existing.Active = ws.Active
	existing.UpdatedAt = time.Now()

	err = s.repo.Save(ctx, existing)
	if err != nil {
		return nil, err
	}
	return existing, nil
}

func (s *service) Delete(ctx context.Context, id uint64) error {
	return s.repo.Delete(ctx, id)
}
