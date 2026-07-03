package settings

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers the settings routes under the Gin group.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	settingsGroup := rg.Group("/settings/company-profile")
	settingsGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		settingsGroup.GET("", h.Get)
		settingsGroup.POST("", h.Save)
	}
}
