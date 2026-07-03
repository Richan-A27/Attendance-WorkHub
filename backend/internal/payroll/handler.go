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
	return &Handler{svc: svc, repo: repo}
}

// --- Period-based endpoints (new) ---

// GeneratePayroll handles POST /api/payroll/generate
// Body: { payPeriodId, calculationMode, overrides: [{employeeId, calculationMode}] }
func (h *Handler) GeneratePayroll(c *gin.Context) {
	var req GeneratePayrollRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	records, err := h.svc.GeneratePayrollForPeriod(c.Request.Context(), req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, records)
}

// PreviewPayroll handles GET /api/payroll/preview/:payPeriodId
// Returns both INCLUDE_BREAKS and EXCLUDE_BREAKS calculations without persisting anything.
func (h *Handler) PreviewPayroll(c *gin.Context) {
	payPeriodID, _ := strconv.ParseUint(c.Param("payPeriodId"), 10, 64)
	previews, err := h.svc.PreviewPayrollForPeriod(c.Request.Context(), payPeriodID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, previews)
}

// GetPayrollByPeriod handles GET /api/payroll/period/:payPeriodId
func (h *Handler) GetPayrollByPeriod(c *gin.Context) {
	payPeriodID, _ := strconv.ParseUint(c.Param("payPeriodId"), 10, 64)
	records, err := h.svc.GetPayrollByPeriod(c.Request.Context(), payPeriodID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, records)
}

// MarkPayrollPaid handles PUT /api/payroll/mark-paid/:employeeId/:payPeriodId
func (h *Handler) MarkPayrollPaid(c *gin.Context) {
	employeeID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	payPeriodID, _ := strconv.ParseUint(c.Param("payPeriodId"), 10, 64)

	record, err := h.svc.MarkPayrollPaid(c.Request.Context(), employeeID, payPeriodID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, record)
}

// --- Month-based endpoints (kept for backward compat) ---

// CalculatePayroll calculates monthly payroll for a single employee.
func (h *Handler) CalculatePayroll(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	record, err := h.svc.CalculateMonthlyPayroll(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, record)
}

// CalculateAllPayroll calculates monthly payroll for all active employees.
func (h *Handler) CalculateAllPayroll(c *gin.Context) {
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	records, err := h.svc.CalculatePayrollForAllEmployees(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, records)
}

// GetEmployeePayroll returns a single employee's calculated payroll record.
func (h *Handler) GetEmployeePayroll(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	record, err := h.repo.FindByEmployeeIDAndMonthAndYear(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "payroll record not found"})
		return
	}
	c.JSON(http.StatusOK, record)
}

// GetMonthlyPayroll returns all records for a month.
func (h *Handler) GetMonthlyPayroll(c *gin.Context) {
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	records, err := h.repo.FindByMonthAndYear(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, records)
}

// GetEmployeePayrollHistory returns historical payroll summaries for an employee.
func (h *Handler) GetEmployeePayrollHistory(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	records, err := h.repo.FindEmployeePayrollHistory(c.Request.Context(), empID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, records)
}

// UpdateDeductions updates deduction values.
func (h *Handler) UpdateDeductions(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))
	deductions, _ := strconv.ParseFloat(c.Query("deductions"), 64)

	record, err := h.svc.UpdatePayrollDeductions(c.Request.Context(), empID, month, year, deductions)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, record)
}

// UpdateBonuses updates bonus values.
func (h *Handler) UpdateBonuses(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))
	bonuses, _ := strconv.ParseFloat(c.Query("bonuses"), 64)

	record, err := h.svc.UpdatePayrollBonuses(c.Request.Context(), empID, month, year, bonuses)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, record)
}

// ProcessPayroll signs and approves a monthly record.
func (h *Handler) ProcessPayroll(c *gin.Context) {
	empID, _ := strconv.ParseUint(c.Param("employeeId"), 10, 64)
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	record, err := h.svc.ProcessPayroll(c.Request.Context(), empID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, record)
}

// ProcessAllPayroll approves all monthly records.
func (h *Handler) ProcessAllPayroll(c *gin.Context) {
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	if err := h.svc.ProcessAllPayrollForMonth(c.Request.Context(), month, year); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.String(http.StatusOK, "Payroll processed for month "+c.Param("month")+" year "+c.Param("year"))
}

// GetPayrollSummary aggregates payroll statistics.
func (h *Handler) GetPayrollSummary(c *gin.Context) {
	month, _ := strconv.Atoi(c.Param("month"))
	year, _ := strconv.Atoi(c.Param("year"))

	records, err := h.repo.FindByMonthAndYear(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	var totalGross, totalNet, totalDeductions, totalOvertimeHours, totalPaidHours float64
	for _, record := range records {
		totalGross += record.GrossPay
		totalNet += record.NetPay
		totalDeductions += record.Deductions
		totalOvertimeHours += record.OvertimeHours
		totalPaidHours += record.PaidHours
	}

	summary := PayrollSummary{
		Month:              month,
		Year:               year,
		TotalEmployees:     len(records),
		TotalGrossPay:      totalGross,
		TotalNetPay:        totalNet,
		TotalDeductions:    totalDeductions,
		TotalOvertimeHours: totalOvertimeHours,
		TotalPaidHours:     totalPaidHours,
	}
	c.JSON(http.StatusOK, summary)
}
