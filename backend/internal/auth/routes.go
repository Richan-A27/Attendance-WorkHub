package auth

import (
	"github.com/gin-gonic/gin"
)

// RegisterRoutes registers authorization routes into the Gin router group.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler) {
	authGroup := rg.Group("/auth")
	{
		authGroup.POST("/register", h.Register)
		authGroup.POST("/login", h.Login)
	}
}
