package payroll

import (
	"context"
	"errors"
	"math"
	"time"

	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/payperiod"
)

// Service defines functions for payroll calculations.
type Service interface {
	// Period-based payroll (new)
	CalculatePayPeriodPayroll(ctx context.Context, employeeID, payPeriodID uint64, calculationMode string) (*PayrollRecord, error)
	GeneratePayrollForPeriod(ctx context.Context, req GeneratePayrollRequest) ([]PayrollRecord, error)
	PreviewPayrollForPeriod(ctx context.Context, payPeriodID uint64) ([]PayrollPreview, error)
	GetPayrollByPeriod(ctx context.Context, payPeriodID uint64) ([]PayrollRecord, error)
	MarkPayrollPaid(ctx context.Context, employeeID, payPeriodID uint64) (*PayrollRecord, error)

	// Month-based payroll (kept for backward compat)
	CalculateMonthlyPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error)
	CalculatePayrollForAllEmployees(ctx context.Context, month, year int) ([]PayrollRecord, error)
	UpdatePayrollDeductions(ctx context.Context, employeeID uint64, month, year int, deductions float64) (*PayrollRecord, error)
	UpdatePayrollBonuses(ctx context.Context, employeeID uint64, month, year int, bonuses float64) (*PayrollRecord, error)
	ProcessPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error)
	ProcessAllPayrollForMonth(ctx context.Context, month, year int) error
}

type service struct {
	repo          Repository
	empRepo       employee.Repository
	intelRepo     intelligence.Repository
	payPeriodRepo payperiod.Repository
}

// NewService creates a new Service instance.
func NewService(repo Repository, empRepo employee.Repository, intelRepo intelligence.Repository, payPeriodRepo payperiod.Repository) Service {
	return &service{
		repo:          repo,
		empRepo:       empRepo,
		intelRepo:     intelRepo,
		payPeriodRepo: payPeriodRepo,
	}
}

// --- Period-based payroll (new) ---

// CalculatePayPeriodPayroll generates payroll for a single employee for a specific pay period.
//
// calculationMode determines how paid hours are calculated:
//   - INCLUDE_BREAKS: Paid Hours = daily_attendance.total_minutes (first punch → last punch span)
//   - EXCLUDE_BREAKS: Paid Hours = daily_attendance.total_working_minutes (sum of session durations only)
//
// Overtime hours are always taken from daily_attendance.overtime_minutes (unchanged by the attendance engine).
func (s *service) CalculatePayPeriodPayroll(ctx context.Context, employeeID, payPeriodID uint64, calculationMode string) (*PayrollRecord, error) {
	emp, err := s.empRepo.FindByID(ctx, employeeID)
	if err != nil {
		return nil, errors.New("employee not found")
	}
	if emp.HourlyRate <= 0 {
		return nil, errors.New("invalid hourly rate for employee: must be greater than 0")
	}

	period, err := s.payPeriodRepo.FindByID(ctx, payPeriodID)
	if err != nil {
		return nil, errors.New("pay period not found")
	}

	// Normalize calculation mode — default to EXCLUDE_BREAKS if empty or invalid
	if calculationMode != ModeIncludeBreaks && calculationMode != ModeExcludeBreaks {
		calculationMode = ModeExcludeBreaks
	}

	// Normalize date strings — GORM may return DATE columns as full timestamps (e.g. "2026-07-07T00:00:00Z")
	startDateStr := normalizeDate(period.StartDate)
	endDateStr := normalizeDate(period.EndDate)

	// Fetch all daily attendance records within the pay period date range
	dailyRecords, err := s.intelRepo.FindByEmployeeIDAndDateRange(ctx, employeeID, startDateStr, endDateStr)
	if err != nil {
		dailyRecords = []intelligence.DailyAttendance{}
	}

	var paidMinutes int
	var overtimeMinutes int
	var breakMinutes int

	for _, daily := range dailyRecords {
		if calculationMode == ModeIncludeBreaks {
			// Use first-punch to last-punch span (total_minutes)
			paidMinutes += daily.TotalMinutes
		} else {
			// Use sum of session durations only (total_working_minutes)
			paidMinutes += daily.TotalWorkingMinutes
		}
		overtimeMinutes += daily.OvertimeMinutes
		breakMinutes += daily.BreakDurationMinutes
	}

	// Regular minutes = paid minutes minus overtime minutes (clamped to 0)
	regularMinutes := paidMinutes - overtimeMinutes
	if regularMinutes < 0 {
		regularMinutes = 0
	}

	paidHours := round2(float64(paidMinutes) / 60.0)
	regularHours := round2(float64(regularMinutes) / 60.0)
	overtimeHours := round2(float64(overtimeMinutes) / 60.0)
	breakHours := round2(float64(breakMinutes) / 60.0)

	overtimeMultiplier := 1.50

	// Fetch existing record for this period (to preserve deductions/bonuses/multiplier)
	record, err := s.repo.FindByEmployeeAndPayPeriod(ctx, employeeID, payPeriodID)
	if err != nil {
		// New record
		record = &PayrollRecord{
			EmployeeID:         employeeID,
			PayPeriodID:        &payPeriodID,
			OvertimeMultiplier: overtimeMultiplier,
		}
	}

	// Derive month/year from pay period start date for backward compatibility
	startDate, parseErr := time.Parse("2006-01-02", startDateStr)
	if parseErr == nil {
		record.Month = int(startDate.Month())
		record.Year = startDate.Year()
	}

	record.HourlyRate = emp.HourlyRate
	record.RegularHours = regularHours
	record.OvertimeHours = overtimeHours
	record.PaidHours = paidHours
	record.BreakHours = breakHours

	regularPay := regularHours * emp.HourlyRate
	overtimePay := overtimeHours * emp.HourlyRate * record.OvertimeMultiplier
	grossPay := regularPay + overtimePay + record.Bonuses
	record.GrossPay = round2(grossPay)

	netPay := grossPay - record.Deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative: deductions exceed gross pay")
	}
	record.NetPay = round2(netPay)
	record.Status = StatusPending

	if err := s.repo.UpsertForPeriod(ctx, record); err != nil {
		return nil, err
	}
	return record, nil
}

