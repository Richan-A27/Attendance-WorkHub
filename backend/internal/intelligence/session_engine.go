package intelligence

import (
	"context"
	"math"
	"strconv"
	"strings"
	"time"
	"com.isravel.workhub/internal/attendance"
	"com.isravel.workhub/internal/schedule"
	"com.isravel.workhub/internal/settings"
)

// SessionEngine groups raw punches into work sessions and break records.
type SessionEngine interface {
	ProcessAttendanceSessions(ctx context.Context, employeeID uint64, date string) ([]AttendanceSession, error)
	ProcessAllSessionsForDate(ctx context.Context, date string) error
}

type sessionEngine struct {
	repo         Repository
	punchRepo    attendance.Repository
	scheduleRepo schedule.Repository
	settingsRepo settings.Repository
}

// NewSessionEngine creates a new SessionEngine instance.
func NewSessionEngine(repo Repository, punchRepo attendance.Repository, scheduleRepo schedule.Repository, settingsRepo settings.Repository) SessionEngine {
	return &sessionEngine{
		repo:         repo,
		punchRepo:    punchRepo,
		scheduleRepo: scheduleRepo,
		settingsRepo: settingsRepo,
	}
}

func (s *sessionEngine) ProcessAttendanceSessions(ctx context.Context, employeeID uint64, date string) ([]AttendanceSession, error) {
	dayBoundary := "06:00:00"
	profile, err := s.settingsRepo.FindFirst(ctx)
	if err == nil && profile.DayBoundary != "" {
		dayBoundary = profile.DayBoundary
	}

	loc, _ := time.LoadLocation("Asia/Kolkata")
	parsedDate, err := time.ParseInLocation("2006-01-02", date, loc)
	if err != nil {
		return nil, err
	}

	boundaryHour := 6
	boundaryMinute := 0
	parts := strings.Split(dayBoundary, ":")
	if len(parts) >= 2 {
		boundaryHour, _ = strconv.Atoi(parts[0])
		boundaryMinute, _ = strconv.Atoi(parts[1])
	}

	startOfDay := time.Date(parsedDate.Year(), parsedDate.Month(), parsedDate.Day(), boundaryHour, boundaryMinute, 0, 0, loc)
	endOfDay := startOfDay.AddDate(0, 0, 1).Add(-time.Nanosecond)

	// Fetch punches from 3 days before to 1 day after to ensure proper boundary chronological pairing
	queryStart := startOfDay.AddDate(0, 0, -3)
	queryEnd := endOfDay.Add(24 * time.Hour)

	punches, err := s.punchRepo.FindByEmployeeIDAndDateRange(ctx, employeeID, queryStart, queryEnd)
	if err != nil {
		return nil, err
	}

	if len(punches) == 0 {
		_ = s.repo.DeleteSessions(ctx, employeeID, date)
		_ = s.repo.DeleteBreaks(ctx, employeeID, date)
		return []AttendanceSession{}, nil
	}

	lunchDuration := 45
	ws, err := s.scheduleRepo.FindActiveByEmployeeID(ctx, employeeID)
	if err == nil && ws.LunchDurationMinutes > 0 {
		lunchDuration = ws.LunchDurationMinutes
	}

	var allSessions []AttendanceSession
	for i := 0; i < len(punches); i += 2 {
		punchIn := punches[i]
		var punchOut *attendance.AttendanceLog
		if i+1 < len(punches) {
			punchOut = &punches[i+1]
		}

		session := AttendanceSession{
			EmployeeID:  employeeID,
			PunchIn:     punchIn.PunchTime,
			CreatedAt:   time.Now(),
		}

		if punchOut != nil {
			poTime := punchOut.PunchTime
			session.PunchOut = &poTime
			duration := int(poTime.Sub(punchIn.PunchTime).Minutes())
			session.DurationMinutes = duration

			if isLunchBreak(punchIn.PunchTime, poTime, lunchDuration) {
				session.IsLunchBreak = true
			}
		}

		allSessions = append(allSessions, session)
	}

	// Filter sessions whose PunchIn belongs to the target date's boundary
	var sessions []AttendanceSession
	sessionIndex := 1
	for _, sess := range allSessions {
		// Include if PunchIn falls strictly within startOfDay and endOfDay
		if (sess.PunchIn.Equal(startOfDay) || sess.PunchIn.After(startOfDay)) && sess.PunchIn.Before(endOfDay.Add(time.Nanosecond)) {
			sess.SessionDate = date
			sess.SessionNumber = sessionIndex
			sessionIndex++
			sessions = append(sessions, sess)
		}
	}

	err = s.repo.DeleteSessions(ctx, employeeID, date)
	if err != nil {
		return nil, err
	}
	err = s.repo.DeleteBreaks(ctx, employeeID, date)
	if err != nil {
		return nil, err
	}

	var savedSessions []AttendanceSession
	for i := range sessions {
		err = s.repo.SaveSession(ctx, &sessions[i])
		if err != nil {
			return nil, err
		}
		savedSessions = append(savedSessions, sessions[i])
	}

	var breaks []AttendanceBreak
	for i := 0; i < len(savedSessions)-1; i++ {
		curr := savedSessions[i]
		nxt := savedSessions[i+1]
		if curr.PunchOut != nil {
			b := AttendanceBreak{
				EmployeeID:      employeeID,
				AttendanceDate:  date,
				BreakNumber:     i + 1,
				BreakStart:      *curr.PunchOut,
				BreakEnd:        nxt.PunchIn,
				DurationMinutes: int(nxt.PunchIn.Sub(*curr.PunchOut).Minutes()),
				CreatedAt:       time.Now(),
			}
			breaks = append(breaks, b)
		}
	}

	for i := range breaks {
		err = s.repo.SaveBreak(ctx, &breaks[i])
		if err != nil {
			return nil, err
		}
	}

	return savedSessions, nil
}

