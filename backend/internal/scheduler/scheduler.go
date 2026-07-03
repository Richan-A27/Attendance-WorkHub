package scheduler

import (
	"context"
	"time"
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/sync"
	"com.isravel.workhub/internal/utils"
	"go.uber.org/zap"
)

// Start begins background periodic attendance calculation and cloud sync loops.
func Start(ctx context.Context, sessionEngine intelligence.SessionEngine, dailyProcessor intelligence.DailyProcessor, syncSvc sync.Service) {
	utils.Logger.Info("Starting background scheduler tasks...")

	// 1. Supabase Sync loop (every 5 seconds)
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				utils.Logger.Info("Supabase sync background job stopped.")
				return
			case <-ticker.C:
				err := syncSvc.ProcessSyncQueue(ctx)
				if err != nil {
					utils.Logger.Error("Error in Supabase sync scheduler loop", zap.Error(err))
				}
			}
		}
	}()

	// 2. Attendance aggregation loop (every 10 seconds)
	go func() {
		ticker := time.NewTicker(10 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				utils.Logger.Info("Attendance intelligence calculation job stopped.")
				return
			case <-ticker.C:
				now := time.Now()
				for i := 0; i <= 2; i++ {
					dateToProcess := now.AddDate(0, 0, -i).Format("2006-01-02")
					_ = sessionEngine.ProcessAllSessionsForDate(ctx, dateToProcess)
					_ = dailyProcessor.ProcessAllAttendanceForDate(ctx, dateToProcess)
				}
			}
		}
	}()
}
