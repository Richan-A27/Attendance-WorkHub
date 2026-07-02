package com.isravel.workhub.device;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "device_sync_status")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DeviceSyncStatus {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_name", nullable = false)
    private String deviceName;

    @Column(name = "device_ip")
    private String deviceIp;

    @Column(name = "device_port")
    private Integer devicePort;

    @Column(name = "last_sync")
    private LocalDateTime lastSync;

    @Column(name = "last_employee_sync")
    private LocalDateTime lastEmployeeSync;

    @Column(name = "last_attendance_sync")
    private LocalDateTime lastAttendanceSync;

    @Column(name = "status")
    private String status;

    @Column(name = "users_synced")
    private Integer usersSynced;

    @Column(name = "attendance_synced")
    private Integer attendanceSynced;

    @Column(name = "duplicates_ignored")
    private Integer duplicatesIgnored;

    @Column(name = "sync_duration")
    private Double syncDuration;

    @Column(name = "last_error")
    private String lastError;
}
