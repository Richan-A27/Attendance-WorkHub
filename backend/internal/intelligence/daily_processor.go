package intelligence

import (
	"context"
	"errors"
	"strconv"
	"strings"
	"time"
	"com.isravel.workhub/internal/attendance"
	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/holiday"
	"com.isravel.workhub/internal/schedule"
	"com.isravel.workhub/internal/settings"
)

// DailyProcessor analyzes raw scans, sessions, breaks and updates shift status records.
type DailyProcessor interface {
	ProcessDailyAttendance(ctx context.Context, employeeID uint64, date string) (*DailyAttendance, error)
	ProcessAllAttendanceForDate(ctx context.Context, date string) error
	ProcessDateRange(ctx context.Context, startDate, endDate string) error
}

type dailyProcessor struct {
	repo         Repository
	punchRepo    attendance.Repository
	employeeRepo employee.Repository
	holidayRepo  holiday.Repository
	scheduleRepo schedule.Repository
	settingsRepo settings.Repository
}

// NewDailyProcessor creates a new DailyProcessor instance.
func NewDailyProcessor(repo Repository, punchRepo attendance.Repository, employeeRepo employee.Repository, holidayRepo holiday.Repository, scheduleRepo schedule.Repository, settingsRepo settings.Repository) DailyProcessor {
	return &dailyProcessor{
		repo:         repo,
		punchRepo:    punchRepo,
		employeeRepo: employeeRepo,
		holidayRepo:  holidayRepo,
		scheduleRepo: scheduleRepo,
		settingsRepo: settingsRepo,
	}
}

