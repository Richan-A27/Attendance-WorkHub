package payperiod

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all pay period management endpoints under /api/pay-periods.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	ppGroup := rg.Group("/pay-periods")
	ppGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		ppGroup.POST("", h.CreatePayPeriod)
		ppGroup.GET("", h.ListPayPeriods)
		ppGroup.GET("/open", h.GetOpenPeriods)
		ppGroup.GET("/:id", h.GetPayPeriod)
		ppGroup.PUT("/:id/status", h.UpdatePeriodStatus)
		ppGroup.DELETE("/:id", h.DeletePayPeriod)
	}
}
