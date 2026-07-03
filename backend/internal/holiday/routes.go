package holiday

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers holiday endpoints under /api/schedules/holidays.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	holidayGroup := rg.Group("/schedules/holidays")
	holidayGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		holidayGroup.POST("", h.Create)
		holidayGroup.GET("", h.List)
		holidayGroup.GET("/range", h.ListRange)
		holidayGroup.GET("/:id", h.Get)
		holidayGroup.GET("/date/:date", h.GetByDate)
		holidayGroup.PUT("/:id", h.Update)
		holidayGroup.DELETE("/:id", h.Delete)
	}
}
