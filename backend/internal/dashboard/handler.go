package dashboard

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// Handler processes dashboard queries.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// GetSummary returns dashboard aggregate cards.
func (h *Handler) GetSummary(c *gin.Context) {
	summary, err := h.svc.GetSummary(c.Request.Context())
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
		Message: "Dashboard summary",
		Data:    summary,
	})
}
