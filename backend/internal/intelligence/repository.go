package intelligence

import (
	"context"
	"errors"
	"gorm.io/gorm"
)

// Repository handles database operations for Sessions, Breaks, and Daily Attendance.
type Repository interface {
	FindSessions(ctx context.Context, employeeID uint64, date string) ([]AttendanceSession, error)
	SaveSession(ctx context.Context, session *AttendanceSession) error
	DeleteSessions(ctx context.Context, employeeID uint64, date string) error

	FindBreaks(ctx context.Context, employeeID uint64, date string) ([]AttendanceBreak, error)
	SaveBreak(ctx context.Context, ab *AttendanceBreak) error
	DeleteBreaks(ctx context.Context, employeeID uint64, date string) error

	FindByEmployeeIDAndDate(ctx context.Context, employeeID uint64, date string) (*DailyAttendance, error)
	FindByEmployeeIDAndDateRange(ctx context.Context, employeeID uint64, startDate, endDate string) ([]DailyAttendance, error)
	FindByDateRange(ctx context.Context, startDate, endDate string) ([]DailyAttendance, error)
	FindByDate(ctx context.Context, date string) ([]DailyAttendance, error)
	SaveDailyAttendance(ctx context.Context, da *DailyAttendance) error

	CountPresentDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error)
	CountAbsentDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error)
	CountLateDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error)
	SumWorkingMinutes(ctx context.Context, employeeID uint64, startDate, endDate string) (int, error)
	SumOvertimeMinutes(ctx context.Context, employeeID uint64, startDate, endDate string) (int, error)
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindSessions(ctx context.Context, employeeID uint64, date string) ([]AttendanceSession, error) {
	var sessions []AttendanceSession
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND session_date = ?", employeeID, date).
		Order("session_number ASC").
		Find(&sessions).Error
	return sessions, err
}

func (r *repository) SaveSession(ctx context.Context, session *AttendanceSession) error {
	return r.db.WithContext(ctx).Save(session).Error
}

func (r *repository) DeleteSessions(ctx context.Context, employeeID uint64, date string) error {
	return r.db.WithContext(ctx).
		Where("employee_id = ? AND session_date = ?", employeeID, date).
		Delete(&AttendanceSession{}).Error
}

func (r *repository) FindBreaks(ctx context.Context, employeeID uint64, date string) ([]AttendanceBreak, error) {
	var breaks []AttendanceBreak
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND attendance_date = ?", employeeID, date).
		Order("break_number ASC").
		Find(&breaks).Error
	return breaks, err
}

func (r *repository) SaveBreak(ctx context.Context, ab *AttendanceBreak) error {
	return r.db.WithContext(ctx).Save(ab).Error
}

func (r *repository) DeleteBreaks(ctx context.Context, employeeID uint64, date string) error {
	return r.db.WithContext(ctx).
		Where("employee_id = ? AND attendance_date = ?", employeeID, date).
		Delete(&AttendanceBreak{}).Error
}

func (r *repository) FindByEmployeeIDAndDate(ctx context.Context, employeeID uint64, date string) (*DailyAttendance, error) {
	var da DailyAttendance
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND attendance_date = ?", employeeID, date).
		First(&da).Error
	if err != nil {
		return nil, err
	}
	return &da, nil
}

func (r *repository) FindByEmployeeIDAndDateRange(ctx context.Context, employeeID uint64, startDate, endDate string) ([]DailyAttendance, error) {
	var records []DailyAttendance
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ?", employeeID, startDate, endDate).
		Order("attendance_date DESC").
		Find(&records).Error
	return records, err
}

func (r *repository) FindByDateRange(ctx context.Context, startDate, endDate string) ([]DailyAttendance, error) {
	var records []DailyAttendance
	err := r.db.WithContext(ctx).
		Where("attendance_date BETWEEN ? AND ?", startDate, endDate).
		Order("attendance_date ASC").
		Find(&records).Error
	return records, err
}

func (r *repository) FindByDate(ctx context.Context, date string) ([]DailyAttendance, error) {
	var records []DailyAttendance
	err := r.db.WithContext(ctx).
		Where("attendance_date = ?", date).
		Find(&records).Error
	return records, err
}

func (r *repository) SaveDailyAttendance(ctx context.Context, da *DailyAttendance) error {
	return r.db.WithContext(ctx).Save(da).Error
}

func (r *repository) CountPresentDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&DailyAttendance{}).
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ? AND status = 'PRESENT'", employeeID, startDate, endDate).
		Count(&count).Error
	return count, err
}

func (r *repository) CountAbsentDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&DailyAttendance{}).
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ? AND status = 'ABSENT'", employeeID, startDate, endDate).
		Count(&count).Error
	return count, err
}

func (r *repository) CountLateDays(ctx context.Context, employeeID uint64, startDate, endDate string) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&DailyAttendance{}).
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ? AND is_late = true", employeeID, startDate, endDate).
		Count(&count).Error
	return count, err
}

func (r *repository) SumWorkingMinutes(ctx context.Context, employeeID uint64, startDate, endDate string) (int, error) {
	var total int
	err := r.db.WithContext(ctx).Model(&DailyAttendance{}).
		Select("COALESCE(SUM(total_working_minutes), 0)").
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ?", employeeID, startDate, endDate).
		Row().Scan(&total)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return 0, nil
		}
		return 0, err
	}
	return total, nil
}

func (r *repository) SumOvertimeMinutes(ctx context.Context, employeeID uint64, startDate, endDate string) (int, error) {
	var total int
	err := r.db.WithContext(ctx).Model(&DailyAttendance{}).
		Select("COALESCE(SUM(overtime_minutes), 0)").
		Where("employee_id = ? AND attendance_date BETWEEN ? AND ?", employeeID, startDate, endDate).
		Row().Scan(&total)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return 0, nil
		}
		return 0, err
	}
	return total, nil
}
