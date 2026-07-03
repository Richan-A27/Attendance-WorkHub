package reports

import (
	"context"
	"math"
	"time"
	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/payroll"
)

// Service defines functions for generating weekly and monthly reports.
type Service interface {
	GenerateWeeklyReport(ctx context.Context, dateStr string) (*WeeklyReport, error)
	GenerateCurrentWeekReport(ctx context.Context) (*WeeklyReport, error)
	GenerateMonthlyReport(ctx context.Context, month, year int) (*MonthlyReport, error)
	GenerateCurrentMonthReport(ctx context.Context) (*MonthlyReport, error)
}

type service struct {
	empRepo     employee.Repository
	intelRepo   intelligence.Repository
	payrollRepo payroll.Repository
	rankingSvc  intelligence.RankingService
}

// NewService creates a new Service instance.
func NewService(empRepo employee.Repository, intelRepo intelligence.Repository, payrollRepo payroll.Repository, rankingSvc intelligence.RankingService) Service {
	return &service{
		empRepo:     empRepo,
		intelRepo:   intelRepo,
		payrollRepo: payrollRepo,
		rankingSvc:  rankingSvc,
	}
}

func (s *service) GenerateWeeklyReport(ctx context.Context, dateStr string) (*WeeklyReport, error) {
	loc, _ := time.LoadLocation("Asia/Kolkata")
	t, err := time.ParseInLocation("2006-01-02", dateStr, loc)
	if err != nil {
		return nil, err
	}

	offset := int(t.Weekday()) - int(time.Monday)
	if offset < 0 {
		offset += 7
	}
	weekStart := t.AddDate(0, 0, -offset)
	weekEnd := weekStart.AddDate(0, 0, 6)

	weekStartStr := weekStart.Format("2006-01-02")
	weekEndStr := weekEnd.Format("2006-01-02")

	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	var stats []EmployeeWeeklyStats
	for _, emp := range activeEmployees {
		if !emp.Active {
			continue
		}

		present, _ := s.intelRepo.CountPresentDays(ctx, emp.ID, weekStartStr, weekEndStr)
		absent, _ := s.intelRepo.CountAbsentDays(ctx, emp.ID, weekStartStr, weekEndStr)
		late, _ := s.intelRepo.CountLateDays(ctx, emp.ID, weekStartStr, weekEndStr)

		workingMinutes, _ := s.intelRepo.SumWorkingMinutes(ctx, emp.ID, weekStartStr, weekEndStr)
		overtimeMinutes, _ := s.intelRepo.SumOvertimeMinutes(ctx, emp.ID, weekStartStr, weekEndStr)

		workingHrs := float64(workingMinutes) / 60.0
		overtimeHrs := float64(overtimeMinutes) / 60.0

		// Standard work week count = 5 days
		attendancePercentage := (float64(present) / 5.0) * 100.0

		stats = append(stats, EmployeeWeeklyStats{
			EmployeeID:           emp.ID,
			EmployeeName:         emp.Name,
			PresentDays:          int(present),
			AbsentDays:           int(absent),
			LateDays:             int(late),
			TotalWorkingHours:    math.Round(workingHrs*100.0) / 100.0,
			TotalOvertimeHours:   math.Round(overtimeHrs*100.0) / 100.0,
			AttendancePercentage: math.Round(attendancePercentage*100.0) / 100.0,
		})
	}

	var totalPresent int
	var totalAbsent int
	var totalLate int
	var totalWorking float64
	var totalOvertime float64
	var sumAttendancePercentage float64

	for _, empStat := range stats {
		totalPresent += empStat.PresentDays
		totalAbsent += empStat.AbsentDays
		totalLate += empStat.LateDays
		totalWorking += empStat.TotalWorkingHours
		totalOvertime += empStat.TotalOvertimeHours
		sumAttendancePercentage += empStat.AttendancePercentage
	}

	avgAttendance := 0.0
	if len(stats) > 0 {
		avgAttendance = sumAttendancePercentage / float64(len(stats))
	}

	return &WeeklyReport{
		WeekStart:                   weekStartStr,
		WeekEnd:                     weekEndStr,
		EmployeeStats:               stats,
		TotalEmployees:              len(stats),
		TotalPresentDays:            totalPresent,
		TotalAbsentDays:             totalAbsent,
		TotalLateDays:               totalLate,
		TotalWorkingHours:           math.Round(totalWorking*100.0) / 100.0,
		TotalOvertimeHours:          math.Round(totalOvertime*100.0) / 100.0,
		AverageAttendancePercentage: math.Round(avgAttendance*100.0) / 100.0,
	}, nil
}

func (s *service) GenerateCurrentWeekReport(ctx context.Context) (*WeeklyReport, error) {
	now := time.Now().Format("2006-01-02")
	return s.GenerateWeeklyReport(ctx, now)
}

