package intelligence

import (
	"time"
)

// AttendanceSession represents aggregated punches forming a session of activity.
type AttendanceSession struct {
	ID              uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID      uint64     `gorm:"not null;column:employee_id" json:"employeeId"`
	SessionDate     string     `gorm:"not null;column:session_date;type:date" json:"sessionDate"`
	SessionNumber   int        `gorm:"not null;column:session_number" json:"sessionNumber"`
	PunchIn         time.Time  `gorm:"not null;column:punch_in" json:"punchIn"`
	PunchOut        *time.Time `gorm:"column:punch_out" json:"punchOut"`
	DurationMinutes int        `gorm:"column:duration_minutes" json:"durationMinutes"`
	IsLunchBreak    bool       `gorm:"column:is_lunch_break;default:false" json:"isLunchBreak"`
	CreatedAt       time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
}

// TableName overrides GORM's default naming behavior to "attendance_sessions".
func (AttendanceSession) TableName() string {
	return "attendance_sessions"
}

// AttendanceBreak represents periods of clock-out/in breaks during a shift.
type AttendanceBreak struct {
	ID             uint64    `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID     uint64    `gorm:"not null;column:employee_id" json:"employeeId"`
	AttendanceDate string    `gorm:"not null;column:attendance_date;type:date" json:"attendanceDate"`
	BreakNumber    int       `gorm:"not null;column:break_number" json:"breakNumber"`
	BreakStart     time.Time `gorm:"not null;column:break_start" json:"breakStart"`
	BreakEnd       time.Time `gorm:"not null;column:break_end" json:"breakEnd"`
	DurationMinutes int       `gorm:"column:duration_minutes" json:"durationMinutes"`
	CreatedAt      time.Time `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
}

// TableName overrides GORM's default naming behavior to "attendance_breaks".
func (AttendanceBreak) TableName() string {
	return "attendance_breaks"
}

// DailyAttendance stores the final parsed metrics, overtime, status and totals for each date.
type DailyAttendance struct {
	ID                    uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	EmployeeID            uint64     `gorm:"not null;column:employee_id" json:"employeeId"`
	AttendanceDate        string     `gorm:"not null;column:attendance_date;type:date" json:"attendanceDate"`
	FirstPunch            *time.Time `gorm:"column:first_punch" json:"firstPunch"`
	LastPunch             *time.Time `gorm:"column:last_punch" json:"lastPunch"`
	TotalWorkingMinutes   int        `gorm:"column:total_working_minutes;default:0" json:"totalWorkingMinutes"`
	BreakDurationMinutes  int        `gorm:"column:break_duration_minutes;default:0" json:"breakDurationMinutes"`
	LunchDurationMinutes  int        `gorm:"column:lunch_duration_minutes;default:0" json:"lunchDurationMinutes"`
	TotalMinutes          int        `gorm:"column:total_minutes;default:0" json:"totalMinutes"`
	WorkingMinutes        int        `gorm:"column:working_minutes;default:0" json:"workingMinutes"`
	BreakMinutes          int        `gorm:"column:break_minutes;default:0" json:"breakMinutes"`
	Status                string     `gorm:"column:status;default:'ABSENT'" json:"status"`
	IsLate                bool       `gorm:"column:is_late;default:false" json:"isLate"`
	LateMinutes           int        `gorm:"column:late_minutes;default:0" json:"lateMinutes"`
	IsEarlyDeparture      bool       `gorm:"column:is_early_departure;default:false" json:"isEarlyDeparture"`
	EarlyDepartureMinutes int        `gorm:"column:early_departure_minutes;default:0" json:"earlyDepartureMinutes"`
	OvertimeMinutes       int        `gorm:"column:overtime_minutes;default:0" json:"overtimeMinutes"`
	ScheduledWorkMinutes  int        `gorm:"column:scheduled_work_minutes;default:0" json:"scheduledWorkMinutes"`
	WorkScheduleID        *uint64    `gorm:"column:work_schedule_id" json:"workScheduleId"`
	CreatedAt             time.Time  `gorm:"column:created_at;autoCreateTime" json:"createdAt"`
	UpdatedAt             time.Time  `gorm:"column:updated_at;autoUpdateTime" json:"updatedAt"`
}

// TableName overrides GORM's default naming behavior to "daily_attendance".
func (DailyAttendance) TableName() string {
	return "daily_attendance"
}

// EmployeeScore represents monthly performance score calculations.
type EmployeeScore struct {
	EmployeeID            uint64  `json:"employeeId"`
	Month                 int     `json:"month"`
	Year                  int     `json:"year"`
	AttendancePercentage  float64 `json:"attendancePercentage"`
	PunctualityPercentage float64 `json:"punctualityPercentage"`
	ConsistencyPercentage float64 `json:"consistencyPercentage"`
	OvertimeContribution  float64 `json:"overtimeContribution"`
	OverallScore          float64 `json:"overallScore"`
	PresentDays           int     `json:"presentDays"`
	AbsentDays            int     `json:"absentDays"`
	LateDays              int     `json:"lateDays"`
	TotalWorkingHours     float64 `json:"totalWorkingHours"`
	TotalOvertimeHours    float64 `json:"totalOvertimeHours"`
}

// EmployeeRanking represents a ranked employee performance record.
type EmployeeRanking struct {
	Rank         int            `json:"rank"`
	EmployeeID   uint64         `json:"employeeId"`
	EmployeeName string         `json:"employeeName"`
	Score        *EmployeeScore `json:"score"`
}
