package dashboard

import (
	"context"
	"math"
	"time"
	"com.isravel.workhub/internal/attendance"
	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/payroll"
)

// Service defines functions for dashboard KPI aggregate summaries.
type Service interface {
	GetSummary(ctx context.Context) (map[string]interface{}, error)
}

type service struct {
	empRepo      employee.Repository
	punchRepo    attendance.Repository
	intelRepo    intelligence.Repository
	payrollRepo  payroll.Repository
}

// NewService creates a new Service instance.
func NewService(empRepo employee.Repository, punchRepo attendance.Repository, intelRepo intelligence.Repository, payrollRepo payroll.Repository) Service {
	return &service{
		empRepo:     empRepo,
		punchRepo:   punchRepo,
		intelRepo:   intelRepo,
		payrollRepo: payrollRepo,
	}
}

func (s *service) GetSummary(ctx context.Context) (map[string]interface{}, error) {
	m := make(map[string]interface{})

	// 1. Employee counts
	activeEmployees, err := s.empRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	totalEmployees := len(activeEmployees)
	activeCount := 0
	for _, emp := range activeEmployees {
		if emp.Active {
			activeCount++
		}
	}
	m["totalEmployees"] = totalEmployees
	m["activeEmployees"] = activeCount

	// 2. Attendance logs today count
	now := time.Now()
	startToday := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	endToday := startToday.AddDate(0, 0, 1).Add(-time.Nanosecond)

	_, todayPunchesCount, _ := s.punchRepo.FindByDateRangePaginated(ctx, startToday, endToday, 0, 1)
	m["attendanceLogsToday"] = todayPunchesCount

	// 3. Latest punch time
	latestPunchTime, err := s.punchRepo.FindLatestPunchTime(ctx)
	if err == nil && latestPunchTime != nil && !latestPunchTime.IsZero() {
		m["latestPunch"] = latestPunchTime
	} else {
		m["latestPunch"] = nil
	}

	// 4. Workforce Intelligence metrics
	todayStr := now.Format("2006-01-02")
	todayAttendance, err := s.intelRepo.FindByDate(ctx, todayStr)
	if err != nil {
		todayAttendance = []intelligence.DailyAttendance{}
	}

	var presentToday int64
	var absentToday int64
	var lateToday int64
	var onLeaveToday int64
	var halfDayToday int64
	var totalMinutesToday int
	var totalOvertimeMinutesToday int

	for _, d := range todayAttendance {
		if d.Status == "PRESENT" || d.Status == "LATE" {
			presentToday++
		}
		if d.Status == "ABSENT" {
			absentToday++
		}
		if d.IsLate {
			lateToday++
		}
		if d.Status == "HOLIDAY" || d.Status == "WEEKEND" || d.Status == "ON_LEAVE" {
			onLeaveToday++
		}
		if d.Status == "HALF_DAY" {
			halfDayToday++
		}
		totalMinutesToday += d.TotalWorkingMinutes
		totalOvertimeMinutesToday += d.OvertimeMinutes
	}

	m["presentToday"] = presentToday
	m["absentToday"] = absentToday
	m["lateToday"] = lateToday
	m["onLeaveToday"] = onLeaveToday
	m["halfDayToday"] = halfDayToday
	m["totalHoursToday"] = math.Round((float64(totalMinutesToday)/60.0)*100.0) / 100.0
	m["totalOvertimeHoursToday"] = math.Round((float64(totalOvertimeMinutesToday)/60.0)*100.0) / 100.0

	// 5. Payroll Net pay sum this month
	monthlyRecords, err := s.payrollRepo.FindByMonthAndYear(ctx, int(now.Month()), now.Year())
	var payrollThisMonth float64
	if err == nil {
		for _, pr := range monthlyRecords {
			payrollThisMonth += pr.NetPay
		}
	}
	m["payrollThisMonth"] = math.Round(payrollThisMonth*100.0) / 100.0

	return m, nil
}