// GeneratePayrollForPeriod generates payroll for all active employees in a pay period.
// A global calculationMode is applied; per-employee overrides take precedence.
func (s *service) GeneratePayrollForPeriod(ctx context.Context, req GeneratePayrollRequest) ([]PayrollRecord, error) {
	if req.PayPeriodID == 0 {
		return nil, errors.New("payPeriodId is required")
	}

	// Validate pay period exists
	if _, err := s.payPeriodRepo.FindByID(ctx, req.PayPeriodID); err != nil {
		return nil, errors.New("pay period not found")
	}

	// Build override map for O(1) lookup
	overrideMap := make(map[uint64]string)
	for _, ov := range req.Overrides {
		overrideMap[ov.EmployeeID] = ov.CalculationMode
	}

	globalMode := req.CalculationMode
	if globalMode != ModeIncludeBreaks && globalMode != ModeExcludeBreaks {
		globalMode = ModeExcludeBreaks
	}

	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	var results []PayrollRecord
	for _, emp := range activeEmployees {
		if !emp.Active {
			continue
		}
		mode := globalMode
		if overrideMode, ok := overrideMap[emp.ID]; ok {
			mode = overrideMode
		}
		record, err := s.CalculatePayPeriodPayroll(ctx, emp.ID, req.PayPeriodID, mode)
		if err == nil {
			results = append(results, *record)
		}
	}
	return results, nil
}

// PreviewPayrollForPeriod computes both calculation modes for all active employees
// for a pay period. Nothing is written to the database.
func (s *service) PreviewPayrollForPeriod(ctx context.Context, payPeriodID uint64) ([]PayrollPreview, error) {
	period, err := s.payPeriodRepo.FindByID(ctx, payPeriodID)
	if err != nil {
		return nil, errors.New("pay period not found")
	}

	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	var previews []PayrollPreview
	for _, emp := range activeEmployees {
		if !emp.Active {
			continue
		}

		dailyRecords, _ := s.intelRepo.FindByEmployeeIDAndDateRange(ctx, emp.ID, normalizeDate(period.StartDate), normalizeDate(period.EndDate))

		var totalMinutes, workingMinutes, overtimeMinutes, breakMinutes int
		for _, daily := range dailyRecords {
			totalMinutes += daily.TotalMinutes
			workingMinutes += daily.TotalWorkingMinutes
			overtimeMinutes += daily.OvertimeMinutes
			breakMinutes += daily.BreakDurationMinutes
		}

		totalHours := round2(float64(totalMinutes) / 60.0)
		workHours := round2(float64(workingMinutes) / 60.0)
		otHours := round2(float64(overtimeMinutes) / 60.0)
		brkHours := round2(float64(breakMinutes) / 60.0)

		// Mode A — INCLUDE_BREAKS
		paidHoursA := totalHours
		regA := round2(paidHoursA - otHours)
		if regA < 0 {
			regA = 0
		}
		grossA := round2(regA*emp.HourlyRate + otHours*emp.HourlyRate*1.5)

		// Mode B — EXCLUDE_BREAKS
		paidHoursB := workHours
		regB := round2(paidHoursB - otHours)
		if regB < 0 {
			regB = 0
		}
		grossB := round2(regB*emp.HourlyRate + otHours*emp.HourlyRate*1.5)

		previews = append(previews, PayrollPreview{
			EmployeeID:    emp.ID,
			EmployeeName:  emp.Name,
			HourlyRate:    emp.HourlyRate,
			TotalHours:    totalHours,
			WorkingHours:  workHours,
			BreakHours:    brkHours,
			OvertimeHours: otHours,
			PaidHoursA:    paidHoursA,
			GrossPayA:     grossA,
			PaidHoursB:    paidHoursB,
			GrossPayB:     grossB,
			Difference:    round2(grossA - grossB),
		})
	}
	return previews, nil
}

