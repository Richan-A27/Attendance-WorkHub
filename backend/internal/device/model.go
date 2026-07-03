package device

import (
	"time"
)

// DeviceSyncStatus represents status records of the hardware sync.
type DeviceSyncStatus struct {
	ID                 uint64     `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	DeviceName         string     `gorm:"not null;column:device_name" json:"deviceName"`
	DeviceIP           string     `gorm:"column:device_ip" json:"deviceIp"`
	DevicePort         *int       `gorm:"column:device_port" json:"devicePort"`
	LastSync           *time.Time `gorm:"column:last_sync" json:"lastSync"`
	LastEmployeeSync   *time.Time `gorm:"column:last_employee_sync" json:"lastEmployeeSync"`
	LastAttendanceSync *time.Time `gorm:"column:last_attendance_sync" json:"lastAttendanceSync"`
	Status             string     `gorm:"column:status" json:"status"`
	UsersSynced        int        `gorm:"column:users_synced" json:"usersSynced"`
	AttendanceSynced   int        `gorm:"column:attendance_synced" json:"attendanceSynced"`
	DuplicatesIgnored  int        `gorm:"column:duplicates_ignored" json:"duplicatesIgnored"`
	SyncDuration       float64    `gorm:"column:sync_duration" json:"syncDuration"`
	LastError          string     `gorm:"column:last_error" json:"lastError"`
}

// TableName overrides GORM's default naming behavior to "device_sync_status".
func (DeviceSyncStatus) TableName() string {
	return "device_sync_status"
}
