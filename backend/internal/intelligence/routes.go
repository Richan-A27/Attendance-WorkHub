package intelligence

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all intelligence calculation and rankings endpoints under their respective paths.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	// 1. Intelligence Base endpoints
	intelGroup := rg.Group("/intelligence")
	intelGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		intelGroup.POST("/sessions/process/:employeeId/:date", h.ProcessSessions)
		intelGroup.POST("/sessions/process-all/:date", h.ProcessAllSessions)
		intelGroup.POST("/daily/process/:employeeId/:date", h.ProcessDailyAttendance)
		intelGroup.POST("/daily/process-all/:date", h.ProcessAllDailyAttendance)
		intelGroup.POST("/daily/process-range", h.ProcessDateRange)

		intelGroup.GET("/daily/:employeeId/:date", h.GetDailyAttendance)
		intelGroup.GET("/daily/:employeeId/range", h.GetDailyAttendanceRange)
		intelGroup.GET("/daily/range", h.GetDailyAttendanceRangeAll)
		intelGroup.GET("/sessions/:employeeId/:date", h.GetAttendanceSessions)
		intelGroup.GET("/breaks/:employeeId/:date", h.GetAttendanceBreaks)
	}

	// 2. Rankings/Scores Base endpoints
	rankGroup := rg.Group("/rankings")
	rankGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		rankGroup.GET("/score/:employeeId/:month/:year", h.GetEmployeeScore)
		rankGroup.GET("/overall/:month/:year", h.RankByOverallScore)
		rankGroup.GET("/attendance/:month/:year", h.RankByAttendance)
		rankGroup.GET("/punctuality/:month/:year", h.RankByPunctuality)
		rankGroup.GET("/working-hours/:month/:year", h.RankByWorkingHours)
		rankGroup.GET("/top-performers/:month/:year", h.GetTopPerformers)
	}
}
