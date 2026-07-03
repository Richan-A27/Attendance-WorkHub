package intelligence

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
)

// Handler processes attendance intelligence and ranking requests.
type Handler struct {
	sessionEngine  SessionEngine
	dailyProcessor DailyProcessor
	scoreEngine    ScoreEngine
	rankingSvc     RankingService
	repo           Repository
}

// NewHandler creates a new Handler instance.
func NewHandler(se SessionEngine, dp DailyProcessor, se2 ScoreEngine, rs RankingService, repo Repository) *Handler {
	return &Handler{
		sessionEngine:  se,
		dailyProcessor: dp,
		scoreEngine:    se2,
		rankingSvc:     rs,
		repo:           repo,
	}
}

// ProcessSessions reprocesses biometric logs into sessions for a specific employee and date.
func (h *Handler) ProcessSessions(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	date := c.Param("date")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	sessions, err := h.sessionEngine.ProcessAttendanceSessions(c.Request.Context(), empID, date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sessions)
}

// ProcessAllSessions processes sessions for all active employees for a date.
func (h *Handler) ProcessAllSessions(c *gin.Context) {
	date := c.Param("date")

	err := h.sessionEngine.ProcessAllSessionsForDate(c.Request.Context(), date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.String(http.StatusOK, "Attendance sessions processed for date: "+date)
}

// ProcessDailyAttendance processes shift status for an employee.
func (h *Handler) ProcessDailyAttendance(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	date := c.Param("date")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	da, err := h.dailyProcessor.ProcessDailyAttendance(c.Request.Context(), empID, date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, da)
}

// ProcessAllDailyAttendance processes shift statuses for all employees on a date.
func (h *Handler) ProcessAllDailyAttendance(c *gin.Context) {
	date := c.Param("date")

	err := h.dailyProcessor.ProcessAllAttendanceForDate(c.Request.Context(), date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.String(http.StatusOK, "Daily attendance processed for date: "+date)
}

// ProcessDateRange processes daily attendance within a date span.
func (h *Handler) ProcessDateRange(c *gin.Context) {
	startDate := c.Query("startDate")
	endDate := c.Query("endDate")

	if startDate == "" || endDate == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Missing startDate or endDate parameters"})
		return
	}

	err := h.dailyProcessor.ProcessDateRange(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.String(http.StatusOK, "Daily attendance processed for range: "+startDate+" to "+endDate)
}

// GetDailyAttendance retrieves daily attendance for a single day.
func (h *Handler) GetDailyAttendance(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	date := c.Param("date")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	da, err := h.repo.FindByEmployeeIDAndDate(c.Request.Context(), empID, date)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Attendance record not found"})
		return
	}

	c.JSON(http.StatusOK, da)
}

// GetDailyAttendanceRange retrieves records for a single employee in a range.
func (h *Handler) GetDailyAttendanceRange(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	startDate := c.Query("startDate")
	endDate := c.Query("endDate")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	attendanceRange, err := h.repo.FindByEmployeeIDAndDateRange(c.Request.Context(), empID, startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, attendanceRange)
}

// GetDailyAttendanceRangeAll retrieves records for all employees in a range.
func (h *Handler) GetDailyAttendanceRangeAll(c *gin.Context) {
	startDate := c.Query("startDate")
	endDate := c.Query("endDate")

	attendanceRange, err := h.repo.FindByDateRange(c.Request.Context(), startDate, endDate)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, attendanceRange)
}

// GetAttendanceSessions returns work session records for an employee and date.
func (h *Handler) GetAttendanceSessions(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	date := c.Param("date")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	sessions, err := h.repo.FindSessions(c.Request.Context(), empID, date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sessions)
}

// GetAttendanceBreaks returns break records.
func (h *Handler) GetAttendanceBreaks(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	date := c.Param("date")

	empID, err := strconv.ParseUint(empIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid employee ID"})
		return
	}

	breaks, err := h.repo.FindBreaks(c.Request.Context(), empID, date)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, breaks)
}

// GetEmployeeScore calculates performance score card for a month.
func (h *Handler) GetEmployeeScore(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	score, err := h.scoreEngine.CalculateEmployeeScore(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, score)
}

// RankByOverallScore returns rankings by weighted overall score.
func (h *Handler) RankByOverallScore(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	rankings, err := h.rankingSvc.RankEmployeesByOverallScore(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rankings)
}

// RankByAttendance returns rankings by attendance.
func (h *Handler) RankByAttendance(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	rankings, err := h.rankingSvc.RankEmployeesByAttendance(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rankings)
}

// RankByPunctuality returns rankings by punctuality.
func (h *Handler) RankByPunctuality(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	rankings, err := h.rankingSvc.RankEmployeesByPunctuality(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rankings)
}

// RankByWorkingHours returns rankings by duration.
func (h *Handler) RankByWorkingHours(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	rankings, err := h.rankingSvc.RankEmployeesByWorkingHours(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rankings)
}

// GetTopPerformers returns top performed staff lists.
func (h *Handler) GetTopPerformers(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")
	limitStr := c.DefaultQuery("limit", "10")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)
	limit, _ := strconv.Atoi(limitStr)

	rankings, err := h.rankingSvc.GetTopPerformers(c.Request.Context(), month, year, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, rankings)
}
