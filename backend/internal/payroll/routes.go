package payroll

import (
	"com.isravel.workhub/internal/auth"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers all monthly payroll processing endpoints under /api/payroll.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, authSvc auth.Service) {
	payrollGroup := rg.Group("/payroll")
	payrollGroup.Use(auth.RequireRole(authSvc, "ADMIN", "MANAGER"))
	{
		payrollGroup.POST("/calculate/:employeeId/:month/:year", h.CalculatePayroll)
		payrollGroup.POST("/calculate-all/:month/:year", h.CalculateAllPayroll)
		payrollGroup.GET("/employee/:employeeId/:month/:year", h.GetEmployeePayroll)
		payrollGroup.GET("/month/:month/:year", h.GetMonthlyPayroll)
		payrollGroup.GET("/employee/:employeeId", h.GetEmployeePayrollHistory)
		payrollGroup.PUT("/deductions/:employeeId/:month/:year", h.UpdateDeductions)
		payrollGroup.PUT("/bonuses/:employeeId/:month/:year", h.UpdateBonuses)
		payrollGroup.POST("/process/:employeeId/:month/:year", h.ProcessPayroll)
		payrollGroup.POST("/process-all/:month/:year", h.ProcessAllPayroll)
		payrollGroup.GET("/summary/:month/:year", h.GetPayrollSummary)
	}
}
