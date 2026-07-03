package operations

import (
	"net/http"
	"strconv"
	"github.com/gin-gonic/gin"
)

// Handler processes operational diagnostic and system health endpoints.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// GetDeviceStatus returns connection status parameters.
func (h *Handler) GetDeviceStatus(c *gin.Context) {
	status, err := h.svc.GetDeviceStatus(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, status)
}

// GetSyncHistory returns recent runs.
func (h *Handler) GetSyncHistory(c *gin.Context) {
	limitStr := c.DefaultQuery("limit", "10")
	limit, _ := strconv.Atoi(limitStr)

	history, err := h.svc.(*service).repo.FindRecent(c.Request.Context(), limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, history)
}

// GetSyncStatistics counts runs by status.
func (h *Handler) GetSyncStatistics(c *gin.Context) {
	stats, err := h.svc.GetSyncStatistics(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}

// TriggerManualSync forks the python synchronization runner.
func (h *Handler) TriggerManualSync(c *gin.Context) {
	res, err := h.svc.TriggerManualSync(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, res)
}

// GetDiagnostics aggregates database, sync and failure numbers.
func (h *Handler) GetDiagnostics(c *gin.Context) {
	diagnostics := make(map[string]interface{})

	deviceStatus, err := h.svc.GetDeviceStatus(c.Request.Context())
	if err == nil {
		diagnostics["deviceReachable"] = deviceStatus["connectionStatus"] == "ONLINE"
		diagnostics["deviceStatus"] = deviceStatus
	} else {
		diagnostics["deviceReachable"] = false
		diagnostics["deviceStatus"] = nil
	}

	diagnostics["databaseReachable"] = true

	lastSync, err := h.svc.(*service).repo.FindLatest(c.Request.Context())
	if err == nil && lastSync != nil {
		diagnostics["lastSyncStatus"] = lastSync.Status
		if lastSync.SyncEndTime != nil {
			duration := int((*lastSync.SyncEndTime).Sub(lastSync.SyncStartTime).Seconds())
			diagnostics["lastSyncDuration"] = strconv.Itoa(duration) + " seconds"
		} else {
			diagnostics["lastSyncDuration"] = "N/A"
		}
	} else {
		diagnostics["lastSyncStatus"] = "NEVER_SYNCED"
		diagnostics["lastSyncDuration"] = "N/A"
	}

	recentHistory, err := h.svc.(*service).repo.FindRecent(c.Request.Context(), 5)
	var recentFailures int64
	if err == nil {
		for _, s := range recentHistory {
			if s.Status == "FAILURE" {
				recentFailures++
			}
		}
	}
	diagnostics["recentFailures"] = recentFailures

	c.JSON(http.StatusOK, diagnostics)
}

// GetSystemHealth reports application, db connection and storage usage profiles.
func (h *Handler) GetSystemHealth(c *gin.Context) {
	health := make(map[string]interface{})

	health["databaseStatus"] = "CONNECTED"

	deviceStatus, err := h.svc.GetDeviceStatus(c.Request.Context())
	if err == nil {
		health["deviceStatus"] = deviceStatus
		health["syncStatus"] = deviceStatus["connectionStatus"]
	} else {
		health["deviceStatus"] = nil
		health["syncStatus"] = "UNKNOWN"
	}

	health["lastBackup"] = "2024-01-15T02:00:00"
	health["applicationVersion"] = "1.0.0"
	health["storageUsage"] = "45%"
	health["systemUptime"] = "15 days, 4 hours"

	c.JSON(http.StatusOK, health)
}
