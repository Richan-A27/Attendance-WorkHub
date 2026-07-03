package intelligence

import (
	"context"
	"math"
	"time"
)

// ScoreEngine handles employee monthly performance scores calculations.
type ScoreEngine interface {
	CalculateEmployeeScore(ctx context.Context, employeeID uint64, month, year int) (*EmployeeScore, error)
}

type scoreEngine struct {
	repo Repository
}

// NewScoreEngine creates a new ScoreEngine instance.
func NewScoreEngine(repo Repository) ScoreEngine {
	return &scoreEngine{repo: repo}
}

func (s *scoreEngine) CalculateEmployeeScore(ctx context.Context, employeeID uint64, month, year int) (*EmployeeScore, error) {
	loc, _ := time.LoadLocation("Asia/Kolkata")
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, loc)
	endDate := startDate.AddDate(0, 1, 0).Add(-time.Nanosecond)

	startStr := startDate.Format("2006-01-02")
	endStr := endDate.Format("2006-01-02")

	totalWorkingDays := s.calculateWorkingDays(startDate, endDate)

	presentDays, err := s.repo.CountPresentDays(ctx, employeeID, startStr, endStr)
	if err != nil {
		presentDays = 0
	}

	absentDays, err := s.repo.CountAbsentDays(ctx, employeeID, startStr, endStr)
	if err != nil {
		absentDays = 0
	}

	lateDays, err := s.repo.CountLateDays(ctx, employeeID, startStr, endStr)
	if err != nil {
		lateDays = 0
	}

	totalWorkingMinutes, err := s.repo.SumWorkingMinutes(ctx, employeeID, startStr, endStr)
	if err != nil {
		totalWorkingMinutes = 0
	}

	totalOvertimeMinutes, err := s.repo.SumOvertimeMinutes(ctx, employeeID, startStr, endStr)
	if err != nil {
		totalOvertimeMinutes = 0
	}

	var attendancePercentage float64
	if totalWorkingDays > 0 {
		attendancePercentage = float64(presentDays) / float64(totalWorkingDays) * 100
	}

	var punctualityPercentage float64
	if presentDays > 0 {
		punctualityPercentage = float64(presentDays-lateDays) / float64(presentDays) * 100
	}

	consistencyPercentage := s.calculateConsistency(presentDays, totalWorkingDays)
	overtimeContribution := s.calculateOvertimeContribution(totalOvertimeMinutes)

	overallScore := (attendancePercentage * 0.4) +
		(punctualityPercentage * 0.25) +
		(consistencyPercentage * 0.25) +
		(overtimeContribution * 0.1)

	return &EmployeeScore{
		EmployeeID:            employeeID,
		Month:                 month,
		Year:                  year,
		AttendancePercentage:  math.Round(attendancePercentage*100.0) / 100.0,
		PunctualityPercentage: math.Round(punctualityPercentage*100.0) / 100.0,
		ConsistencyPercentage: math.Round(consistencyPercentage*100.0) / 100.0,
		OvertimeContribution:  math.Round(overtimeContribution*100.0) / 100.0,
		OverallScore:          math.Round(overallScore*100.0) / 100.0,
		PresentDays:           int(presentDays),
		AbsentDays:            int(absentDays),
		LateDays:              int(lateDays),
		TotalWorkingHours:     math.Round((float64(totalWorkingMinutes)/60.0)*100.0) / 100.0,
		TotalOvertimeHours:    math.Round((float64(totalOvertimeMinutes)/60.0)*100.0) / 100.0,
	}, nil
}

func (s *scoreEngine) calculateWorkingDays(startDate, endDate time.Time) int {
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

func (s *scoreEngine) calculateConsistency(presentDays int64, totalWorkingDays int) float64 {
	if totalWorkingDays == 0 {
		return 0
	}

	baseConsistency := float64(presentDays) / float64(totalWorkingDays)
	if baseConsistency >= 0.95 {
		return 100
	}
	if baseConsistency >= 0.90 {
		return 95
	}
	if baseConsistency >= 0.85 {
		return 90
	}
	if baseConsistency >= 0.80 {
		return 85
	}
	if baseConsistency >= 0.75 {
		return 80
	}
	if baseConsistency >= 0.70 {
		return 75
	}

	return baseConsistency * 100
}

func (s *scoreEngine) calculateOvertimeContribution(totalOvertimeMinutes int) float64 {
	if totalOvertimeMinutes <= 0 {
		return 50
	}

	overtimeHours := float64(totalOvertimeMinutes) / 60.0
	if overtimeHours <= 10 {
		return 50 + (overtimeHours * 5)
	}
	return 100
}
