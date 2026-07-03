package operations

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes maps operational diagnostics and health check endpoints.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	operationsGroup := rg.Group("/operations")
	operationsGroup.Use(auth.RequireRole(authSvc, "ADMIN"))
	{
		operationsGroup.GET("/device-status", h.GetDeviceStatus)
		operationsGroup.GET("/sync-history", h.GetSyncHistory)
		operationsGroup.GET("/sync-statistics", h.GetSyncStatistics)
		operationsGroup.POST("/manual-sync", h.TriggerManualSync)
		operationsGroup.GET("/diagnostics", h.GetDiagnostics)
	}

	systemHealthGroup := rg.Group("/system-health")
	systemHealthGroup.Use(auth.RequireRole(authSvc, "ADMIN"))
	{
		systemHealthGroup.GET("", h.GetSystemHealth)
	}
}
