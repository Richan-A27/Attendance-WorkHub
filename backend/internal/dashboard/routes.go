package dashboard

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all dashboard analytics endpoints under /api/dashboard.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	dashboardGroup := rg.Group("/dashboard")
	dashboardGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		dashboardGroup.GET("", h.GetSummary)
	}
}
