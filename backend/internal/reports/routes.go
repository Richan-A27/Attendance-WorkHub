package reports

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all report endpoints under /api/reports.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	reportsGroup := rg.Group("/reports")
	reportsGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		reportsGroup.GET("/weekly/:date", h.GetWeeklyReport)
		reportsGroup.GET("/weekly/current", h.GetCurrentWeekReport)
		reportsGroup.GET("/monthly/:month/:year", h.GetMonthlyReport)
		reportsGroup.GET("/monthly/current", h.GetCurrentMonthReport)
	}
}