func (dp *dailyProcessor) ProcessDailyAttendance(ctx context.Context, employeeID uint64, date string) (*DailyAttendance, error) {
	loc, _ := time.LoadLocation("Asia/Kolkata")
	parsedDate, err := time.ParseInLocation("2006-01-02", date, loc)
	if err != nil {
		return nil, err
	}

	dayBoundary := "06:00:00"
	profile, err := dp.settingsRepo.FindFirst(ctx)
	if err == nil && profile.DayBoundary != "" {
		dayBoundary = profile.DayBoundary
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

	punches, err := dp.punchRepo.FindByEmployeeIDAndDateRange(ctx, employeeID, startOfDay, endOfDay)
	if err != nil {
		return nil, err
	}

	// If no punches recorded, check if it's a holiday or weekend to assign correct empty status
	if len(punches) == 0 {
		h, err := dp.holidayRepo.FindHolidayForDate(ctx, date)
		if err == nil && h != nil {
			return dp.createHolidayAttendance(ctx, employeeID, date, h.Name)
		}

		weekday := parsedDate.Weekday()
		if weekday == time.Saturday || weekday == time.Sunday {
			return dp.createWeekendAttendance(ctx, employeeID, date)
		}
	}

	ws, err := dp.scheduleRepo.FindActiveByEmployeeID(ctx, employeeID)
	var scheduleID *uint64
	if err == nil && ws != nil {
		idVal := ws.ID
		scheduleID = &idVal
	}

	sessions, err := dp.repo.FindSessions(ctx, employeeID, date)
	if err != nil {
		return nil, err
	}

	breaks, err := dp.repo.FindBreaks(ctx, employeeID, date)
	if err != nil {
		return nil, err
	}

	da, err := dp.repo.FindByEmployeeIDAndDate(ctx, employeeID, date)
	if err != nil {
		da = &DailyAttendance{}
	}

	da.EmployeeID = employeeID
	da.AttendanceDate = date
	da.WorkScheduleID = scheduleID

	if len(punches) == 0 {
		da.Status = "ABSENT"
		da.FirstPunch = nil
		da.LastPunch = nil
		da.TotalWorkingMinutes = 0
		da.WorkingMinutes = 0
		da.BreakMinutes = 0
		da.BreakDurationMinutes = 0
		da.TotalMinutes = 0
		da.OvertimeMinutes = 0
		da.IsLate = false
		da.LateMinutes = 0
		da.IsEarlyDeparture = false
		da.EarlyDepartureMinutes = 0
	} else {
		dp.processPunches(da, punches, sessions, breaks, ws)
	}

	if ws != nil {
		da.ScheduledWorkMinutes = dp.calculateScheduledWorkMinutes(ws, parsedDate)
	} else {
		da.ScheduledWorkMinutes = 0
	}

	dp.calculateOvertime(da)
	dp.determineAttendanceStatus(da, ws)

	da.UpdatedAt = time.Now()
	if da.CreatedAt.IsZero() {
		da.CreatedAt = time.Now()
	}

	err = dp.repo.SaveDailyAttendance(ctx, da)
	if err != nil {
		return nil, err
	}

	return da, nil
}

func (dp *dailyProcessor) processPunches(da *DailyAttendance, punches []attendance.AttendanceLog, sessions []AttendanceSession, breaks []AttendanceBreak, ws *schedule.WorkSchedule) {
	if len(sessions) == 0 {
		return
	}

	first := sessions[0].PunchIn
	da.FirstPunch = &first

	lastSession := sessions[len(sessions)-1]
	if lastSession.PunchOut != nil {
		outVal := *lastSession.PunchOut
		da.LastPunch = &outVal
	} else {
		da.LastPunch = nil
	}

	totalWorking := 0
	for _, s := range sessions {
		totalWorking += s.DurationMinutes
	}

	totalBreak := 0
	for _, b := range breaks {
		totalBreak += b.DurationMinutes
	}

	da.WorkingMinutes = totalWorking
	da.TotalWorkingMinutes = totalWorking
	da.BreakMinutes = totalBreak
	da.BreakDurationMinutes = totalBreak

	if da.FirstPunch != nil && da.LastPunch != nil {
		da.TotalMinutes = int((*da.LastPunch).Sub(*da.FirstPunch).Minutes())
	} else {
		da.TotalMinutes = 0
	}

	if ws != nil && da.FirstPunch != nil {
		dp.detectLateArrival(da, ws)
	} else {
		da.IsLate = false
		da.LateMinutes = 0
	}

	if ws != nil && da.LastPunch != nil {
		dp.detectEarlyDeparture(da, ws)
	} else {
		da.IsEarlyDeparture = false
		da.EarlyDepartureMinutes = 0
	}
}

func (dp *dailyProcessor) detectLateArrival(da *DailyAttendance, ws *schedule.WorkSchedule) {
	firstPunchTime := da.FirstPunch.Format("15:04:05")
	shiftStart := ws.StartTime

	layout := "15:04:05"
	parsedPunch, err1 := time.Parse(layout, firstPunchTime)
	parsedShift, err2 := time.Parse(layout, shiftStart)

	if err1 == nil && err2 == nil {
		allowedArrival := parsedShift.Add(time.Duration(ws.GracePeriodMinutes) * time.Minute)
		if parsedPunch.After(allowedArrival) {
			da.IsLate = true
			da.LateMinutes = int(parsedPunch.Sub(parsedShift).Minutes())
		} else {
			da.IsLate = false
			da.LateMinutes = 0
		}
	}
}

func (dp *dailyProcessor) detectEarlyDeparture(da *DailyAttendance, ws *schedule.WorkSchedule) {
	lastPunchTime := da.LastPunch.Format("15:04:05")
	shiftEnd := ws.EndTime

	layout := "15:04:05"
	parsedPunch, err1 := time.Parse(layout, lastPunchTime)
	parsedShift, err2 := time.Parse(layout, shiftEnd)

	if err1 == nil && err2 == nil {
		earlyLimit := parsedShift.Add(-15 * time.Minute)
		if parsedPunch.Before(earlyLimit) {
			da.IsEarlyDeparture = true
			da.EarlyDepartureMinutes = int(parsedShift.Sub(parsedPunch).Minutes())
		} else {
			da.IsEarlyDeparture = false
			da.EarlyDepartureMinutes = 0
		}
	}
}

func (dp *dailyProcessor) calculateScheduledWorkMinutes(ws *schedule.WorkSchedule, date time.Time) int {
	if ws.StartTime == "" || ws.EndTime == "" {
		return 0
	}

	// Check if this date is a holiday
	h, err := dp.holidayRepo.FindHolidayForDate(context.Background(), date.Format("2006-01-02"))
	if err == nil && h != nil {
		return 0 // Holidays have 0 scheduled minutes
	}

	dayName := strings.ToUpper(date.Weekday().String())
	isWorkDay := false
	if len(ws.WorkDays) == 0 {
		weekday := date.Weekday()
		if weekday != time.Saturday && weekday != time.Sunday {
			isWorkDay = true
		}
	} else {
		for _, wd := range ws.WorkDays {
			if strings.ToUpper(wd) == dayName {
				isWorkDay = true
				break
			}
		}
	}

	if !isWorkDay {
		return 0
	}

	layout := "15:04:05"
	t1, err1 := time.Parse(layout, ws.StartTime)
	t2, err2 := time.Parse(layout, ws.EndTime)

	if err1 == nil && err2 == nil {
		diff := int(t2.Sub(t1).Minutes())
		lunch := ws.LunchDurationMinutes
		if lunch <= 0 {
			lunch = 45
		}
		res := diff - lunch
		if res < 0 {
			return 0
		}
		return res
	}

	return 0
}

func (dp *dailyProcessor) calculateOvertime(da *DailyAttendance) {
	if da.ScheduledWorkMinutes > 0 {
		overtime := da.TotalWorkingMinutes - da.ScheduledWorkMinutes
		if overtime > 0 {
			da.OvertimeMinutes = overtime
		} else {
			da.OvertimeMinutes = 0
		}
	} else {
		da.OvertimeMinutes = 0
	}
}

func (dp *dailyProcessor) determineAttendanceStatus(da *DailyAttendance, ws *schedule.WorkSchedule) {
	if da.FirstPunch == nil {
		da.Status = "ABSENT"
		return
	}

	if da.LastPunch == nil {
		da.Status = "INCOMPLETE"
		return
	}

	// Check if this date is a holiday
	h, err := dp.holidayRepo.FindHolidayForDate(context.Background(), da.AttendanceDate)
	if err == nil && h != nil {
		da.Status = "HOLIDAY"
		return
	}

	// Check if this date is a weekend
	loc, _ := time.LoadLocation("Asia/Kolkata")
	parsedDate, err := time.ParseInLocation("2006-01-02", da.AttendanceDate, loc)
	if err == nil {
		weekday := parsedDate.Weekday()
		if weekday == time.Saturday || weekday == time.Sunday {
			da.Status = "WEEKEND"
			return
		}
	}

	if ws != nil && da.ScheduledWorkMinutes > 0 {
		ratio := float64(da.TotalWorkingMinutes) / float64(da.ScheduledWorkMinutes)
		if ratio < 0.5 {
			da.Status = "HALF_DAY"
			return
		}
	}

	if da.IsLate {
		da.Status = "LATE"
		return
	}

	da.Status = "PRESENT"
}

func (dp *dailyProcessor) createHolidayAttendance(ctx context.Context, employeeID uint64, date string, holidayName string) (*DailyAttendance, error) {
	da, err := dp.repo.FindByEmployeeIDAndDate(ctx, employeeID, date)
	if err != nil {
		da = &DailyAttendance{}
	}

	da.EmployeeID = employeeID
	da.AttendanceDate = date
	da.Status = "HOLIDAY"
	da.FirstPunch = nil
	da.LastPunch = nil
	da.TotalWorkingMinutes = 0
	da.WorkingMinutes = 0
	da.BreakMinutes = 0
	da.BreakDurationMinutes = 0
	da.TotalMinutes = 0
	da.OvertimeMinutes = 0
	da.IsLate = false
	da.LateMinutes = 0
	da.IsEarlyDeparture = false
	da.EarlyDepartureMinutes = 0
	da.UpdatedAt = time.Now()
	if da.CreatedAt.IsZero() {
		da.CreatedAt = time.Now()
	}

	err = dp.repo.SaveDailyAttendance(ctx, da)
	if err != nil {
		return nil, err
	}
	return da, nil
}

func (dp *dailyProcessor) createWeekendAttendance(ctx context.Context, employeeID uint64, date string) (*DailyAttendance, error) {
	da, err := dp.repo.FindByEmployeeIDAndDate(ctx, employeeID, date)
	if err != nil {
		da = &DailyAttendance{}
	}

	da.EmployeeID = employeeID
	da.AttendanceDate = date
	da.Status = "WEEKEND"
	da.FirstPunch = nil
	da.LastPunch = nil
	da.TotalWorkingMinutes = 0
	da.WorkingMinutes = 0
	da.BreakMinutes = 0
	da.BreakDurationMinutes = 0
	da.TotalMinutes = 0
	da.OvertimeMinutes = 0
	da.IsLate = false
	da.LateMinutes = 0
	da.IsEarlyDeparture = false
	da.EarlyDepartureMinutes = 0
	da.UpdatedAt = time.Now()
	if da.CreatedAt.IsZero() {
		da.CreatedAt = time.Now()
	}

	err = dp.repo.SaveDailyAttendance(ctx, da)
	if err != nil {
		return nil, err
	}
	return da, nil
}

func (dp *dailyProcessor) ProcessAllAttendanceForDate(ctx context.Context, date string) error {
	activeEmps, err := dp.employeeRepo.FindAll(ctx)
	if err != nil {
		return err
	}

	for _, emp := range activeEmps {
		if emp.Active {
			_, _ = dp.ProcessDailyAttendance(ctx, emp.ID, date)
		}
	}

	return nil
}

func (dp *dailyProcessor) ProcessDateRange(ctx context.Context, startDate, endDate string) error {
	loc, _ := time.LoadLocation("Asia/Kolkata")
	start, err1 := time.ParseInLocation("2006-01-02", startDate, loc)
	end, err2 := time.ParseInLocation("2006-01-02", endDate, loc)

	if err1 != nil || err2 != nil {
		return errors.New("invalid date range format")
	}

	curr := start
	for !curr.After(end) {
		dateStr := curr.Format("2006-01-02")
		_ = dp.ProcessAllAttendanceForDate(ctx, dateStr)
		curr = curr.AddDate(0, 0, 1)
	}

	return nil
}
