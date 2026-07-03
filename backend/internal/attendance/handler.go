package attendance

import (
	"net/http"
	"strconv"
	"time"
	"github.com/gin-gonic/gin"
)

// Handler processes REST requests for raw log punches and adjustment records.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// ApiResponse represents the standard response format.
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// List returns raw logs, supporting page filters, date range filters, or employee ID filters.
func (h *Handler) List(c *gin.Context) {
	employeeIdStr := c.Query("employeeId")
	startDateStr := c.Query("startDate")
	endDateStr := c.Query("endDate")

	pageStr := c.DefaultQuery("page", "0")
	sizeStr := c.DefaultQuery("size", "50")

	page, _ := strconv.Atoi(pageStr)
	size, _ := strconv.Atoi(sizeStr)

	if employeeIdStr != "" {
		empID, err := strconv.ParseUint(employeeIdStr, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, ApiResponse{
				Success: false,
				Message: "Invalid employee ID",
				Data:    nil,
			})
			return
		}

		res, err := h.svc.FindByEmployeeID(c.Request.Context(), empID, page, size)
		if err != nil {
			c.JSON(http.StatusInternalServerError, ApiResponse{
				Success: false,
				Message: err.Error(),
				Data:    nil,
			})
			return
		}

		c.JSON(http.StatusOK, ApiResponse{
			Success: true,
			Message: "Attendance by employee",
			Data:    res,
		})
		return
	}

	if startDateStr != "" && endDateStr != "" {
		start, err1 := time.Parse("2006-01-02T15:04:05", startDateStr)
		if err1 != nil {
			start, err1 = time.Parse(time.RFC3339, startDateStr)
		}

		end, err2 := time.Parse("2006-01-02T15:04:05", endDateStr)
		if err2 != nil {
			end, err2 = time.Parse(time.RFC3339, endDateStr)
		}

		if err1 != nil || err2 != nil {
			c.JSON(http.StatusBadRequest, ApiResponse{
				Success: false,
				Message: "Invalid startDate or endDate format (expected ISO-8601)",
				Data:    nil,
			})
			return
		}

		res, err := h.svc.FindByDateRange(c.Request.Context(), start, end, page, size)
		if err != nil {
			c.JSON(http.StatusInternalServerError, ApiResponse{
				Success: false,
				Message: err.Error(),
				Data:    nil,
			})
			return
		}

		c.JSON(http.StatusOK, ApiResponse{
			Success: true,
			Message: "Attendance by date range",
			Data:    res,
		})
		return
	}

	res, err := h.svc.FindAll(c.Request.Context(), page, size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ApiResponse{
			Success: false,
			Message: err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "All attendance",
		Data:    res,
	})
}

// Recent returns the last few logs parsed.
func (h *Handler) Recent(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	limit, _ := strconv.Atoi(limitStr)

	logs, err := h.svc.FindRecent(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ApiResponse{
			Success: false,
			Message: err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "Recent attendance",
		Data:    logs,
	})
}

// Today returns log punches recorded on the current calendar day.
func (h *Handler) Today(c *gin.Context) {
	pageStr := c.DefaultQuery("page", "0")
	sizeStr := c.DefaultQuery("size", "50")

	page, _ := strconv.Atoi(pageStr)
	size, _ := strconv.Atoi(sizeStr)

	now := time.Now()
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	end := start.AddDate(0, 0, 1).Add(-time.Nanosecond)

	res, err := h.svc.FindByDateRange(c.Request.Context(), start, end, page, size)
	if err != nil {
		c.JSON(http.StatusInternalServerError, ApiResponse{
			Success: false,
			Message: err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "Today attendance",
		Data:    res,
	})
}
