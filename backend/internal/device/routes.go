package device

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all device status endpoints under /api/device.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	deviceGroup := rg.Group("/device")
	deviceGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		deviceGroup.GET("/status", h.GetStatus)
	}
}
