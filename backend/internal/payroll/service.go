package payroll

import (
	"context"
	"errors"
	"math"
	"time"
	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/intelligence"
)

// Service defines functions for monthly payroll calculations.
type Service interface {
	CalculateMonthlyPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error)
	CalculatePayrollForAllEmployees(ctx context.Context, month, year int) ([]PayrollRecord, error)
	UpdatePayrollDeductions(ctx context.Context, employeeID uint64, month, year int, deductions float64) (*PayrollRecord, error)
	UpdatePayrollBonuses(ctx context.Context, employeeID uint64, month, year int, bonuses float64) (*PayrollRecord, error)
	ProcessPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error)
	ProcessAllPayrollForMonth(ctx context.Context, month, year int) error
}

type service struct {
	repo         Repository
	empRepo      employee.Repository
	intelRepo    intelligence.Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository, empRepo employee.Repository, intelRepo intelligence.Repository) Service {
	return &service{
		repo:      repo,
		empRepo:   empRepo,
		intelRepo: intelRepo,
	}
}

func (s *service) CalculateMonthlyPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error) {
	emp, err := s.empRepo.FindByID(ctx, employeeID)
	if err != nil {
		return nil, errors.New("employee not found with id: " + string(rune(employeeID)))
	}

	hourlyRate := emp.HourlyRate
	if hourlyRate <= 0 {
		return nil, errors.New("invalid hourly rate for employee: must be greater than 0")
	}

	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		record = &PayrollRecord{
			OvertimeMultiplier: 1.50,
		}
	}

	record.EmployeeID = employeeID
	record.Month = month
	record.Year = year
	record.HourlyRate = hourlyRate

	// Date boundaries
	loc, _ := time.LoadLocation("Asia/Kolkata")
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, loc)
	endDate := startDate.AddDate(0, 1, 0).Add(-time.Nanosecond)

	dailyRecords, err := s.intelRepo.FindByEmployeeIDAndDateRange(ctx, employeeID, startDate.Format("2006-01-02"), endDate.Format("2006-01-02"))
	if err != nil {
		dailyRecords = []intelligence.DailyAttendance{}
	}

	totalWorkingMinutes := 0
	totalOvertimeMinutes := 0

	for _, daily := range dailyRecords {
		totalWorkingMinutes += daily.TotalWorkingMinutes
		totalOvertimeMinutes += daily.OvertimeMinutes
	}

	regHrs := float64(totalWorkingMinutes)/60.0 - float64(totalOvertimeMinutes)/60.0
	otHrs := float64(totalOvertimeMinutes)/60.0

	regHrs = math.Round(regHrs*100.0) / 100.0
	otHrs = math.Round(otHrs*100.0) / 100.0

	record.RegularHours = regHrs
	record.OvertimeHours = otHrs

	regularPay := regHrs * hourlyRate
	overtimePay := otHrs * hourlyRate * record.OvertimeMultiplier

	grossPay := regularPay + overtimePay + record.Bonuses
	record.GrossPay = grossPay

	netPay := grossPay - record.Deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative")
	}
	record.NetPay = netPay
	record.Status = "CALCULATED"

	err = s.repo.Save(ctx, record)
	if err != nil {
		return nil, err
	}

	return record, nil
}

func (s *service) CalculatePayrollForAllEmployees(ctx context.Context, month, year int) ([]PayrollRecord, error) {
	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	var results []PayrollRecord
	for _, emp := range activeEmployees {
		if emp.Active {
			record, err := s.CalculateMonthlyPayroll(ctx, emp.ID, month, year)
			if err == nil {
				results = append(results, *record)
			}
		}
	}

	return results, nil
}

func (s *service) UpdatePayrollDeductions(ctx context.Context, employeeID uint64, month, year int, deductions float64) (*PayrollRecord, error) {
	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		return nil, errors.New("payroll record not found")
	}

	record.Deductions = deductions
	netPay := record.GrossPay - deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative")
	}
	record.NetPay = netPay

	err = s.repo.Save(ctx, record)
	if err != nil {
		return nil, err
	}
	return record, nil
}

func (s *service) UpdatePayrollBonuses(ctx context.Context, employeeID uint64, month, year int, bonuses float64) (*PayrollRecord, error) {
	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		return nil, errors.New("payroll record not found")
	}

	record.Bonuses = bonuses
	regularPay := record.RegularHours * record.HourlyRate
	overtimePay := record.OvertimeHours * record.HourlyRate * record.OvertimeMultiplier

	grossPay := regularPay + overtimePay + bonuses
	record.GrossPay = grossPay

	netPay := grossPay - record.Deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative")
	}
	record.NetPay = netPay

	err = s.repo.Save(ctx, record)
	if err != nil {
		return nil, err
	}
	return record, nil
}

func (s *service) ProcessPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error) {
	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		return nil, errors.New("payroll record not found")
	}

	record.Status = "PROCESSED"
	now := time.Now()
	record.ProcessedDate = &now

	err = s.repo.Save(ctx, record)
	if err != nil {
		return nil, err
	}
	return record, nil
}

func (s *service) ProcessAllPayrollForMonth(ctx context.Context, month, year int) error {
	records, err := s.repo.FindByMonthAndYear(ctx, month, year)
	if err != nil {
		return err
	}

	for _, r := range records {
		_, _ = s.ProcessPayroll(ctx, r.EmployeeID, month, year)
	}

	return nil
}
