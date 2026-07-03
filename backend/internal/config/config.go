package config

import (
	"fmt"
	"github.com/spf13/viper"
)

// Config holds all configuration values for the application.
type Config struct {
	ServerPort      string `mapstructure:"PORT"`
	DBHost          string `mapstructure:"DB_HOST"`
	DBPort          string `mapstructure:"DB_PORT"`
	DBName          string `mapstructure:"DB_NAME"`
	DBUser          string `mapstructure:"DB_USER"`
	DBPassword      string `mapstructure:"DB_PASSWORD"`
	JWTSecret       string `mapstructure:"JWT_SECRET"`
	JWTExpirationMs int64  `mapstructure:"JWT_EXPIRATION_MS"`
	DeviceIP        string `mapstructure:"DEVICE_IP"`
	DevicePort      string `mapstructure:"DEVICE_PORT"`
	SupabaseURL     string `mapstructure:"SUPABASE_URL"`
	SupabaseKey     string `mapstructure:"SUPABASE_KEY"`
}

// LoadConfig loads the configuration from environment variables and config files.
func LoadConfig() (*Config, error) {
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("DB_HOST", "localhost")
	viper.SetDefault("DB_PORT", "5432")
	viper.SetDefault("DB_NAME", "isravel_workhub")
	viper.SetDefault("DB_USER", "richan_27")
	viper.SetDefault("DB_PASSWORD", "")
	viper.SetDefault("JWT_EXPIRATION_MS", int64(3600000))
	viper.SetDefault("DEVICE_IP", "192.168.31.11")
	viper.SetDefault("DEVICE_PORT", "4370")

	viper.AutomaticEnv()

	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	viper.AddConfigPath("./configs")
	viper.AddConfigPath(".")

	// Ignore read errors if configuration file doesn't exist; rely on environment variables
	_ = viper.ReadInConfig()

	var cfg Config
	err := viper.Unmarshal(&cfg)
	if err != nil {
		return nil, err
	}

	fmt.Printf("Loaded Config: %+v\n", cfg)
	return &cfg, nil
}
