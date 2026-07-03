package payroll

import (
	"context"
	"gorm.io/gorm"
)

// Repository handles CRUD operations for PayrollRecords.
type Repository interface {
	// Period-based queries (new)
	FindByPayPeriodID(ctx context.Context, payPeriodID uint64) ([]PayrollRecord, error)
	FindByEmployeeAndPayPeriod(ctx context.Context, employeeID, payPeriodID uint64) (*PayrollRecord, error)
	UpsertForPeriod(ctx context.Context, record *PayrollRecord) error

	// Month-based queries (kept for backward compat)
	FindByEmployeeIDAndMonthAndYear(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error)
	FindByMonthAndYear(ctx context.Context, month, year int) ([]PayrollRecord, error)
	FindByEmployeeID(ctx context.Context, employeeID uint64) ([]PayrollRecord, error)
	FindByStatus(ctx context.Context, status string) ([]PayrollRecord, error)
	FindByMonthAndYearOrderByEmployee(ctx context.Context, month, year int) ([]PayrollRecord, error)
	SumNetPayForMonth(ctx context.Context, month, year int) (float64, error)
	SumGrossPayForMonth(ctx context.Context, month, year int) (float64, error)
	FindEmployeePayrollHistory(ctx context.Context, employeeID uint64) ([]PayrollRecord, error)
	Save(ctx context.Context, record *PayrollRecord) error
}

type repository struct {
	db *gorm.DB
}

// NewRepository creates a new Repository instance.
func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

// --- Period-based (new) ---

func (r *repository) FindByPayPeriodID(ctx context.Context, payPeriodID uint64) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("pay_period_id = ?", payPeriodID).
		Order("employee_id ASC").
		Find(&records).Error
	return records, err
}

func (r *repository) FindByEmployeeAndPayPeriod(ctx context.Context, employeeID, payPeriodID uint64) (*PayrollRecord, error) {
	var record PayrollRecord
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND pay_period_id = ?", employeeID, payPeriodID).
		First(&record).Error
	if err != nil {
		return nil, err
	}
	return &record, nil
}

// UpsertForPeriod inserts a new payroll record or overwrites an existing PENDING one.
// PAID records are protected from overwrite.
func (r *repository) UpsertForPeriod(ctx context.Context, record *PayrollRecord) error {
	existing, err := r.FindByEmployeeAndPayPeriod(ctx, record.EmployeeID, *record.PayPeriodID)
	if err == nil {
		// Record exists — protect PAID records
		if existing.Status == StatusPaid {
			return errPaidRecordProtected
		}
		record.ID = existing.ID
	}
	return r.db.WithContext(ctx).Save(record).Error
}

var errPaidRecordProtected = &payrollError{"cannot overwrite a PAID payroll record"}

type payrollError struct{ msg string }

func (e *payrollError) Error() string { return e.msg }

// --- Month-based (kept for backward compat) ---

func (r *repository) FindByEmployeeIDAndMonthAndYear(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error) {
	var pr PayrollRecord
	err := r.db.WithContext(ctx).
		Where("employee_id = ? AND month = ? AND year = ? AND pay_period_id IS NULL", employeeID, month, year).
		First(&pr).Error
	if err != nil {
		return nil, err
	}
	return &pr, nil
}

func (r *repository) FindByMonthAndYear(ctx context.Context, month, year int) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("month = ? AND year = ?", month, year).
		Find(&records).Error
	return records, err
}

func (r *repository) FindByEmployeeID(ctx context.Context, employeeID uint64) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("employee_id = ?", employeeID).
		Find(&records).Error
	return records, err
}

func (r *repository) FindByStatus(ctx context.Context, status string) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("status = ?", status).
		Find(&records).Error
	return records, err
}

func (r *repository) FindByMonthAndYearOrderByEmployee(ctx context.Context, month, year int) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("month = ? AND year = ?", month, year).
		Order("employee_id ASC").
		Find(&records).Error
	return records, err
}

func (r *repository) SumNetPayForMonth(ctx context.Context, month, year int) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&PayrollRecord{}).
		Select("COALESCE(SUM(net_pay), 0)").
		Where("month = ? AND year = ?", month, year).
		Row().Scan(&total)
	return total, err
}

func (r *repository) SumGrossPayForMonth(ctx context.Context, month, year int) (float64, error) {
	var total float64
	err := r.db.WithContext(ctx).Model(&PayrollRecord{}).
		Select("COALESCE(SUM(gross_pay), 0)").
		Where("month = ? AND year = ?", month, year).
		Row().Scan(&total)
	return total, err
}

func (r *repository) FindEmployeePayrollHistory(ctx context.Context, employeeID uint64) ([]PayrollRecord, error) {
	var records []PayrollRecord
	err := r.db.WithContext(ctx).
		Where("employee_id = ?", employeeID).
		Order("year DESC, month DESC").
		Find(&records).Error
	return records, err
}

func (r *repository) Save(ctx context.Context, record *PayrollRecord) error {
	return r.db.WithContext(ctx).Save(record).Error
}