func (s *service) GenerateMonthlyReport(ctx context.Context, month, year int) (*MonthlyReport, error) {
	loc, _ := time.LoadLocation("Asia/Kolkata")
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, loc)
	endDate := startDate.AddDate(0, 1, 0).Add(-time.Nanosecond)

	startStr := startDate.Format("2006-01-02")
	endStr := endDate.Format("2006-01-02")

	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	// 1. Attendance statistics
	var attendanceStats []EmployeeMonthlyAttendanceStats
	workingDays := s.calculateWorkingDays(startDate, endDate)

	for _, emp := range activeEmployees {
		if !emp.Active {
			continue
		}

		present, _ := s.intelRepo.CountPresentDays(ctx, emp.ID, startStr, endStr)
		absent, _ := s.intelRepo.CountAbsentDays(ctx, emp.ID, startStr, endStr)
		late, _ := s.intelRepo.CountLateDays(ctx, emp.ID, startStr, endStr)

		workingMinutes, _ := s.intelRepo.SumWorkingMinutes(ctx, emp.ID, startStr, endStr)
		overtimeMinutes, _ := s.intelRepo.SumOvertimeMinutes(ctx, emp.ID, startStr, endStr)

		workingHrs := float64(workingMinutes) / 60.0
		overtimeHrs := float64(overtimeMinutes) / 60.0

		var attendancePercentage float64
		if workingDays > 0 {
			attendancePercentage = (float64(present) / float64(workingDays)) * 100.0
		}

		attendanceStats = append(attendanceStats, EmployeeMonthlyAttendanceStats{
			EmployeeID:           emp.ID,
			EmployeeName:         emp.Name,
			PresentDays:          int(present),
			AbsentDays:           int(absent),
			LateDays:             int(late),
			TotalWorkingHours:    math.Round(workingHrs*100.0) / 100.0,
			TotalOvertimeHours:   math.Round(overtimeHrs*100.0) / 100.0,
			AttendancePercentage: math.Round(attendancePercentage*100.0) / 100.0,
		})
	}

	// Aggregate attendance
	var totalPresent int
	var totalAbsent int
	var totalLate int
	var totalWorking float64
	var totalOvertime float64
	var sumAttendancePercentage float64

	for _, att := range attendanceStats {
		totalPresent += att.PresentDays
		totalAbsent += att.AbsentDays
		totalLate += att.LateDays
		totalWorking += att.TotalWorkingHours
		totalOvertime += att.TotalOvertimeHours
		sumAttendancePercentage += att.AttendancePercentage
	}

	avgAttendance := 0.0
	if len(attendanceStats) > 0 {
		avgAttendance = sumAttendancePercentage / float64(len(attendanceStats))
	}

	// 2. Payroll section
	payrollRecords, err := s.payrollRepo.FindByMonthAndYear(ctx, month, year)
	if err != nil {
		payrollRecords = []payroll.PayrollRecord{}
	}

	var totalGross float64
	var totalNet float64
	var totalDeductions float64
	var totalBonuses float64

	for _, pr := range payrollRecords {
		totalGross += pr.GrossPay
		totalNet += pr.NetPay
		totalDeductions += pr.Deductions
		totalBonuses += pr.Bonuses
	}

	// 3. Rankings section
	topPerformers, _ := s.rankingSvc.GetTopPerformers(ctx, month, year, 10)
	rankingsByOverallScore, _ := s.rankingSvc.RankEmployeesByOverallScore(ctx, month, year)
	rankingsByAttendance, _ := s.rankingSvc.RankEmployeesByAttendance(ctx, month, year)
	rankingsByPunctuality, _ := s.rankingSvc.RankEmployeesByPunctuality(ctx, month, year)
	rankingsByWorkingHours, _ := s.rankingSvc.RankEmployeesByWorkingHours(ctx, month, year)

	return &MonthlyReport{
		Month:                       month,
		Year:                        year,
		StartDate:                   startStr,
		EndDate:                     endStr,
		AttendanceStats:             attendanceStats,
		PayrollRecords:              payrollRecords,
		TopPerformers:               topPerformers,
		RankingsByOverallScore:      rankingsByOverallScore,
		RankingsByAttendance:        rankingsByAttendance,
		RankingsByPunctuality:       rankingsByPunctuality,
		RankingsByWorkingHours:      rankingsByWorkingHours,
		TotalPresentDays:            totalPresent,
		TotalAbsentDays:             totalAbsent,
		TotalLateDays:               totalLate,
		TotalWorkingHours:           math.Round(totalWorking*100.0) / 100.0,
		TotalOvertimeHours:          math.Round(totalOvertime*100.0) / 100.0,
		AverageAttendancePercentage: math.Round(avgAttendance*100.0) / 100.0,
		TotalGrossPay:               math.Round(totalGross*100.0) / 100.0,
		TotalNetPay:                 math.Round(totalNet*100.0) / 100.0,
		TotalDeductions:            math.Round(totalDeductions*100.0) / 100.0,
		TotalBonuses:               math.Round(totalBonuses*100.0) / 100.0,
	}, nil
}

func (s *service) GenerateCurrentMonthReport(ctx context.Context) (*MonthlyReport, error) {
	now := time.Now()
	return s.GenerateMonthlyReport(ctx, int(now.Month()), now.Year())
}

func (s *service) calculateWorkingDays(startDate, endDate time.Time) int {
	workingDays := 0
	curr := startDate
	for !curr.After(endDate) {
		wd := curr.Weekday()
		if wd != time.Saturday && wd != time.Sunday {
			workingDays++
		}
		curr = curr.AddDate(0, 0, 1)
	}
	return workingDays
}
