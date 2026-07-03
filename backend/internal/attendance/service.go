package attendance

import (
	"context"
	"time"
)

// Service defines functions for managing attendance log queries and page maps.
type Service interface {
	FindAll(ctx context.Context, page, size int) (*Page, error)
	FindByEmployeeID(ctx context.Context, employeeID uint64, page, size int) (*Page, error)
	FindByDateRange(ctx context.Context, start, end time.Time, page, size int) (*Page, error)
	FindRecent(ctx context.Context, limit int) ([]AttendanceLog, error)
	FindLatestPunchTime(ctx context.Context) (*time.Time, error)
	Save(ctx context.Context, log *AttendanceLog) (*AttendanceLog, error)
	SaveAll(ctx context.Context, logs []*AttendanceLog) ([]*AttendanceLog, error)
}

type service struct {
	repo Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

// Page mirrors Spring Boot's Pageable JSON layout.
type Page struct {
	Content          interface{} `json:"content"`
	TotalPages       int         `json:"totalPages"`
	TotalElements    int64       `json:"totalElements"`
	Size             int         `json:"size"`
	Number           int         `json:"number"`
}

func buildPage(content interface{}, totalElements int64, page, size int) *Page {
	totalPages := int(totalElements / int64(size))
	if totalElements%int64(size) > 0 || totalElements == 0 {
		totalPages++
	}
	if totalElements == 0 {
		totalPages = 0
	}
	return &Page{
		Content:       content,
		TotalPages:    totalPages,
		TotalElements: totalElements,
		Size:          size,
		Number:        page,
	}
}

func (s *service) FindAll(ctx context.Context, page, size int) (*Page, error) {
	offset := page * size
	logs, total, err := s.repo.FindAllPaginated(ctx, offset, size)
	if err != nil {
		return nil, err
	}
	return buildPage(logs, total, page, size), nil
}

func (s *service) FindByEmployeeID(ctx context.Context, employeeID uint64, page, size int) (*Page, error) {
	offset := page * size
	logs, total, err := s.repo.FindByEmployeeIDPaginated(ctx, employeeID, offset, size)
	if err != nil {
		return nil, err
	}
	return buildPage(logs, total, page, size), nil
}

func (s *service) FindByDateRange(ctx context.Context, start, end time.Time, page, size int) (*Page, error) {
	offset := page * size
	logs, total, err := s.repo.FindByDateRangePaginated(ctx, start, end, offset, size)
	if err != nil {
		return nil, err
	}
	return buildPage(logs, total, page, size), nil
}

func (s *service) FindRecent(ctx context.Context, limit int) ([]AttendanceLog, error) {
	return s.repo.FindRecent(ctx, limit)
}

func (s *service) FindLatestPunchTime(ctx context.Context) (*time.Time, error) {
	return s.repo.FindLatestPunchTime(ctx)
}

func (s *service) Save(ctx context.Context, log *AttendanceLog) (*AttendanceLog, error) {
	if log.CreatedAt.IsZero() {
		log.CreatedAt = time.Now()
	}
	err := s.repo.Save(ctx, log)
	if err != nil {
		return nil, err
	}
	return log, nil
}

func (s *service) SaveAll(ctx context.Context, logs []*AttendanceLog) ([]*AttendanceLog, error) {
	now := time.Now()
	for _, log := range logs {
		if log.CreatedAt.IsZero() {
			log.CreatedAt = now
		}
	}
	err := s.repo.SaveAll(ctx, logs)
	if err != nil {
		return nil, err
	}
	return logs, nil
}
