package payroll

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
)

// Handler processes HTTP request operations for payroll calculations and aggregates.
type Handler struct {
	svc  Service
	repo Repository
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service, repo Repository) *Handler {
	return &Handler{
		svc:  svc,
		repo: repo,
	}
}

// CalculatePayroll calculates monthly payroll for a single employee.
func (h *Handler) CalculatePayroll(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	record, err := h.svc.CalculateMonthlyPayroll(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, record)
}

// CalculateAllPayroll calculates monthly payroll for all active employees.
func (h *Handler) CalculateAllPayroll(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	records, err := h.svc.CalculatePayrollForAllEmployees(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, records)
}

// GetEmployeePayroll returns a single employee's calculated payroll record.
func (h *Handler) GetEmployeePayroll(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	record, err := h.repo.FindByEmployeeIDAndMonthAndYear(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Payroll record not found"})
		return
	}

	c.JSON(http.StatusOK, record)
}

// GetMonthlyPayroll returns all records for a month.
func (h *Handler) GetMonthlyPayroll(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	records, err := h.repo.FindByMonthAndYear(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, records)
}

// GetEmployeePayrollHistory returns historical payroll summaries for an employee.
func (h *Handler) GetEmployeePayrollHistory(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	empID, _ := strconv.ParseUint(empIDStr, 10, 64)

	records, err := h.repo.FindEmployeePayrollHistory(c.Request.Context(), empID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, records)
}

// UpdateDeductions updates deductions values.
func (h *Handler) UpdateDeductions(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")
	deductionsStr := c.Query("deductions")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)
	deductions, _ := strconv.ParseFloat(deductionsStr, 64)

	record, err := h.svc.UpdatePayrollDeductions(c.Request.Context(), empID, month, year, deductions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, record)
}

// UpdateBonuses updates bonuses values.
func (h *Handler) UpdateBonuses(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")
	bonusesStr := c.Query("bonuses")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)
	bonuses, _ := strconv.ParseFloat(bonusesStr, 64)

	record, err := h.svc.UpdatePayrollBonuses(c.Request.Context(), empID, month, year, bonuses)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, record)
}

// ProcessPayroll signs and approves a monthly record.
func (h *Handler) ProcessPayroll(c *gin.Context) {
	empIDStr := c.Param("employeeId")
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	empID, _ := strconv.ParseUint(empIDStr, 10, 64)
	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	record, err := h.svc.ProcessPayroll(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, record)
}

// ProcessAllPayroll approves all monthly records.
func (h *Handler) ProcessAllPayroll(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	err := h.svc.ProcessAllPayrollForMonth(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.String(http.StatusOK, "Payroll processed for month "+monthStr+" year "+yearStr)
}

// GetPayrollSummary aggregates payroll statistics.
func (h *Handler) GetPayrollSummary(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	records, err := h.repo.FindByMonthAndYear(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var totalGross float64
	var totalNet float64
	var totalDeductions float64
	var totalOvertimeHours float64

	for _, record := range records {
		totalGross += record.GrossPay
		totalNet += record.NetPay
		totalDeductions += record.Deductions
		totalOvertimeHours += record.OvertimeHours
	}

	summary := PayrollSummary{
		Month:              month,
		Year:               year,
		TotalEmployees:     len(records),
		TotalGrossPay:      totalGross,
		TotalNetPay:        totalNet,
		TotalDeductions:    totalDeductions,
		TotalOvertimeHours: totalOvertimeHours,
	}

	c.JSON(http.StatusOK, summary)
}
