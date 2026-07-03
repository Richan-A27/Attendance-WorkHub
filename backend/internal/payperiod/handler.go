package payperiod

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// Handler processes HTTP requests for pay period management.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// CreatePayPeriod handles POST /api/pay-periods
func (h *Handler) CreatePayPeriod(c *gin.Context) {
	var body struct {
		Name      string `json:"name" binding:"required"`
		StartDate string `json:"startDate" binding:"required"`
		EndDate   string `json:"endDate" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	period, err := h.svc.CreatePayPeriod(c.Request.Context(), body.Name, body.StartDate, body.EndDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, period)
}

// ListPayPeriods handles GET /api/pay-periods
func (h *Handler) ListPayPeriods(c *gin.Context) {
	periods, err := h.svc.ListPayPeriods(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, periods)
}

// GetOpenPeriods handles GET /api/pay-periods/open
func (h *Handler) GetOpenPeriods(c *gin.Context) {
	periods, err := h.svc.GetOpenPeriods(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, periods)
}

// GetPayPeriod handles GET /api/pay-periods/:id
func (h *Handler) GetPayPeriod(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	period, err := h.svc.GetPayPeriod(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "pay period not found"})
		return
	}
	c.JSON(http.StatusOK, period)
}

// UpdatePeriodStatus handles PUT /api/pay-periods/:id/status
func (h *Handler) UpdatePeriodStatus(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	var body struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	period, err := h.svc.UpdatePeriodStatus(c.Request.Context(), id, body.Status)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, period)
}

// DeletePayPeriod handles DELETE /api/pay-periods/:id
func (h *Handler) DeletePayPeriod(c *gin.Context) {
	id, _ := strconv.ParseUint(c.Param("id"), 10, 64)
	if err := h.svc.DeletePayPeriod(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "pay period deleted"})
}
