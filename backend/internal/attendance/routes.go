package attendance

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes maps raw log queries under /api/attendance.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	attendanceGroup := rg.Group("/attendance")
	attendanceGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		attendanceGroup.GET("", h.List)
		attendanceGroup.GET("/recent", h.Recent)
		attendanceGroup.GET("/today", h.Today)
	}
}
