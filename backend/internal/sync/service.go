package sync

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
	"com.isravel.workhub/internal/config"
)

// Service defines synchronization triggers.
type Service interface {
	ProcessSyncQueue(ctx context.Context) error
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

func (s *service) ProcessSyncQueue(ctx context.Context) error {
	supabaseURL := s.cfg.SupabaseURL
	supabaseKey := s.cfg.SupabaseKey

	if supabaseURL == "" || supabaseKey == "" {
		return nil // Not configured
	}

	pendingTasks, err := s.repo.FindByStatus(ctx, "PENDING")
	if err != nil {
		return err
	}

	if len(pendingTasks) == 0 {
		return nil
	}

	client := &http.Client{Timeout: 10 * time.Second}

	for _, task := range pendingTasks {
		task.Status = "PROCESSING"
		_ = s.repo.Save(ctx, &task)

		success, errMessage := s.syncRecordToSupabase(ctx, client, supabaseURL, supabaseKey, &task)

		if success {
			task.Status = "SYNCED"
			task.ErrorMessage = ""
		} else {
			task.Status = "FAILED"
			task.ErrorMessage = errMessage
		}
		_ = s.repo.Save(ctx, &task)
	}

	return nil
}

func (s *service) syncRecordToSupabase(ctx context.Context, client *http.Client, url, key string, task *SyncQueue) (bool, string) {
	targetURL := fmt.Sprintf("%s/rest/v1/%s", url, task.SyncTable)

	if task.Action == "DELETE" {
		targetURL = fmt.Sprintf("%s?id=eq.%s", targetURL, task.RecordID)
		req, err := http.NewRequestWithContext(ctx, http.MethodDelete, targetURL, nil)
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("apikey", key)
		req.Header.Set("Authorization", "Bearer "+key)

		resp, err := client.Do(req)
		if err != nil {
			return false, err.Error()
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return true, ""
		}
		return false, fmt.Sprintf("Supabase returned status code %d", resp.StatusCode)
	}

	// For INSERT and UPDATE, fetch the row from local DB
	row, err := s.repo.FetchRow(ctx, task.SyncTable, task.RecordID)
	if err != nil {
		// Record might have been deleted locally before sync, mark as skipped success
		return true, ""
	}

	// GORM raw maps time.Time into string or formats, but let's serialize it as JSON
	payload, err := json.Marshal(row)
	if err != nil {
		return false, err.Error()
	}

	var req *http.Request
	if task.Action == "INSERT" {
		req, err = http.NewRequestWithContext(ctx, http.MethodPost, targetURL, bytes.NewBuffer(payload))
		if err != nil {
			return false, err.Error()
		}
		req.Header.Set("Prefer", "resolution=merge-duplicates")
	} else if task.Action == "UPDATE" {
		targetURL = fmt.Sprintf("%s?id=eq.%s", targetURL, task.RecordID)
		req, err = http.NewRequestWithContext(ctx, http.MethodPatch, targetURL, bytes.NewBuffer(payload))
		if err != nil {
			return false, err.Error()
		}
	} else {
		return false, "Unsupported sync action: " + task.Action
	}

	req.Header.Set("apikey", key)
	req.Header.Set("Authorization", "Bearer "+key)
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return false, err.Error()
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return true, ""
	}
	return false, fmt.Sprintf("Supabase returned status code %d", resp.StatusCode)
}
