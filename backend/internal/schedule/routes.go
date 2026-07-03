package schedule

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers work schedule endpoints under /api/schedules/work-schedules.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	scheduleGroup := rg.Group("/schedules/work-schedules")
	scheduleGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		scheduleGroup.POST("", h.Create)
		scheduleGroup.GET("", h.List)
		scheduleGroup.GET("/:id", h.Get)
		scheduleGroup.GET("/employee/:employeeId", h.GetByEmployeeID)
		scheduleGroup.PUT("/:id", h.Update)
		scheduleGroup.DELETE("/:id", h.Delete)
	}
}
