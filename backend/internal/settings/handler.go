package settings

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// Handler processes settings configurations REST requests.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// Get retrieves the singular company profile.
func (h *Handler) Get(c *gin.Context) {
	profile, err := h.svc.GetProfile(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, profile)
}

// Save inserts or updates the singular company profile configuration.
func (h *Handler) Save(c *gin.Context) {
	var req CompanyProfile
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	saved, err := h.svc.SaveProfile(c.Request.Context(), &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, saved)
}