// GetPayrollByPeriod returns all payroll records for a pay period.
func (s *service) GetPayrollByPeriod(ctx context.Context, payPeriodID uint64) ([]PayrollRecord, error) {
	return s.repo.FindByPayPeriodID(ctx, payPeriodID)
}

// MarkPayrollPaid sets a single employee's payroll record status to PAID.
func (s *service) MarkPayrollPaid(ctx context.Context, employeeID, payPeriodID uint64) (*PayrollRecord, error) {
	record, err := s.repo.FindByEmployeeAndPayPeriod(ctx, employeeID, payPeriodID)
	if err != nil {
		return nil, errors.New("payroll record not found")
	}
	now := time.Now()
	record.Status = StatusPaid
	record.ProcessedDate = &now
	if err := s.repo.Save(ctx, record); err != nil {
		return nil, err
	}
	return record, nil
}

// --- Month-based payroll (kept for backward compat) ---

func (s *service) CalculateMonthlyPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error) {
	emp, err := s.empRepo.FindByID(ctx, employeeID)
	if err != nil {
		return nil, errors.New("employee not found")
	}
	if emp.HourlyRate <= 0 {
		return nil, errors.New("invalid hourly rate for employee: must be greater than 0")
	}

	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		record = &PayrollRecord{OvertimeMultiplier: 1.50}
	}

	record.EmployeeID = employeeID
	record.Month = month
	record.Year = year
	record.HourlyRate = emp.HourlyRate

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

	regHrs := round2(float64(totalWorkingMinutes)/60.0 - float64(totalOvertimeMinutes)/60.0)
	otHrs := round2(float64(totalOvertimeMinutes) / 60.0)
	record.RegularHours = regHrs
	record.OvertimeHours = otHrs
	record.PaidHours = round2(float64(totalWorkingMinutes) / 60.0)

	regularPay := regHrs * emp.HourlyRate
	overtimePay := otHrs * emp.HourlyRate * record.OvertimeMultiplier
	grossPay := regularPay + overtimePay + record.Bonuses
	record.GrossPay = round2(grossPay)

	netPay := grossPay - record.Deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative")
	}
	record.NetPay = round2(netPay)
	record.Status = StatusPending

	if err := s.repo.Save(ctx, record); err != nil {
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
	record.NetPay = round2(netPay)
	if err := s.repo.Save(ctx, record); err != nil {
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
	grossPay := round2(regularPay + overtimePay + bonuses)
	record.GrossPay = grossPay
	netPay := grossPay - record.Deductions
	if netPay < 0 {
		return nil, errors.New("net pay cannot be negative")
	}
	record.NetPay = round2(netPay)
	if err := s.repo.Save(ctx, record); err != nil {
		return nil, err
	}
	return record, nil
}

func (s *service) ProcessPayroll(ctx context.Context, employeeID uint64, month, year int) (*PayrollRecord, error) {
	record, err := s.repo.FindByEmployeeIDAndMonthAndYear(ctx, employeeID, month, year)
	if err != nil {
		return nil, errors.New("payroll record not found")
	}
	now := time.Now()
	record.Status = StatusPaid
	record.ProcessedDate = &now
	if err := s.repo.Save(ctx, record); err != nil {
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

// normalizeDate ensures a date string is in "2006-01-02" format.
// GORM may return DATE columns from PostgreSQL as full RFC3339 timestamps.
func normalizeDate(s string) string {
	if len(s) > 10 {
		if t, err := time.Parse(time.RFC3339, s); err == nil {
			return t.Format("2006-01-02")
		}
		// try without timezone
		if t, err := time.Parse("2006-01-02T15:04:05Z", s); err == nil {
			return t.Format("2006-01-02")
		}
	}
	return s
}

// round2 rounds a float64 to 2 decimal places.
func round2(v float64) float64 {
	return math.Round(v*100.0) / 100.0
}
