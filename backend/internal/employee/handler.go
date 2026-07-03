package employee

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
)

// Handler processes employee related REST requests.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// ApiResponse mirrors the Java API response format.
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// List returns a list of all employees.
func (h *Handler) List(c *gin.Context) {
	all, err := h.svc.FindAll(c.Request.Context())
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
		Message: "Employees retrieved",
		Data:    all,
	})
}

// Get returns details of a single employee by ID.
func (h *Handler) Get(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid employee ID",
			Data:    nil,
		})
		return
	}

	emp, err := h.svc.FindByID(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, ApiResponse{
			Success: false,
			Message: "Employee not found",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "Employee retrieved",
		Data:    emp,
	})
}

// Create processes requests to insert a new employee.
func (h *Handler) Create(c *gin.Context) {
	var req Employee
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid request payload",
			Data:    nil,
		})
		return
	}

	created, err := h.svc.Create(c.Request.Context(), &req)
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
		Message: "Employee created",
		Data:    created,
	})
}

// Update processes requests to update an existing employee.
func (h *Handler) Update(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid employee ID",
			Data:    nil,
		})
		return
	}

	var req Employee
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid request payload",
			Data:    nil,
		})
		return
	}

	updated, err := h.svc.Update(c.Request.Context(), id, &req)
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
		Message: "Employee updated",
		Data:    updated,
	})
}

// Delete processes requests to remove an employee.
func (h *Handler) Delete(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid employee ID",
			Data:    nil,
		})
		return
	}

	err = h.svc.Delete(c.Request.Context(), id)
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
		Message: "Employee deleted",
		Data:    nil,
	})
}

// PatchHourlyRate processes requests to update an employee's hourly rate.
func (h *Handler) PatchHourlyRate(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid employee ID",
			Data:    nil,
		})
		return
	}

	var rate float64
	if err := c.ShouldBindJSON(&rate); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid rate payload",
			Data:    nil,
		})
		return
	}

	updated, err := h.svc.PatchHourlyRate(c.Request.Context(), id, rate)
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
		Message: "Hourly rate updated",
		Data:    updated,
	})
}

// PatchStatus processes requests to update an employee's status (active/inactive).
func (h *Handler) PatchStatus(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid employee ID",
			Data:    nil,
		})
		return
	}

	var active bool
	if err := c.ShouldBindJSON(&active); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid active status payload",
			Data:    nil,
		})
		return
	}

	updated, err := h.svc.PatchStatus(c.Request.Context(), id, active)
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
		Message: "Status updated",
		Data:    updated,
	})
}
