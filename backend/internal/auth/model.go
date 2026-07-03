package auth

import (
	"time"
)

// User represents the users GORM model mapped to the "users" table.
type User struct {
	ID           uint64     `gorm:"primaryKey;autoIncrement;column:id"`
	Username     string     `gorm:"not null;unique;column:username"`
	PasswordHash string     `gorm:"not null;column:password_hash"`
	Role         string     `gorm:"column:role"`
	CreatedAt    time.Time  `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt    *time.Time `gorm:"column:updated_at"`
}

// TableName overrides GORM's default naming behavior to "users".
func (User) TableName() string {
	return "users"
}
