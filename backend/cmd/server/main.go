package main

import (
	"context"
	"net/http"
	"com.isravel.workhub/internal/attendance"
	"com.isravel.workhub/internal/auth"
	"com.isravel.workhub/internal/config"
	"com.isravel.workhub/internal/dashboard"
	"com.isravel.workhub/internal/database"
	"com.isravel.workhub/internal/device"
	"com.isravel.workhub/internal/employee"
	"com.isravel.workhub/internal/holiday"
	"com.isravel.workhub/internal/intelligence"
	"com.isravel.workhub/internal/middleware"
	"com.isravel.workhub/internal/operations"
	"com.isravel.workhub/internal/payroll"
	"com.isravel.workhub/internal/reports"
	"com.isravel.workhub/internal/schedule"
	"com.isravel.workhub/internal/scheduler"
	"com.isravel.workhub/internal/settings"
	"com.isravel.workhub/internal/sync"
	"com.isravel.workhub/internal/utils"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func main() {
	// 1. Initialize Zap Logger
	utils.InitLogger()
	defer utils.Logger.Sync()

	utils.Logger.Info("Starting WorkHub Backend v2 in Go...")

	// 2. Load Config via Viper
	cfg, err := config.LoadConfig()
	if err != nil {
		utils.Logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// 3. Connect to PostgreSQL via GORM
	db, err := database.InitDB(cfg)
	if err != nil {
		utils.Logger.Fatal("Failed to connect to PostgreSQL database", zap.Error(err))
	}
	utils.Logger.Info("Successfully connected to PostgreSQL database")

	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	// 4. Initialize Gin router
	r := gin.New()

	// 5. General Middlewares
	r.Use(gin.Recovery())
	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.ZapLoggerMiddleware())

	// 6. Wire Modules
	authRepo := auth.NewRepository(db)
	authSvc := auth.NewService(authRepo, cfg)
	authHandler := auth.NewHandler(authSvc)

	empRepo := employee.NewRepository(db)
	empSvc := employee.NewService(empRepo)
	empHandler := employee.NewHandler(empSvc)

	settingsRepo := settings.NewRepository(db)
	settingsSvc := settings.NewService(settingsRepo)
	settingsHandler := settings.NewHandler(settingsSvc)

	holidayRepo := holiday.NewRepository(db)
	holidaySvc := holiday.NewService(holidayRepo)
	holidayHandler := holiday.NewHandler(holidaySvc)

	scheduleRepo := schedule.NewRepository(db)
	scheduleSvc := schedule.NewService(scheduleRepo)
	scheduleHandler := schedule.NewHandler(scheduleSvc)

	attendanceRepo := attendance.NewRepository(db)
	attendanceSvc := attendance.NewService(attendanceRepo)
	attendanceHandler := attendance.NewHandler(attendanceSvc)

	intelRepo := intelligence.NewRepository(db)
	sessionEngine := intelligence.NewSessionEngine(intelRepo, attendanceRepo, scheduleRepo, settingsRepo)
	dailyProcessor := intelligence.NewDailyProcessor(intelRepo, attendanceRepo, empRepo, holidayRepo, scheduleRepo, settingsRepo)
	scoreEngine := intelligence.NewScoreEngine(intelRepo)
	rankingSvc := intelligence.NewRankingService(scoreEngine, empRepo)
	intelHandler := intelligence.NewHandler(sessionEngine, dailyProcessor, scoreEngine, rankingSvc, intelRepo)

	payrollRepo := payroll.NewRepository(db)
	payrollSvc := payroll.NewService(payrollRepo, empRepo, intelRepo)
	payrollHandler := payroll.NewHandler(payrollSvc, payrollRepo)

	reportsSvc := reports.NewService(empRepo, intelRepo, payrollRepo, rankingSvc)
	reportsHandler := reports.NewHandler(reportsSvc)

	dashboardSvc := dashboard.NewService(empRepo, attendanceRepo, intelRepo, payrollRepo)
	dashboardHandler := dashboard.NewHandler(dashboardSvc)

	deviceRepo := device.NewRepository(db)
	deviceHandler := device.NewHandler(deviceRepo)

	syncRepo := sync.NewRepository(db)
	syncSvc := sync.NewService(syncRepo, cfg)

	opsRepo := operations.NewRepository(db)
	opsSvc := operations.NewService(opsRepo, cfg)
	opsHandler := operations.NewHandler(opsSvc)

	// 7. Start Background Scheduler Tickers
	bgCtx, cancel := context.WithCancel(context.Background())
	defer cancel() // will cancel on server shutdown
	scheduler.Start(bgCtx, sessionEngine, dailyProcessor, syncSvc)

	// 8. Register Routes
	apiGroup := r.Group("/api")
	auth.RegisterRoutes(apiGroup, authHandler)
	employee.RegisterRoutes(apiGroup, empHandler, authSvc)
	settings.RegisterRoutes(apiGroup, settingsHandler, authSvc)
	holiday.RegisterRoutes(apiGroup, holidayHandler, authSvc)
	schedule.RegisterRoutes(apiGroup, scheduleHandler, authSvc)
	attendance.RegisterRoutes(apiGroup, attendanceHandler, authSvc)
	intelligence.RegisterRoutes(apiGroup, intelHandler, authSvc)
	payroll.RegisterRoutes(apiGroup, payrollHandler, authSvc)
	reports.RegisterRoutes(apiGroup, reportsHandler, authSvc)
	dashboard.RegisterRoutes(apiGroup, dashboardHandler, authSvc)
	device.RegisterRoutes(apiGroup, deviceHandler, authSvc)
	operations.RegisterRoutes(apiGroup, opsHandler, authSvc)

	r.GET("/health", func(c *gin.Context) {
		sqlDB, err := db.DB()
		if err != nil || sqlDB.Ping() != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"success": false,
				"status":  "DOWN",
				"details": "Database unreachable",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"status":  "UP",
			"details": "WorkHub Backend v2 is healthy",
		})
	})

	// 8. Start the server
	addr := ":" + cfg.ServerPort
	utils.Logger.Info("Server is running", zap.String("address", addr))
	if err := r.Run(addr); err != nil {
		utils.Logger.Fatal("Server run failed", zap.Error(err))
	}
}
