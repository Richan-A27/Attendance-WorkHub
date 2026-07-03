package device

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// Handler processes device requests.
type Handler struct {
	repo Repository
}

// NewHandler creates a new Handler instance.
func NewHandler(repo Repository) *Handler {
	return &Handler{repo: repo}
}

// GetStatus returns the latest biometric hardware sync status.
func (h *Handler) GetStatus(c *gin.Context) {
	status, err := h.repo.FindFirstByOrderByLastSyncDesc(c.Request.Context())
	if err != nil {
		// Return default payload
		defaultStatus := DeviceSyncStatus{
			DeviceName:       "X2008",
			Status:           "Offline",
			UsersSynced:      0,
			AttendanceSynced: 0,
		}
		c.JSON(http.StatusOK, defaultStatus)
		return
	}

	c.JSON(http.StatusOK, status)
}
