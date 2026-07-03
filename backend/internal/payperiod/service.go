package payperiod

import (
	"context"
	"errors"
)

// Service defines business logic operations for PayPeriods.
type Service interface {
	CreatePayPeriod(ctx context.Context, name, startDate, endDate string) (*PayPeriod, error)
	ListPayPeriods(ctx context.Context) ([]PayPeriod, error)
	GetPayPeriod(ctx context.Context, id uint64) (*PayPeriod, error)
	GetOpenPeriods(ctx context.Context) ([]PayPeriod, error)
	UpdatePeriodStatus(ctx context.Context, id uint64, status string) (*PayPeriod, error)
	DeletePayPeriod(ctx context.Context, id uint64) error
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreatePayPeriod(ctx context.Context, name, startDate, endDate string) (*PayPeriod, error) {
	if name == "" || startDate == "" || endDate == "" {
		return nil, errors.New("name, startDate and endDate are required")
	}
	if endDate <= startDate {
		return nil, errors.New("endDate must be after startDate")
	}
	period := &PayPeriod{
		Name:      name,
		StartDate: startDate,
		EndDate:   endDate,
		Status:    StatusOpen,
	}
	if err := s.repo.Save(ctx, period); err != nil {
		return nil, err
	}
	return period, nil
}

func (s *service) ListPayPeriods(ctx context.Context) ([]PayPeriod, error) {
	return s.repo.FindAll(ctx)
}

func (s *service) GetPayPeriod(ctx context.Context, id uint64) (*PayPeriod, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *service) GetOpenPeriods(ctx context.Context) ([]PayPeriod, error) {
	return s.repo.FindOpen(ctx)
}

var validStatuses = map[string]bool{
	StatusOpen:       true,
	StatusProcessing: true,
	StatusFinalized:  true,
	StatusPaid:       true,
}

func (s *service) UpdatePeriodStatus(ctx context.Context, id uint64, status string) (*PayPeriod, error) {
	if !validStatuses[status] {
		return nil, errors.New("invalid status: must be one of OPEN, PROCESSING, FINALIZED, PAID")
	}
	period, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, errors.New("pay period not found")
	}
	period.Status = status
	if err := s.repo.Save(ctx, period); err != nil {
		return nil, err
	}
	return period, nil
}

func (s *service) DeletePayPeriod(ctx context.Context, id uint64) error {
	period, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return errors.New("pay period not found")
	}
	if period.Status != StatusOpen {
		return errors.New("only OPEN pay periods can be deleted")
	}
	return s.repo.Delete(ctx, id)
}
