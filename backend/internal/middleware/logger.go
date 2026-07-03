package middleware

import (
	"time"
	"com.isravel.workhub/internal/utils"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// ZapLoggerMiddleware integrates request information and metrics into the Zap logger.
func ZapLoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		reqID, _ := c.Get("RequestID")
		reqIDStr, _ := reqID.(string)

		utils.Logger.Info("Request completed",
			zap.String("request_id", reqIDStr),
			zap.Int("status", status),
			zap.String("method", c.Request.Method),
			zap.String("path", path),
			zap.String("query", query),
			zap.String("ip", c.ClientIP()),
			zap.Duration("duration", latency),
			zap.String("user_agent", c.Request.UserAgent()),
		)
	}
}
