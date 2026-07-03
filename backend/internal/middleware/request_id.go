package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// RequestIDMiddleware injects a unique Request ID header into the request and response contexts.
func RequestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		reqID := c.Request.Header.Get("X-Request-ID")
		if reqID == "" {
			reqID = uuid.New().String()
		}
		c.Writer.Header().Set("X-Request-ID", reqID)
		c.Set("RequestID", reqID)
		c.Next()
	}
}
