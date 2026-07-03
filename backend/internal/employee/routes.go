package employee

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers the employee CRUD routes, protected by authorization guards.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	empGroup := rg.Group("/employees")
	empGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		empGroup.GET("", h.List)
		empGroup.GET("/:id", h.Get)
		empGroup.POST("", h.Create)
		empGroup.PUT("/:id", h.Update)
		empGroup.DELETE("/:id", h.Delete)
		empGroup.PATCH("/:id/hourly-rate", h.PatchHourlyRate)
		empGroup.PATCH("/:id/status", h.PatchStatus)
	}
}
