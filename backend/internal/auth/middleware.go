package auth

import (
	"net/http"
	"strings"
	"github.com/gin-gonic/gin"
)

// RequireRole checks for a valid JWT token and restricts access to specific roles.
func RequireRole(svc Service, allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, ApiResponse{
				Success: false,
				Message: "Authorization header is missing",
				Data:    nil,
			})
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, ApiResponse{
				Success: false,
				Message: "Invalid authorization header format",
				Data:    nil,
			})
			return
		}

		tokenStr := parts[1]
		claims, err := svc.ParseToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, ApiResponse{
				Success: false,
				Message: "Invalid or expired token",
				Data:    nil,
			})
			return
		}

		username, _ := (*claims)["sub"].(string)
		role, _ := (*claims)["role"].(string)

		c.Set("username", username)
		c.Set("role", role)

		if len(allowedRoles) > 0 {
			allowed := false
			for _, r := range allowedRoles {
				if r == role {
					allowed = true
					break
				}
			}
			if !allowed {
				c.AbortWithStatusJSON(http.StatusForbidden, ApiResponse{
					Success: false,
					Message: "Insufficient permissions",
					Data:    nil,
				})
				return
			}
		}

		c.Next()
	}
}
