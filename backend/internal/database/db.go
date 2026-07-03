package database

import (
	"fmt"
	"com.isravel.workhub/internal/config"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// DB is the global GORM database connection wrapper.
var DB *gorm.DB

// InitDB initializes the GORM PostgreSQL connection pool.
func InitDB(cfg *config.Config) (*gorm.DB, error) {
	dsn := fmt.Sprintf(
		"host=%s user=%s dbname=%s port=%s sslmode=disable TimeZone=Asia/Kolkata",
		cfg.DBHost,
		cfg.DBUser,
		cfg.DBName,
		cfg.DBPort,
	)
	if cfg.DBPassword != "" {
		dsn += fmt.Sprintf(" password=%s", cfg.DBPassword)
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve generic database object: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)

	DB = db
	return db, nil
}
