package attendance

import (
	"context"
	"time"
	"gorm.io/gorm"
)

// Repository defines database queries for raw punch logs and adjustments.
type Repository interface {
	FindAllPaginated(ctx context.Context, offset, limit int) ([]AttendanceLog, int64, error)
	FindByEmployeeIDPaginated(ctx context.Context, employeeID uint64, offset, limit int) ([]AttendanceLog, int64, error)
	FindByDateRangePaginated(ctx context.Context, start, end time.Time, offset, limit int) ([]AttendanceLog, int64, error)
	FindRecent(ctx context.Context, limit int) ([]AttendanceLog, error)
	FindLatestPunchTime(ctx context.Context) (*time.Time, error)
	FindByEmployeeIDAndDateRange(ctx context.Context, employeeID uint64, start, end time.Time) ([]AttendanceLog, error)
	FindDistinctEmployeeIDs(ctx context.Context, start, end time.Time) ([]uint64, error)
	Save(ctx context.Context, log *AttendanceLog) error
	SaveAll(ctx context.Context, logs []*AttendanceLog) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAllPaginated(ctx context.Context, offset, limit int) ([]AttendanceLog, int64, error) {
	var logs []AttendanceLog
	var total int64

	err := r.db.WithContext(ctx).Model(&AttendanceLog{}).Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = r.db.WithContext(ctx).Order("punch_time DESC").Offset(offset).Limit(limit).Find(&logs).Error
	return logs, total, err
}

func (r *repository) FindByEmployeeIDPaginated(ctx context.Context, employeeID uint64, offset, limit int) ([]AttendanceLog, int64, error) {
	var logs []AttendanceLog
	var total int64

	err := r.db.WithContext(ctx).Model(&AttendanceLog{}).Where("employee_id = ?", employeeID).Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = r.db.WithContext(ctx).Where("employee_id = ?", employeeID).Order("punch_time DESC").Offset(offset).Limit(limit).Find(&logs).Error
	return logs, total, err
}

func (r *repository) FindByDateRangePaginated(ctx context.Context, start, end time.Time, offset, limit int) ([]AttendanceLog, int64, error) {
	var logs []AttendanceLog
	var total int64

	err := r.db.WithContext(ctx).Model(&AttendanceLog{}).Where("punch_time >= ? AND punch_time <= ?", start, end).Count(&total).Error
	if err != nil {
		return nil, 0, err
	}

	err = r.db.WithContext(ctx).Where("punch_time >= ? AND punch_time <= ?", start, end).Order("punch_time DESC").Offset(offset).Limit(limit).Find(&logs).Error
	return logs, total, err
}

func (r *repository) FindRecent(ctx context.Context, limit int) ([]AttendanceLog, error) {
	var logs []AttendanceLog
	err := r.db.WithContext(ctx).Order("punch_time DESC").Limit(limit).Find(&logs).Error
	return logs, err
}

func (r *repository) FindLatestPunchTime(ctx context.Context) (*time.Time, error) {
	var latest time.Time
	err := r.db.WithContext(ctx).Model(&AttendanceLog{}).Select("MAX(punch_time)").Row().Scan(&latest)
	if err != nil {
		return nil, err
	}
	return &latest, nil
}

func (r *repository) FindByEmployeeIDAndDateRange(ctx context.Context, employeeID uint64, start, end time.Time) ([]AttendanceLog, error) {
	var logs []AttendanceLog
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND punch_time BETWEEN ? AND ?", employeeID, start, end).
		Order("punch_time ASC").
		Find(&logs).Error
	return logs, err
}

func (r *repository) FindDistinctEmployeeIDs(ctx context.Context, start, end time.Time) ([]uint64, error) {
	var ids []uint64
	err := r.db.WithContext(ctx).Model(&AttendanceLog{}).
		Distinct("employee_id").
		Where("punch_time BETWEEN ? AND ?", start, end).
		Pluck("employee_id", &ids).Error
	return ids, err
}

func (r *repository) Save(ctx context.Context, log *AttendanceLog) error {
	return r.db.WithContext(ctx).Save(log).Error
}

func (r *repository) SaveAll(ctx context.Context, logs []*AttendanceLog) error {
	if len(logs) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).Create(&logs).Error
}
