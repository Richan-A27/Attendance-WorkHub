package operations

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"time"
	"com.isravel.workhub/internal/config"
)

// Service defines synchronization run and triggers.
type Service interface {
	StartSync(ctx context.Context) (*SyncHistory, error)
	CompleteSync(ctx context.Context, id uint64, recordsProcessed int, errorMessage string) (*SyncHistory, error)
	GetDeviceStatus(ctx context.Context) (map[string]interface{}, error)
	GetSyncStatistics(ctx context.Context) (map[string]interface{}, error)
	TriggerManualSync(ctx context.Context) (map[string]interface{}, error)
}

type service struct {
	repo Repository
	cfg  *config.Config
}

// NewService creates a new Service instance.
func NewService(repo Repository, cfg *config.Config) Service {
	return &service{
		repo: repo,
		cfg:  cfg,
	}
}

func (s *service) StartSync(ctx context.Context) (*SyncHistory, error) {
	sh := &SyncHistory{
		SyncStartTime: time.Now(),
		Status:        "IN_PROGRESS",
	}
	err := s.repo.Save(ctx, sh)
	return sh, err
}

func (s *service) CompleteSync(ctx context.Context, id uint64, recordsProcessed int, errorMessage string) (*SyncHistory, error) {
	sh, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	sh.SyncEndTime = &now
	sh.RecordsProcessed = recordsProcessed

	if errorMessage != "" {
		sh.Status = "FAILURE"
		sh.ErrorMessage = errorMessage
	} else {
		sh.Status = "SUCCESS"
		sh.ErrorMessage = ""
	}

	err = s.repo.Save(ctx, sh)
	return sh, err
}

func (s *service) GetDeviceStatus(ctx context.Context) (map[string]interface{}, error) {
	status := make(map[string]interface{})
	status["deviceName"] = "X2008"
	status["deviceIp"] = s.cfg.DeviceIP

	lastSync, err := s.repo.FindLatest(ctx)
	if err != nil || lastSync == nil {
		status["connectionStatus"] = "UNKNOWN"
		status["lastSyncTime"] = nil
		status["lastSyncStatus"] = nil
		return status, nil
	}

	status["lastSyncTime"] = lastSync.SyncEndTime
	status["lastSyncStatus"] = lastSync.Status

	if lastSync.Status == "SUCCESS" && lastSync.SyncEndTime != nil && time.Since(*lastSync.SyncEndTime) < 30*time.Minute {
		status["connectionStatus"] = "ONLINE"
	} else {
		status["connectionStatus"] = "OFFLINE"
	}

	return status, nil
}

func (s *service) GetSyncStatistics(ctx context.Context) (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	total, _ := s.repo.CountAll(ctx)
	success, _ := s.repo.CountSuccessful(ctx)
	failed, _ := s.repo.CountFailed(ctx)
	latest, _ := s.repo.FindLatest(ctx)

	stats["totalSyncs"] = total
	stats["successfulSyncs"] = success
	stats["failedSyncs"] = failed
	stats["lastSync"] = latest

	return stats, nil
}

func (s *service) TriggerManualSync(ctx context.Context) (map[string]interface{}, error) {
	syncHistory, err := s.StartSync(ctx)
	if err != nil {
		return nil, err
	}

	historyID := syncHistory.ID

	// Run process run in background goroutine
	go func() {
		bgCtx := context.Background()
		cmd := exec.Command(
			"/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync/.venv/bin/python",
			"/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync/attendance_sync.py",
			"--once",
			"--history-id",
			strconv.FormatUint(historyID, 10),
		)
		cmd.Dir = "/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync"
		cmd.Env = os.Environ()

		// Run process
		output, err := cmd.CombinedOutput()
		if err != nil {
			errStr := fmt.Sprintf("Python process failed: %s. Output: %s", err.Error(), string(output))
			_, _ = s.CompleteSync(bgCtx, historyID, 0, errStr)
		}
	}()

	response := make(map[string]interface{})
	response["message"] = "Manual sync triggered"
	response["syncHistoryId"] = historyID
	response["status"] = "IN_PROGRESS"

	return response, nil
}