func (s *sessionEngine) ProcessAllSessionsForDate(ctx context.Context, date string) error {
	dayBoundary := "06:00:00"
	profile, err := s.settingsRepo.FindFirst(ctx)
	if err == nil && profile.DayBoundary != "" {
		dayBoundary = profile.DayBoundary
	}

	loc, _ := time.LoadLocation("Asia/Kolkata")
	parsedDate, err := time.ParseInLocation("2006-01-02", date, loc)
	if err != nil {
		return err
	}

	boundaryHour := 6
	boundaryMinute := 0
	parts := strings.Split(dayBoundary, ":")
	if len(parts) >= 2 {
		boundaryHour, _ = strconv.Atoi(parts[0])
		boundaryMinute, _ = strconv.Atoi(parts[1])
	}

	startOfDay := time.Date(parsedDate.Year(), parsedDate.Month(), parsedDate.Day(), boundaryHour, boundaryMinute, 0, 0, loc)
	endOfDay := startOfDay.AddDate(0, 0, 1).Add(-time.Nanosecond)

	employeeIDs, err := s.punchRepo.FindDistinctEmployeeIDs(ctx, startOfDay, endOfDay)
	if err != nil {
		return err
	}

	for _, empID := range employeeIDs {
		_, _ = s.ProcessAttendanceSessions(ctx, empID, date)
	}

	return nil
}

func isLunchBreak(punchIn, punchOut time.Time, expectedDuration int) bool {
	inTime := punchIn.Format("15:04:05")
	outTime := punchOut.Format("15:04:05")

	lunchStart := "11:30:00"
	lunchEnd := "14:30:00"

	inLunch := inTime >= lunchStart && inTime <= lunchEnd
	outLunch := outTime >= lunchStart && outTime <= lunchEnd

	actualDuration := int(punchOut.Sub(punchIn).Minutes())
	durationMatches := math.Abs(float64(actualDuration-expectedDuration)) <= 15

	return inLunch && outLunch && durationMatches
}
