package reports

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
)

// Handler handles HTTP requests for reporting aggregates.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// GetWeeklyReport handles queries for a week's stats starting on the Monday of the given date.
func (h *Handler) GetWeeklyReport(c *gin.Context) {
	dateStr := c.Param("date")

	report, err := h.svc.GenerateWeeklyReport(c.Request.Context(), dateStr)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}

// GetCurrentWeekReport handles queries for the current calendar week stats.
func (h *Handler) GetCurrentWeekReport(c *gin.Context) {
	report, err := h.svc.GenerateCurrentWeekReport(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}

// GetMonthlyReport handles queries for monthly stats.
func (h *Handler) GetMonthlyReport(c *gin.Context) {
	monthStr := c.Param("month")
	yearStr := c.Param("year")

	month, _ := strconv.Atoi(monthStr)
	year, _ := strconv.Atoi(yearStr)

	report, err := h.svc.GenerateMonthlyReport(c.Request.Context(), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}

// GetCurrentMonthReport handles queries for the current calendar month stats.
func (h *Handler) GetCurrentMonthReport(c *gin.Context) {
	report, err := h.svc.GenerateCurrentMonthReport(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, report)
}
