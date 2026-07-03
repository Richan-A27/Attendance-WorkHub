package reports

import (
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/payroll"
)

// WeeklyReport summarizes attendance parameters for a single week.
type WeeklyReport struct {
	WeekStart                   string                `json:"weekStart"`
	WeekEnd                     string                `json:"weekEnd"`
	EmployeeStats               []EmployeeWeeklyStats `json:"employeeStats"`
	TotalEmployees              int                   `json:"totalEmployees"`
	TotalPresentDays            int                   `json:"totalPresentDays"`
	TotalAbsentDays             int                   `json:"totalAbsentDays"`
	TotalLateDays               int                   `json:"totalLateDays"`
	TotalWorkingHours           float64               `json:"totalWorkingHours"`
	TotalOvertimeHours          float64               `json:"totalOvertimeHours"`
	AverageAttendancePercentage float64               `json:"averageAttendancePercentage"`
}

// EmployeeWeeklyStats represents weekly numbers for an individual.
type EmployeeWeeklyStats struct {
	EmployeeID           uint64  `json:"employeeId"`
	EmployeeName         string  `json:"employeeName"`
	PresentDays          int     `json:"presentDays"`
	AbsentDays           int     `json:"absentDays"`
	LateDays             int     `json:"lateDays"`
	TotalWorkingHours    float64 `json:"totalWorkingHours"`
	TotalOvertimeHours   float64 `json:"totalOvertimeHours"`
	AttendancePercentage float64 `json:"attendancePercentage"`
}

// MonthlyReport consolidates attendance, payroll and performance metrics.
type MonthlyReport struct {
	Month                       int                                    `json:"month"`
	Year                        int                                    `json:"year"`
	StartDate                   string                                 `json:"startDate"`
	EndDate                     string                                 `json:"endDate"`
	AttendanceStats             []EmployeeMonthlyAttendanceStats       `json:"attendanceStats"`
	PayrollRecords              []payroll.PayrollRecord                `json:"payrollRecords"`
	TopPerformers               []intelligence.EmployeeRanking         `json:"topPerformers"`
	RankingsByOverallScore      []intelligence.EmployeeRanking         `json:"rankingsByOverallScore"`
	RankingsByAttendance        []intelligence.EmployeeRanking         `json:"rankingsByAttendance"`
	RankingsByPunctuality       []intelligence.EmployeeRanking         `json:"rankingsByPunctuality"`
	RankingsByWorkingHours      []intelligence.EmployeeRanking         `json:"rankingsByWorkingHours"`
	TotalPresentDays            int                                    `json:"totalPresentDays"`
	TotalAbsentDays             int                                    `json:"totalAbsentDays"`
	TotalLateDays               int                                    `json:"totalLateDays"`
	TotalWorkingHours           float64                                `json:"totalWorkingHours"`
	TotalOvertimeHours          float64                                `json:"totalOvertimeHours"`
	AverageAttendancePercentage float64                                `json:"averageAttendancePercentage"`
	TotalGrossPay               float64                                `json:"totalGrossPay"`
	TotalNetPay                 float64                                `json:"totalNetPay"`
	TotalDeductions             float64                                `json:"totalDeductions"`
	TotalBonuses                float64                                `json:"totalBonuses"`
}

// EmployeeMonthlyAttendanceStats holds monthly stats for an employee.
type EmployeeMonthlyAttendanceStats struct {
	EmployeeID           uint64  `json:"employeeId"`
	EmployeeName         string  `json:"employeeName"`
	PresentDays          int     `json:"presentDays"`
	AbsentDays           int     `json:"absentDays"`
	LateDays             int     `json:"lateDays"`
	TotalWorkingHours    float64 `json:"totalWorkingHours"`
	TotalOvertimeHours   float64 `json:"totalOvertimeHours"`
	AttendancePercentage float64 `json:"attendancePercentage"`
}
